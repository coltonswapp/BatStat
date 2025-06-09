import UIKit

class PlayerGameSummaryViewController: UIViewController {
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .systemGroupedBackground
        
        // Register cells
        collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: "GameInfoCell")
        collectionView.register(PlayerStatCell.self, forCellWithReuseIdentifier: PlayerStatCell.identifier)
        collectionView.register(AtBatOutcomeCell.self, forCellWithReuseIdentifier: AtBatOutcomeCell.identifier)
        collectionView.register(DiamondVisualizationCell.self, forCellWithReuseIdentifier: DiamondVisualizationCell.identifier)
        collectionView.register(StatisticsHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: StatisticsHeaderView.identifier)
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.identifier)
        collectionView.register(SprayChartLegendFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: SprayChartLegendFooterView.identifier)
        
        return collectionView
    }()
    
    private let statService = StatService.shared
    private var game: Game?
    private var player: Player?
    private var playerStats: PlayerGameStats?
    private var gameStats: [Stat] = [] // Store the raw stats to avoid duplicate fetches
    private var atBatOutcomes: [(number: Int, outcome: String, statType: StatType, inning: Int?)] = []
    private var selectedAtBatIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadData()
    }
    
    func configure(with game: Game, player: Player) {
        self.game = game
        self.player = player
        loadData()
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
        guard let player = player, let game = game else { return }
        title = "\(player.name) vs \(game.opponent)"
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, environment in
            switch sectionIndex {
            case 0:
                return self.createGameInfoSection(environment: environment)
            case 1:
                return self.createPlayerStatsSection(environment: environment)
            case 2:
                return self.createAtBatOutcomesSection(environment: environment)
            case 3:
                return self.createDiamondVisualizationSection(environment: environment)
            default:
                return self.createPlayerStatsSection(environment: environment)
            }
        })
    }
    
    private func createGameInfoSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
        
        // Add section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    private func createPlayerStatsSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
        
        // Add section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    private func createAtBatOutcomesSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
        
        // Add section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    private func createDiamondVisualizationSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 8, trailing: 14)
        
        // Add section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        
        // Add section footer for legend
        let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(32))
        let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: footerSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)
        
        section.boundarySupplementaryItems = [header, footer]
        
        return section
    }
    
    private func loadData() {
        guard let player = player, let game = game else { return }
        
        Task {
            do {
                // Fetch stats for this player in this specific game
                let stats = try await statService.fetchPlayerGameStats(gameId: game.id, playerId: player.id)
                
                await MainActor.run {
                    // Store the raw stats to avoid duplicate fetches
                    self.gameStats = stats
                    self.playerStats = self.statService.calculatePlayerGameStats(player: player, stats: stats)
                    
                    // Convert stats to at-bat outcomes for display
                    self.atBatOutcomes = stats.compactMap { stat in
                        guard let atBatNumber = stat.atBatNumber else { return nil }
                        let outcome = self.formatAtBatOutcome(stat)
                        return (number: atBatNumber, outcome: outcome, statType: stat.type, inning: stat.inning)
                    }.sorted { $0.number < $1.number }
                    
                    self.collectionView.reloadData()
                }
            } catch {
                await MainActor.run {
                    print("Error loading player game data: \(error)")
                    self.showAlert(title: "Error", message: "Failed to load game data: \(error.localizedDescription)")
                }
            }
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
                baseOutcome = "Fly Out"
            }
        }
        
        // Special formatting for home runs with RBIs
        if stat.type == .homeRun, let rbiCount = stat.runsBattedIn, rbiCount > 0 {
            if rbiCount == 1 {
                return "Solo Home Run"
            } else {
                return "\(rbiCount)-run Home Run"
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

extension PlayerGameSummaryViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 4 // Game info + Player stats + At-bats + Spray chart
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return game != nil ? 1 : 0 // Game info
        case 1:
            return playerStats != nil ? 1 : 0 // Player stats
        case 2:
            return atBatOutcomes.count // At-bat outcomes
        case 3:
            return 1 // Spray chart
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            // Game info
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GameInfoCell", for: indexPath) as! UICollectionViewListCell
            if let game = game {
                var content = cell.defaultContentConfiguration()
                
                let formatter = DateFormatter()
                formatter.dateStyle = .full
                
                content.text = "vs \(game.opponent)"
                content.secondaryText = "\(formatter.string(from: game.date)) • \(game.location)"
                
                // Show game result if available
                if let homeScore = game.homeScore, let opponentScore = game.opponentScore {
                    let result = homeScore > opponentScore ? "W" : "L"
                    content.secondaryText! += " • \(result) \(homeScore)-\(opponentScore)"
                }
                
                cell.contentConfiguration = content
            }
            return cell
            
        case 1:
            // Player stats
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlayerStatCell.identifier, for: indexPath) as! PlayerStatCell
            if let playerStats = playerStats {
                cell.configure(with: playerStats, isCurrentAtBat: false)
            }
            return cell
            
        case 2:
            // At-bat outcomes
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AtBatOutcomeCell.identifier, for: indexPath) as! AtBatOutcomeCell
            let outcome = atBatOutcomes[indexPath.item]
            cell.configure(atBatNumber: outcome.number, outcome: outcome.outcome, statType: outcome.statType, inning: outcome.inning)
            return cell
            
        case 3:
            // Spray chart
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiamondVisualizationCell.identifier, for: indexPath) as! DiamondVisualizationCell
            
            // Use the already-loaded stats to show hits from this specific game
            let hitsWithLocation = gameStats.filter { $0.hitLocation != nil }
            cell.configure(with: hitsWithLocation, selectedAtBatNumber: selectedAtBatIndex)
            
            return cell
            
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            switch indexPath.section {
            case 0:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
                header.configure(title: "GAME INFO")
                return header
            case 1:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: StatisticsHeaderView.identifier, for: indexPath) as! StatisticsHeaderView
                header.configure(title: "GAME STATS")
                return header
            case 2:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
                header.configure(title: "AT BATS")
                return header
            case 3:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
                header.configure(title: "SPRAY CHART")
                return header
            default:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
                header.configure(title: "")
                return header
            }
        } else if kind == UICollectionView.elementKindSectionFooter {
            // Only section 3 (spray chart) has a footer
            if indexPath.section == 3 {
                let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SprayChartLegendFooterView.identifier, for: indexPath) as! SprayChartLegendFooterView
                return footer
            }
        }
        return UICollectionReusableView()
    }
}

// MARK: - UICollectionViewDelegate

extension PlayerGameSummaryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 2:
            // At-bat outcome tapped - highlight corresponding hit
            let tappedAtBatNumber = atBatOutcomes[indexPath.item].number
            
            if selectedAtBatIndex == tappedAtBatNumber {
                // Deselect if already selected
                selectedAtBatIndex = nil
            } else {
                // Select this at-bat for highlighting
                selectedAtBatIndex = tappedAtBatNumber
            }
            
            // Reload the spray chart section to update highlighting
            collectionView.reloadSections(IndexSet([3]))
            
        default:
            break
        }
    }
}