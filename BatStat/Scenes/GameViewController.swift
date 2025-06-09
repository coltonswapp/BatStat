import UIKit

class GameViewController: UIViewController {
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .systemGroupedBackground
        
        // Register cells
        collectionView.register(AtBatCell.self, forCellWithReuseIdentifier: AtBatCell.identifier)
        collectionView.register(PlayerStatCell.self, forCellWithReuseIdentifier: PlayerStatCell.identifier)
        collectionView.register(GameCell.self, forCellWithReuseIdentifier: GameCell.identifier)
        collectionView.register(AtBatOutcomeCell.self, forCellWithReuseIdentifier: AtBatOutcomeCell.identifier)
        collectionView.register(ViewAllCell.self, forCellWithReuseIdentifier: ViewAllCell.identifier)
        collectionView.register(AtBatSectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: AtBatSectionHeader.identifier)
        collectionView.register(StatisticsHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: StatisticsHeaderView.identifier)
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.identifier)
        collectionView.register(SectionFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: SectionFooterView.identifier)
        
        return collectionView
    }()
    
    private let playerService = PlayerService()
    private let gameService = GameService.shared
    private let statService = StatService.shared
    private var currentGame: Game?
    private var rosterPlayers: [Player] = []
    private var pastGames: [Game] = []
    private var recentAtBats: [Stat] = []
    private var playerGameStats: [UUID: PlayerGameStats] = [:]
    private var currentAtBatIndex: Int = 0
    private var currentInning: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadData()
    }
    
    
    func configure(with game: Game) {
        self.currentGame = game
        loadData()
    }
    
    private func loadData() {
        guard let game = currentGame else { return }
        
        loadRosterPlayers()
        loadPastGames()
        loadRecentAtBats()
    }
    
    private func loadRosterPlayers() {
        guard let game = currentGame else { return }
        
        Task {
            do {
                Logger.debug("Loading roster players for game: \(game.opponent)", category: .games)
                let players = try await playerService.fetchPlayersInGame(gameId: game.id)
                await MainActor.run {
                    self.rosterPlayers = players
                    self.currentAtBatIndex = 0 // Reset to first player
                    self.collectionView.reloadData()
                    Logger.info("Loaded \(players.count) players in game roster", category: .games)
                    
                    // Load player stats now that we have the roster
                    self.loadPlayerStats()
                }
            } catch {
                await MainActor.run {
                    Logger.error("Failed to load roster players: \(error.localizedDescription)", category: .games)
                    self.rosterPlayers = []
                    self.currentAtBatIndex = 0
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    private func loadPastGames() {
        guard let game = currentGame else { return }
        
        Task {
            do {
                Logger.debug("Loading past games against: \(game.opponent)", category: .games)
                let allGames = try await gameService.fetchAllGames()
                let gamesAgainstOpponent = allGames.filter { 
                    $0.opponent == game.opponent && $0.id != game.id 
                }
                await MainActor.run {
                    self.pastGames = gamesAgainstOpponent
                    self.collectionView.reloadData()
                    Logger.info("Loaded \(gamesAgainstOpponent.count) past games against \(game.opponent)", category: .games)
                }
            } catch {
                await MainActor.run {
                    Logger.error("Failed to load past games: \(error.localizedDescription)", category: .games)
                    self.pastGames = []
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    private func loadRecentAtBats() {
        guard let game = currentGame else { return }
        
        Task {
            do {
                Logger.debug("Loading recent at-bats for game: \(game.opponent)", category: .games)
                let atBats = try await statService.fetchRecentAtBats(gameId: game.id, limit: 10)
                await MainActor.run {
                    self.recentAtBats = atBats
                    self.collectionView.reloadData()
                    Logger.info("Loaded \(atBats.count) recent at-bats", category: .games)
                }
            } catch {
                await MainActor.run {
                    Logger.error("Failed to load recent at-bats: \(error.localizedDescription)", category: .games)
                    self.recentAtBats = []
                    self.collectionView.reloadData()
                }
            }
        }
    }
    
    private func loadPlayerStats() {
        guard let game = currentGame else { return }
        
        Task {
            do {
                Logger.debug("Loading player stats for game: \(game.opponent)", category: .games)
                var statsDict: [UUID: PlayerGameStats] = [:]
                
                for player in rosterPlayers {
                    let playerStats = try await statService.getPlayerGameStats(gameId: game.id, player: player)
                    statsDict[player.id] = playerStats
                }
                
                await MainActor.run {
                    self.playerGameStats = statsDict
                    self.collectionView.reloadData()
                    Logger.info("Loaded stats for \(statsDict.count) players", category: .games)
                }
            } catch {
                await MainActor.run {
                    Logger.error("Failed to load player stats: \(error.localizedDescription)", category: .games)
                    // Create empty stats for all players
                    var emptyStats: [UUID: PlayerGameStats] = [:]
                    for player in self.rosterPlayers {
                        emptyStats[player.id] = PlayerGameStats(player: player, stats: [])
                    }
                    self.playerGameStats = emptyStats
                    self.collectionView.reloadData()
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
        guard let game = currentGame else { return }
        title = "vs. \(game.opponent)"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        let subtitle = dateFormatter.string(from: game.date)
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .label
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        
        navigationItem.titleView = stackView
        
        let menuActions = [
            UIAction(title: "Edit Game", image: UIImage(systemName: "pencil")) { [weak self] _ in
                self?.editGameTapped()
            },
            UIAction(title: "Edit Roster", image: UIImage(systemName: "person.2")) { [weak self] _ in
                self?.editRosterTapped()
            },
            UIAction(title: "End Game", image: UIImage(systemName: "flag.checkered"), attributes: .destructive) { [weak self] _ in
                self?.endGameTapped()
            }
        ]
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            menu: UIMenu(children: menuActions)
        )
    }
    
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, environment in
            switch sectionIndex {
            case 0:
                return self.createAtBatSection()
            case 1:
                return self.createStatisticsSection(environment: environment)
            case 2:
                return self.createRecentAtBatsSection(environment: environment)
            case 3:
                return self.createPastGamesSection()
            default:
                return self.createAtBatSection()
            }
        })
    }
    
    private func createAtBatSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(60))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(60))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 14)
        
        // Add section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        
        // Add section footer
        let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(30))
        let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: footerSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)
        
        section.boundarySupplementaryItems = [header, footer]
        
        return section
    }
    
    private func createStatisticsSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
        
        // Add section header with explicit 44pt height like other sections
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    private func createRecentAtBatsSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
        
        // Add section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    private func createPastGamesSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(120))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(120))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
        section.interGroupSpacing = 12
        
        // Add section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    private func editGameTapped() {
        let editGameVC = EditGameViewController()
        if let game = currentGame {
            editGameVC.configure(with: game)
        }
        let navController = UINavigationController(rootViewController: editGameVC)
        
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(navController, animated: true)
    }
    
    private func editRosterTapped() {
        // TODO: Navigate to roster editing
        print("Edit Roster tapped")
    }
    
    private func endGameTapped() {
        // TODO: Show end game confirmation and logic
        print("End Game tapped")
    }
    
    private func previousPlayer() {
        guard !rosterPlayers.isEmpty else { return }
        
        currentAtBatIndex = (currentAtBatIndex - 1 + rosterPlayers.count) % rosterPlayers.count
        Logger.info("Previous player: \(rosterPlayers[currentAtBatIndex].name) (\(currentAtBatIndex + 1)/\(rosterPlayers.count))", category: .games)
        
        // Reload At Bat and Statistics sections
        collectionView.reloadSections(IndexSet([0, 1]))
    }
    
    private func nextPlayer() {
        guard !rosterPlayers.isEmpty else { return }
        
        currentAtBatIndex = (currentAtBatIndex + 1) % rosterPlayers.count
        Logger.info("Next player: \(rosterPlayers[currentAtBatIndex].name) (\(currentAtBatIndex + 1)/\(rosterPlayers.count))", category: .games)
        
        // Reload At Bat and Statistics sections
        collectionView.reloadSections(IndexSet([0, 1]))
    }
    
    private func incrementInning() {
        currentInning += 1
        Logger.info("Inning incremented to: \(currentInning)", category: .games)
        
        // Reload At Bat section to update the inning display
        collectionView.reloadSections(IndexSet([0]))
    }
    
    private func decrementInning() {
        if currentInning > 1 {
            currentInning -= 1
            Logger.info("Inning decremented to: \(currentInning)", category: .games)
            
            // Reload At Bat section to update the inning display
            collectionView.reloadSections(IndexSet([0]))
        }
    }
    
    @objc private func atBatCellTapped() {
        guard let game = currentGame,
              !rosterPlayers.isEmpty else {
            Logger.notice("Cannot record at-bat: missing game or no players", category: .games)
            return
        }
        
        let currentPlayer = rosterPlayers[currentAtBatIndex]
        let recordAtBatVC = RecordAtBatViewController()
        recordAtBatVC.configure(game: game, player: currentPlayer, inning: currentInning)
        
        // Set completion handler to refresh data and advance to next player
        recordAtBatVC.onAtBatSaved = { [weak self] in
            self?.handleAtBatSaved()
        }
        
        let navController = UINavigationController(rootViewController: recordAtBatVC)
        
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(navController, animated: true)
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
    
    /// Call this method when an at-bat is recorded to refresh the data
    func refreshAfterAtBat() {
        loadRecentAtBats()
        loadPlayerStats()
    }
    
    private func handleAtBatSaved() {
        Logger.info("At-bat saved, refreshing data and advancing to next player", category: .games)
        
        // Refresh the data
        refreshAfterAtBat()
        
        // Advance to next player
        nextPlayer()
    }
}

// MARK: - UICollectionViewDataSource

extension GameViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 4  // At Bat, Statistics, Recent At-Bats, Past Games
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return rosterPlayers.isEmpty ? 0 : 1 // At Bat section (hide if no players)
        case 1:
            return rosterPlayers.count // Statistics section
        case 2:
            // Recent At-Bats section: add 1 for "View All" cell
            return recentAtBats.count > 0 ? recentAtBats.count + 1 : 0 
        case 3:
            return pastGames.count // Past Games section
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AtBatCell.identifier, for: indexPath) as! AtBatCell
            // Show current at-bat player
            let currentPlayer = rosterPlayers.isEmpty ? Player(name: "No Players", number: nil) : rosterPlayers[currentAtBatIndex]
            cell.configure(with: currentPlayer)
            cell.onPreviousPlayer = { [weak self] in
                self?.previousPlayer()
            }
            cell.onNextPlayer = { [weak self] in
                self?.nextPlayer()
            }
            cell.onAtBatTapped = { [weak self] in
                self?.atBatCellTapped()
            }
            cell.onInningIncrement = { [weak self] in
                self?.incrementInning()
            }
            cell.onInningDecrement = { [weak self] in
                self?.decrementInning()
            }
            return cell
            
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlayerStatCell.identifier, for: indexPath) as! PlayerStatCell
            let player = rosterPlayers[indexPath.item]
            
            // Get real stats for the player, or create empty stats if not loaded yet
            let playerStats = playerGameStats[player.id] ?? PlayerGameStats(player: player, stats: [])
            
            let isCurrentAtBat = indexPath.item == currentAtBatIndex // Highlight current at-bat player
            cell.configure(with: playerStats, isCurrentAtBat: isCurrentAtBat)
            return cell
            
        case 2:
            // Recent At-Bats section
            if indexPath.item < recentAtBats.count {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AtBatOutcomeCell.identifier, for: indexPath) as! AtBatOutcomeCell
                let atBat = recentAtBats[indexPath.item]
                
                // Find the player for this at-bat
                let player = rosterPlayers.first { $0.id == atBat.playerId } ?? Player(name: "Unknown", number: nil)
                let outcome = formatAtBatOutcome(atBat)
                
                cell.configure(playerName: player.name, outcome: outcome, statType: atBat.type)
                return cell
            } else {
                // This is the "View All" cell at the bottom
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ViewAllCell.identifier, for: indexPath) as! ViewAllCell
                return cell
            }
            
        case 3:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GameCell.identifier, for: indexPath) as! GameCell
            let game = pastGames[indexPath.item]
            cell.configure(with: game)
            return cell
            
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            switch indexPath.section {
            case 0:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: AtBatSectionHeader.identifier, for: indexPath) as! AtBatSectionHeader
                header.configure(inning: currentInning)
                return header
            case 1:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: StatisticsHeaderView.identifier, for: indexPath) as! StatisticsHeaderView
                header.configure(title: "Statistics")
                return header
            case 2:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
                header.configure(title: "PLAY-BY-PLAY")
                return header
            case 3:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
                header.configure(title: "PAST GAMES")
                return header
            default:
                break
            }
        } else if kind == UICollectionView.elementKindSectionFooter {
            switch indexPath.section {
            case 0:
                let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionFooterView.identifier, for: indexPath) as! SectionFooterView
                footer.configure(title: "Tap to record AB • Long press to change inning")
                return footer
            default:
                break
            }
        }
        return UICollectionReusableView()
    }
}

// MARK: - UICollectionViewDelegate

extension GameViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            atBatCellTapped()
        case 1:
            let player = rosterPlayers[indexPath.item]
            let playerStatVC = PlayerStatViewController()
            if let game = currentGame {
                playerStatVC.configure(with: player, game: game)
            }
            navigationController?.pushViewController(playerStatVC, animated: true)
        case 2:
            // Recent At-Bats section
            if indexPath.item < recentAtBats.count {
                // Regular at-bat cell tapped
                let atBat = recentAtBats[indexPath.item]
                Logger.debug("At-bat tapped", category: .games)
                // TODO: Show at-bat details or allow editing
            } else {
                // "View All" cell tapped - navigate to PlayByPlayViewController
                guard let game = currentGame else { return }
                
                let playByPlayVC = PlayByPlayViewController()
                playByPlayVC.configure(with: game)
                navigationController?.pushViewController(playByPlayVC, animated: true)
                Logger.debug("View All Play-by-Play tapped", category: .games)
            }
        case 3:
            // TODO: Navigate to past game details
            Logger.debug("Past game tapped - navigation not implemented yet", category: .games)
        default:
            break
        }
    }
}
