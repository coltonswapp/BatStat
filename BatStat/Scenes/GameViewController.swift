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
        collectionView.register(StatisticsHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: StatisticsHeaderView.identifier)
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.identifier)
        collectionView.register(SectionFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: SectionFooterView.identifier)
        
        return collectionView
    }()
    
    private let mockDataManager = MockDataManager.shared
    private var currentGame: Game?
    private var playerStats: [PlayerGameStats] = []
    private var pastGames: [Game] = []
    private var recentAtBats: [(player: Player, outcome: String)] = []
    
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
        guard let game = currentGame else {
            // Default to current game if no game provided
            currentGame = mockDataManager.currentGame
            return
        }
        
        guard let game = currentGame else { return }
        
        playerStats = mockDataManager.getAllPlayerStats(for: game.id)
        pastGames = mockDataManager.getGamesAgainst(opponent: game.opponent).filter { $0.id != game.id }
        
        // Mock recent at-bats data
        let players = mockDataManager.getPlayersInGame(gameId: game.id)
        recentAtBats = [
            (player: players[0], outcome: "Single"),
            (player: players[1], outcome: "Strikeout"),
            (player: players[2], outcome: "RBI Double"),
            (player: players[3], outcome: "Fly out"),
            (player: players[0], outcome: "Home Run"),
            (player: players[1], outcome: "Ground out"),
            (player: players[2], outcome: "Walk"),
            (player: players[3], outcome: "Single"),
            (player: players[0], outcome: "Foul Ball"),
            (player: players[1], outcome: "Triple")
        ]
        
        collectionView.reloadData()
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
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
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
    
    @objc private func previousPlayerTapped() {
        _ = mockDataManager.previousAtBatPlayer()
        collectionView.reloadSections(IndexSet([0, 1]))
    }
    
    @objc private func nextPlayerTapped() {
        _ = mockDataManager.nextAtBatPlayer()
        collectionView.reloadSections(IndexSet([0, 1]))
    }
    
    @objc private func atBatCellTapped() {
        let recordAtBatVC = RecordAtBatViewController()
        let navController = UINavigationController(rootViewController: recordAtBatVC)
        
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(navController, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension GameViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1 // At Bat section
        case 1:
            return playerStats.count // Statistics section
        case 2:
            return recentAtBats.count + 1 // Recent at-bats + "View All" cell
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
            let currentPlayer = mockDataManager.getCurrentAtBatPlayer()
            cell.configure(with: currentPlayer)
            cell.onPreviousPlayer = { [weak self] in
                self?.previousPlayerTapped()
            }
            cell.onNextPlayer = { [weak self] in
                self?.nextPlayerTapped()
            }
            cell.onAtBatTapped = { [weak self] in
                self?.atBatCellTapped()
            }
            return cell
            
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlayerStatCell.identifier, for: indexPath) as! PlayerStatCell
            let playerStat = playerStats[indexPath.item]
            let currentAtBatPlayer = mockDataManager.getCurrentAtBatPlayer()
            let isCurrentAtBat = playerStat.player.id == currentAtBatPlayer.id
            cell.configure(with: playerStat, isCurrentAtBat: isCurrentAtBat)
            return cell
            
        case 2:
            if indexPath.item < recentAtBats.count {
                // Recent at-bat cell
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AtBatOutcomeCell.identifier, for: indexPath) as! AtBatOutcomeCell
                let atBat = recentAtBats[indexPath.item]
                cell.configure(playerName: atBat.player.name, outcome: atBat.outcome)
                return cell
            } else {
                // "View All" cell
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
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
                header.configure(title: "AT BAT")
                return header
            case 1:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: StatisticsHeaderView.identifier, for: indexPath) as! StatisticsHeaderView
                header.configure(title: "Statistics")
                return header
            case 2:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
                header.configure(title: "RECENT AT-BATS")
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
                footer.configure(title: "Tap to record AB outcomes")
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
            let playerStat = playerStats[indexPath.item]
            let playerStatVC = PlayerStatViewController()
            if let game = currentGame {
                playerStatVC.configure(with: playerStat.player, game: game)
            }
            navigationController?.pushViewController(playerStatVC, animated: true)
        case 2:
            if indexPath.item < recentAtBats.count {
                // TODO: Handle specific at-bat tap
                print("Recent at-bat tapped")
            } else {
                // "View All" cell tapped - navigate to PlayByPlayViewController
                let playByPlayVC = PlayByPlayViewController()
                if let game = currentGame {
                    playByPlayVC.configure(with: game)
                }
                navigationController?.pushViewController(playByPlayVC, animated: true)
            }
        case 3:
            // TODO: Navigate to past game details
            print("Past game tapped")
        default:
            break
        }
    }
}
