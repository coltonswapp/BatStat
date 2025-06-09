import UIKit

class PlayByPlayViewController: UIViewController {
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .systemGroupedBackground
        
        // Register cells
        collectionView.register(AtBatOutcomeCell.self, forCellWithReuseIdentifier: AtBatOutcomeCell.identifier)
        collectionView.register(InningTotalsCell.self, forCellWithReuseIdentifier: InningTotalsCell.identifier)
        collectionView.register(InningStatsHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: InningStatsHeaderView.identifier)
        
        return collectionView
    }()
    
    private let playerService = PlayerService()
    private let statService = StatService.shared
    private var currentGame: Game?
    private var rosterPlayers: [Player] = []
    private var inningData: [Int: [Stat]] = [:] // Organized by inning number
    private var sortedInnings: [Int] = [] // To keep track of the inning order
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    func configure(with game: Game) {
        self.currentGame = game
        loadData()
    }
    
    private func loadData() {
        guard let game = currentGame else { return }
        
        Task {
            do {
                // Load players first
                let players = try await playerService.fetchPlayersInGame(gameId: game.id)
                
                // Then load all stats for the game
                let gameStats = try await statService.fetchGameStats(gameId: game.id)
                
                // Organize stats by inning
                var statsByInning: [Int: [Stat]] = [:]
                for stat in gameStats {
                    let inning = stat.inning ?? 1
                    if statsByInning[inning] == nil {
                        statsByInning[inning] = []
                    }
                    statsByInning[inning]?.append(stat)
                }
                
                // Sort the innings and the stats within each inning
                let sortedInningNumbers = statsByInning.keys.sorted()
                
                for inning in sortedInningNumbers {
                    if let inningStats = statsByInning[inning] {
                        // Sort stats by timestamp (or atBatNumber if available)
                        statsByInning[inning] = inningStats.sorted { (stat1, stat2) -> Bool in
                            // First try to sort by timestamp (non-optional Date)
                            if stat1.timestamp != stat2.timestamp {
                                return stat1.timestamp < stat2.timestamp
                            } else if let ab1 = stat1.atBatNumber, let ab2 = stat2.atBatNumber {
                                return ab1 < ab2
                            } else {
                                return false
                            }
                        }
                    }
                }
                
                await MainActor.run {
                    self.rosterPlayers = players
                    self.inningData = statsByInning
                    self.sortedInnings = sortedInningNumbers
                    self.collectionView.reloadData()
                    Logger.info("Loaded play-by-play data for \(sortedInningNumbers.count) innings", category: .games)
                }
            } catch {
                await MainActor.run {
                    Logger.error("Failed to load play-by-play data: \(error.localizedDescription)", category: .games)
                    self.showAlert(title: "Error", message: "Failed to load play-by-play data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        title = "Play by Play"
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, environment in
            return self.createInningSection(environment: environment)
        })
    }
    
    private func createInningSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
        
        // Add section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    private func calculateInningStats(for inning: Int) -> (ab: Int, r: Int, h: Int, rbi: Int, hr: Int) {
        guard let stats = inningData[inning] else {
            return (0, 0, 0, 0, 0)
        }
        
        var ab = 0, r = 0, h = 0, rbi = 0, hr = 0
        
        for stat in stats {
            if isAtBatStat(stat.type) {
                ab += 1
            }
            
            switch stat.type {
            case .run:
                r += 1
            case .hit, .single, .double, .triple:
                h += 1
            case .homeRun:
                h += 1
                hr += 1
            default:
                break
            }
            
            // Count RBIs
            if let runsBattedIn = stat.runsBattedIn, runsBattedIn > 0 {
                rbi += runsBattedIn
            }
        }
        
        return (ab: ab, r: r, h: h, rbi: rbi, hr: hr)
    }
    
    // Helper function to determine if a stat type represents an actual at-bat
    private func isAtBatStat(_ statType: StatType) -> Bool {
        switch statType {
        case .atBat, .hit, .single, .double, .triple, .homeRun, .strikeOut, .error, .fieldersChoice, .flyOut:
            return true
        case .walk, .rbi, .run, .sacrifice:
            return false // These don't count as official at-bats
        }
    }
    
    private func formatAtBatOutcome(_ stat: Stat) -> String {
        // Start with the base outcome
        var baseOutcome: String
        
        // Use the outcome field if available, otherwise format from type
        if let outcome = stat.outcome, !outcome.isEmpty {
            baseOutcome = outcome
        } else {
            switch stat.type {
            case .hit, .single:
                baseOutcome = "Single"
            case .double:
                baseOutcome = "Double"
            case .triple:
                baseOutcome = "Triple"
            case .homeRun:
                baseOutcome = "Home Run"
            case .strikeOut:
                baseOutcome = "Strikeout"
            case .walk:
                baseOutcome = "Walk"
            case .atBat:
                baseOutcome = "Out"
            case .rbi:
                baseOutcome = "RBI"
            case .run:
                baseOutcome = "Run"
            case .error:
                baseOutcome = "Error"
            case .fieldersChoice:
                baseOutcome = "Fielder's Choice"
            case .sacrifice:
                baseOutcome = "Sacrifice"
            case .flyOut:
                baseOutcome = "Flyout"
            }
        }
        
        // Special formatting for home runs with RBIs
        if stat.type == .homeRun, let rbiCount = stat.runsBattedIn, rbiCount > 0 {
            if rbiCount == 1 {
                return "Solo homer"
            } else {
                return "\(rbiCount)-run homer"
            }
        }
        
        // Add RBI information for non-home runs if present and greater than 0
        if let rbiCount = stat.runsBattedIn, rbiCount > 0 {
            return "\(rbiCount) RBI, \(baseOutcome)"
        } else {
            return baseOutcome
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension PlayByPlayViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sortedInnings.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let inning = sortedInnings[section]
        let statsCount = inningData[inning]?.count ?? 0
        return statsCount + 1 // +1 for inning totals cell
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let inning = sortedInnings[indexPath.section]
        
        if indexPath.item == 0 {
            // First cell shows inning totals
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InningTotalsCell.identifier, for: indexPath) as! InningTotalsCell
            let inningStats = calculateInningStats(for: inning)
            cell.configure(ab: inningStats.ab, r: inningStats.r, h: inningStats.h, rbi: inningStats.rbi, hr: inningStats.hr)
            return cell
        } else {
            // Subsequent cells show at-bat outcomes
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AtBatOutcomeCell.identifier, for: indexPath) as! AtBatOutcomeCell
            
            if let stats = inningData[inning], indexPath.item - 1 < stats.count {
                let stat = stats[indexPath.item - 1]
                // Find the player for this stat
                let player = rosterPlayers.first { $0.id == stat.playerId } ?? Player(name: "Unknown", number: nil)
                let outcome = formatAtBatOutcome(stat)
                
                cell.configure(playerName: player.name, outcome: outcome, statType: stat.type)
            } else {
                cell.configure(playerName: "Unknown", outcome: "Unknown", statType: .atBat)
            }
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: InningStatsHeaderView.identifier, for: indexPath) as! InningStatsHeaderView
            let inning = sortedInnings[indexPath.section]
            header.configure(title: "Inning \(inning)")
            return header
        }
        return UICollectionReusableView()
    }
}

// MARK: - UICollectionViewDelegate

extension PlayByPlayViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        // TODO: Handle at-bat detail tap if needed
    }
}