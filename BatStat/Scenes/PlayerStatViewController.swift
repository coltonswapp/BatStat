import UIKit

class PlayerStatViewController: UIViewController {
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .systemGroupedBackground
        
        // Register cells
        collectionView.register(PlayerStatCell.self, forCellWithReuseIdentifier: PlayerStatCell.identifier)
        collectionView.register(AtBatOutcomeCell.self, forCellWithReuseIdentifier: AtBatOutcomeCell.identifier)
        collectionView.register(AddAtBatCell.self, forCellWithReuseIdentifier: AddAtBatCell.identifier)
        collectionView.register(DiamondVisualizationCell.self, forCellWithReuseIdentifier: DiamondVisualizationCell.identifier)
        collectionView.register(StatisticsHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: StatisticsHeaderView.identifier)
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.identifier)
        
        return collectionView
    }()
    
    private let mockDataManager = MockDataManager.shared
    private var player: Player?
    private var currentGame: Game?
    private var playerStats: PlayerGameStats?
    private var atBatOutcomes: [(number: Int, outcome: String)] = []
    private var mockHitStats: [Stat] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadData()
    }
    
    func configure(with player: Player, game: Game) {
        self.player = player
        self.currentGame = game
        loadData()
    }
    
    private func loadData() {
        guard let player = player, let game = currentGame else { return }
        
        playerStats = mockDataManager.getPlayerStats(for: player.id, in: game.id)
        
        // Mock at-bat outcomes for this player
        atBatOutcomes = [
            (number: 1, outcome: "Single"),
            (number: 2, outcome: "Strikeout"),
            (number: 3, outcome: "RBI Double"),
            (number: 4, outcome: "Fly out")
        ]
        
        // Mock hit data with locations for visualization (correlate with at-bat outcomes)
        mockHitStats = [
            Stat(gameId: game.id, playerId: player.id, type: .single, value: 1,
                 hitLocation: HitLocation(point: CGPoint(x: 120, y: 180), height: 0.3, fieldSize: CGSize(width: 300, height: 240))),
            Stat(gameId: game.id, playerId: player.id, type: .double, value: 3,
                 hitLocation: HitLocation(point: CGPoint(x: 50, y: 100), height: 0.7, fieldSize: CGSize(width: 300, height: 240))),
            Stat(gameId: game.id, playerId: player.id, type: .single, value: 4,
                 hitLocation: HitLocation(point: CGPoint(x: 200, y: 160), height: 0.2, fieldSize: CGSize(width: 300, height: 240)))
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
        guard let player = player else { return }
        title = player.name
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, environment in
            switch sectionIndex {
            case 0:
                return self.createPlayerStatsSection(environment: environment)
            case 1:
                return self.createAtBatOutcomesSection(environment: environment)
            case 2:
                return self.createDiamondVisualizationSection(environment: environment)
            default:
                return self.createPlayerStatsSection(environment: environment)
            }
        })
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
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
        
        // Add section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
}

// MARK: - UICollectionViewDataSource

extension PlayerStatViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return playerStats != nil ? 1 : 0 // Player stats section
        case 1:
            return atBatOutcomes.count + 1 // At-bat outcomes + add new row
        case 2:
            return mockHitStats.isEmpty ? 0 : 1 // Diamond visualization section
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlayerStatCell.identifier, for: indexPath) as! PlayerStatCell
            if let playerStats = playerStats {
                cell.configure(with: playerStats, isCurrentAtBat: false)
            }
            return cell
            
        case 1:
            if indexPath.item < atBatOutcomes.count {
                // Regular at-bat outcome cell
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AtBatOutcomeCell.identifier, for: indexPath) as! AtBatOutcomeCell
                let outcome = atBatOutcomes[indexPath.item]
                cell.configure(atBatNumber: outcome.number, outcome: outcome.outcome)
                return cell
            } else {
                // "Add new at-bat" cell
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddAtBatCell.identifier, for: indexPath) as! AddAtBatCell
                return cell
            }
            
        case 2:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiamondVisualizationCell.identifier, for: indexPath) as! DiamondVisualizationCell
            cell.configure(with: mockHitStats)
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
                header.configure(title: "TONIGHT")
                return header
            case 1:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
                header.configure(title: "AT BATS")
                return header
            case 2:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
                header.configure(title: "HIT CHART")
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

extension PlayerStatViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            // TODO: Handle player stats tap
            print("Player stats tapped")
        case 1:
            if indexPath.item < atBatOutcomes.count {
                // TODO: Handle existing at-bat outcome tap
                print("At-bat outcome tapped")
            } else {
                // Handle "Add new at-bat" tap
                presentInteractiveDiamond()
            }
        case 2:
            // TODO: Handle hit chart tap - maybe show full screen version
            print("Hit chart tapped")
        default:
            break
        }
    }
    
    private func presentInteractiveDiamond() {
        let recordAtBatVC = RecordAtBatViewController()
        let navController = UINavigationController(rootViewController: recordAtBatVC)
        
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(navController, animated: true)
    }
}
