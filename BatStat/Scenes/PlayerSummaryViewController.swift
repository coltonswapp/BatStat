import UIKit

class PlayerSummaryViewController: UIViewController {
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .systemGroupedBackground
        
        // Register cells
        collectionView.register(PlayerStatCell.self, forCellWithReuseIdentifier: PlayerStatCell.identifier)
        collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: "GameSummaryCell")
        collectionView.register(StatisticsHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: StatisticsHeaderView.identifier)
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.identifier)
        
        return collectionView
    }()
    
    private let statService = StatService.shared
    private let gameService = GameService.shared
    private var player: Player?
    private var overallStats: PlayerGameStats?
    private var gameStats: [(game: Game, stats: PlayerGameStats)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadData()
    }
    
    func configure(with player: Player) {
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
        guard let player = player else { return }
        title = player.name
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, environment in
            switch sectionIndex {
            case 0:
                return self.createOverallStatsSection(environment: environment)
            case 1:
                return self.createGameStatsSection(environment: environment)
            default:
                return self.createOverallStatsSection(environment: environment)
            }
        })
    }
    
    private func createOverallStatsSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
        
        // Add section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    private func createGameStatsSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
        
        // Add section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    private func loadData() {
        guard let player = player else { return }
        
        Task {
            do {
                // Fetch all games
                let allGames = try await gameService.fetchAllGames()
                
                // Fetch stats for this player across all games
                var allStats: [Stat] = []
                var gameStatsArray: [(game: Game, stats: PlayerGameStats)] = []
                
                for game in allGames {
                    let playerGameStats = try await statService.fetchPlayerGameStats(gameId: game.id, playerId: player.id)
                    allStats.append(contentsOf: playerGameStats)
                    
                    let calculatedStats = statService.calculatePlayerGameStats(player: player, stats: playerGameStats)
                    // Only include games where the player has stats
                    if !playerGameStats.isEmpty {
                        gameStatsArray.append((game: game, stats: calculatedStats))
                    }
                }
                
                // Calculate overall stats from all games
                let overallPlayerStats = statService.calculatePlayerGameStats(player: player, stats: allStats)
                
                await MainActor.run {
                    self.overallStats = overallPlayerStats
                    self.gameStats = gameStatsArray.sorted { $0.game.date > $1.game.date } // Most recent first
                    self.collectionView.reloadData()
                }
            } catch {
                await MainActor.run {
                    print("Error loading player summary data: \(error)")
                    self.showAlert(title: "Error", message: "Failed to load player data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension PlayerSummaryViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2 // Overall stats + Game-by-game stats
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return overallStats != nil ? 1 : 0 // Overall stats
        case 1:
            return gameStats.count // Game-by-game stats
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            // Overall stats
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlayerStatCell.identifier, for: indexPath) as! PlayerStatCell
            if let overallStats = overallStats {
                cell.configure(with: overallStats, isCurrentAtBat: false)
            }
            return cell
            
        case 1:
            // Game-by-game stats
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GameSummaryCell", for: indexPath) as! UICollectionViewListCell
            let gameData = gameStats[indexPath.item]
            
            var content = cell.defaultContentConfiguration()
            
            // Format date
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            content.text = "vs \(gameData.game.opponent)"
            content.secondaryText = formatter.string(from: gameData.game.date)
            
            // Show key stats in secondary text
            let stats = gameData.stats
            let battingAvg = String(format: "%.3f", stats.battingAverage)
            content.secondaryText = "\(formatter.string(from: gameData.game.date)) • \(stats.hits)/\(stats.atBats), \(battingAvg) AVG"
            
            cell.contentConfiguration = content
            cell.accessories = [.disclosureIndicator()]
            
            return cell
            
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            switch indexPath.section {
            case 0:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: StatisticsHeaderView.identifier, for: indexPath) as! StatisticsHeaderView
                header.configure(title: "CAREER TOTALS")
                return header
            case 1:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
                header.configure(title: "GAME BY GAME")
                return header
            default:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
                header.configure(title: "")
                return header
            }
        }
        return UICollectionReusableView()
    }
}

// MARK: - UICollectionViewDelegate

extension PlayerSummaryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            // Overall stats tapped - could show more detailed breakdown
            break
        case 1:
            // Game stats tapped - show detailed game view
            let gameData = gameStats[indexPath.item]
            let playerGameSummaryVC = PlayerGameSummaryViewController()
            playerGameSummaryVC.configure(with: gameData.game, player: player!)
            navigationController?.pushViewController(playerGameSummaryVC, animated: true)
        default:
            break
        }
    }
}