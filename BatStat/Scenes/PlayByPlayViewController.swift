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
    
    private let mockDataManager = MockDataManager.shared
    private var currentGame: Game?
    private var inningData: [(inning: Int, atBats: [(player: Player, outcome: String)])] = []
    
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
        
        let players = mockDataManager.getPlayersInGame(gameId: game.id)
        
        // Mock play-by-play data organized by inning
        inningData = [
            (inning: 1, atBats: [
                (player: players[0], outcome: "Single"),
                (player: players[1], outcome: "Strikeout"),
                (player: players[2], outcome: "RBI Double"),
                (player: players[3], outcome: "Fly out")
            ]),
            (inning: 2, atBats: [
                (player: players[0], outcome: "Home Run"),
                (player: players[1], outcome: "Ground out"),
                (player: players[2], outcome: "Walk")
            ]),
            (inning: 3, atBats: [
                (player: players[3], outcome: "Single"),
                (player: players[0], outcome: "Foul Ball"),
                (player: players[1], outcome: "Triple"),
                (player: players[2], outcome: "Strikeout")
            ])
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
    
    private func calculateInningStats(for section: Int) -> (ab: Int, r: Int, h: Int, rbi: Int, hr: Int) {
        let atBats = inningData[section].atBats
        var ab = 0, r = 0, h = 0, rbi = 0, hr = 0
        
        for atBat in atBats {
            ab += 1 // Each at-bat counts
            
            switch atBat.outcome.lowercased() {
            case let outcome where outcome.contains("single"):
                h += 1
                if outcome.contains("rbi") { rbi += 1 }
            case let outcome where outcome.contains("double"):
                h += 1
                if outcome.contains("rbi") { rbi += 1 }
            case let outcome where outcome.contains("triple"):
                h += 1
                if outcome.contains("rbi") { rbi += 1 }
            case let outcome where outcome.contains("home run"):
                h += 1
                hr += 1
                r += 1
                rbi += 1
            case let outcome where outcome.contains("rbi"):
                rbi += 1
            default:
                break
            }
        }
        
        return (ab: ab, r: r, h: h, rbi: rbi, hr: hr)
    }
}

// MARK: - UICollectionViewDataSource

extension PlayByPlayViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return inningData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return inningData[section].atBats.count + 1 // +1 for inning totals cell
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            // First cell shows inning totals
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InningTotalsCell.identifier, for: indexPath) as! InningTotalsCell
            let inningStats = calculateInningStats(for: indexPath.section)
            cell.configure(ab: inningStats.ab, r: inningStats.r, h: inningStats.h, rbi: inningStats.rbi, hr: inningStats.hr)
            return cell
        } else {
            // Subsequent cells show at-bat outcomes
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AtBatOutcomeCell.identifier, for: indexPath) as! AtBatOutcomeCell
            let atBat = inningData[indexPath.section].atBats[indexPath.item - 1]
            cell.configure(playerName: atBat.player.name, outcome: atBat.outcome)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: InningStatsHeaderView.identifier, for: indexPath) as! InningStatsHeaderView
            let inning = inningData[indexPath.section].inning
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