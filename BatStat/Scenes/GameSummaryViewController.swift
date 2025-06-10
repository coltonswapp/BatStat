import UIKit

class GameSummaryViewController: UIViewController {
    
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
        collectionView.register(InningTotalsCell.self, forCellWithReuseIdentifier: InningTotalsCell.identifier)
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.identifier)
        collectionView.register(InningStatsHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: InningStatsHeaderView.identifier)
        collectionView.register(StatisticsHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: StatisticsHeaderView.identifier)
        
        return collectionView
    }()
    
    private let gameService = GameService.shared
    private let playerService = PlayerService()
    private let statService = StatService.shared
    
    private var currentGame: Game!
    private var playerStats: [PlayerGameStats] = []
    private var inningStats: [(inning: Int, ab: Int, r: Int, h: Int, rbi: Int, hr: Int)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadData()
    }
    
    func configure(with game: Game) {
        self.currentGame = game
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
        title = "Game Summary"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissTapped)
        )
    }
    
    @objc private func dismissTapped() {
        dismiss(animated: true)
    }
    
    private func loadData() {
        Task {
            do {
                Logger.debug("Loading game summary data", category: .games)
                
                // Load player stats for this game
                let players = try await playerService.fetchPlayersInGame(gameId: currentGame.id)
                var gameStats: [PlayerGameStats] = []
                
                for player in players {
                    let stats = try await statService.fetchPlayerStatsForGame(playerId: player.id, gameId: currentGame.id)
                    let playerGameStats = PlayerGameStats(player: player, stats: stats)
                    gameStats.append(playerGameStats)
                }
                
                // Load real inning stats from game data
                let allGameStats = try await statService.fetchStatsForGame(gameId: currentGame.id)
                let realInningStats = self.calculateInningStats(from: allGameStats)
                
                await MainActor.run {
                    self.playerStats = gameStats
                    self.inningStats = realInningStats
                    self.collectionView.reloadData()
                    Logger.info("Successfully loaded game summary data with \(realInningStats.count) innings", category: .games)
                }
            } catch {
                await MainActor.run {
                    Logger.error("Failed to load game summary data: \(error.localizedDescription)", category: .games)
                    self.showAlert(title: "Error", message: "Failed to load game data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func calculateInningStats(from stats: [Stat]) -> [(inning: Int, ab: Int, r: Int, h: Int, rbi: Int, hr: Int)] {
        // Filter out stats without inning numbers and group by inning
        let statsWithInnings = stats.filter { $0.inning != nil }
        let groupedByInning = Dictionary(grouping: statsWithInnings) { $0.inning! }
        
        var inningStats: [(inning: Int, ab: Int, r: Int, h: Int, rbi: Int, hr: Int)] = []
        
        // Calculate stats for each inning
        for (inningNumber, inningStatsList) in groupedByInning.sorted(by: { $0.key < $1.key }) {
            var ab = 0, r = 0, h = 0, rbi = 0, hr = 0
            
            for stat in inningStatsList {
                // Count at-bats (excluding walks)
                switch stat.type {
                case .atBat, .strikeOut, .single, .double, .triple, .homeRun, .flyOut, .error, .fieldersChoice:
                    ab += 1
                case .walk:
                    // Walks don't count as at-bats
                    break
                default:
                    break
                }
                
                // Count hits
                if [.single, .double, .triple, .homeRun].contains(stat.type) {
                    h += 1
                }
                
                // Count home runs and runs
                if stat.type == .homeRun {
                    hr += 1
                    r += 1 // Home runs always count as runs for the batter
                }
                
                // Count additional runs
                if stat.type == .run {
                    r += 1
                }
                
                // Count RBIs
                if let rbiCount = stat.runsBattedIn {
                    rbi += rbiCount
                }
            }
            
            inningStats.append((inning: inningNumber, ab: ab, r: r, h: h, rbi: rbi, hr: hr))
        }
        
        return inningStats
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, environment in
            switch sectionIndex {
            case 0:
                return self.createGameInfoSection(environment: environment)
            case 1:
                return self.createPlayerStatsSection(environment: environment)
            case 2:
                return self.createInningsSection(environment: environment)
            default:
                return self.createGameInfoSection(environment: environment)
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
    
    private func createInningsSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
        
        // Add section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
}

// MARK: - UICollectionViewDataSource

extension GameSummaryViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: // Game Info
            return 4 // opponent, date, score, win/loss
        case 1: // Player Statistics
            return playerStats.count
        case 2: // Innings
            return inningStats.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0: // Game Info
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GameInfoCell", for: indexPath) as! UICollectionViewListCell
            
            var content = cell.defaultContentConfiguration()
            
            switch indexPath.item {
            case 0:
                content.text = "Opponent"
                content.secondaryText = currentGame.opponent
            case 1:
                content.text = "Date"
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                content.secondaryText = formatter.string(from: currentGame.date)
            case 2:
                content.text = "Score"
                let homeScore = currentGame.homeScore ?? 0
                let opponentScore = currentGame.opponentScore ?? 0
                content.secondaryText = "\(homeScore) - \(opponentScore)"
            case 3:
                content.text = "Result"
                if let isWin = currentGame.isWin {
                    content.secondaryText = isWin ? "Win" : "Loss"
                    content.secondaryTextProperties.color = isWin ? .systemGreen : .systemRed
                } else {
                    content.secondaryText = "Unknown"
                }
            default:
                break
            }
            
            cell.contentConfiguration = content
            return cell
            
        case 1: // Player Statistics
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlayerStatCell.identifier, for: indexPath) as! PlayerStatCell
            let playerStat = playerStats[indexPath.item]
            cell.configure(with: playerStat)
            return cell
            
        case 2: // Innings
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InningTotalsCell.identifier, for: indexPath) as! InningTotalsCell
            let inning = inningStats[indexPath.item]
            cell.configure(title: "Inning \(inning.inning)", ab: inning.ab, r: inning.r, h: inning.h, rbi: inning.rbi, hr: inning.hr)
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
                header.configure(title: "PLAYER STATISTICS")
                return header
            case 2:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: InningStatsHeaderView.identifier, for: indexPath) as! InningStatsHeaderView
                header.configure(title: "INNINGS")
                return header
            default:
                break
            }
        }
        return UICollectionReusableView()
    }
}

// MARK: - UICollectionViewDelegate

extension GameSummaryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 1: // Player Statistics
            let playerStat = playerStats[indexPath.item]
            let playerStatVC = PlayerStatViewController()
            playerStatVC.configure(with: playerStat.player, game: currentGame)
            navigationController?.pushViewController(playerStatVC, animated: true)
            
        case 2: // Innings
            let inning = inningStats[indexPath.item]
            let inningDetailVC = InningDetailViewController()
            inningDetailVC.configure(with: currentGame, inning: inning.inning)
            navigationController?.pushViewController(inningDetailVC, animated: true)
            
        default:
            break
        }
    }
}
