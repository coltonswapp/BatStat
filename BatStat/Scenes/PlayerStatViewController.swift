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
        
        // Register footer view for spray chart legend
        collectionView.register(SprayChartLegendFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: SprayChartLegendFooterView.identifier)
        
        return collectionView
    }()
    
    private let statService = StatService.shared
    private var player: Player?
    private var currentGame: Game?
    private var playerStats: PlayerGameStats?
    private var playerAtBats: [Stat] = []
    private var atBatOutcomes: [(number: Int, outcome: String, statType: StatType, inning: Int?)] = []
    private var mockHitStats: [Stat] = []
    private var selectedAtBatIndex: Int? // Track which at-bat is selected for highlighting
    private var spraySheetViewController: SpraySheetViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadData()
        
        // Register cells and supplementary views
        collectionView.register(PlayerStatCell.self, forCellWithReuseIdentifier: PlayerStatCell.identifier)
        collectionView.register(AtBatOutcomeCell.self, forCellWithReuseIdentifier: AtBatOutcomeCell.identifier)
        collectionView.register(AddAtBatCell.self, forCellWithReuseIdentifier: AddAtBatCell.identifier)
        collectionView.register(DiamondVisualizationCell.self, forCellWithReuseIdentifier: DiamondVisualizationCell.identifier)
        
        // Register header views
        collectionView.register(StatisticsHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: StatisticsHeaderView.identifier)
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.identifier)
        
        // Register footer view for spray chart legend
        collectionView.register(SprayChartLegendFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: SprayChartLegendFooterView.identifier)
    }
    
    func configure(with player: Player, game: Game) {
        self.player = player
        self.currentGame = game
        loadData()
    }
    
    private func loadData() {
        guard let player = player, let game = currentGame else { return }
        
        Task {
            do {
                // Fetch real stats for this player in this game
                let stats = try await statService.fetchPlayerGameStats(gameId: game.id, playerId: player.id)
                playerStats = statService.calculatePlayerGameStats(player: player, stats: stats)
                playerAtBats = stats
                
                // Convert stats to at-bat outcomes for display
                // Only include stats that have an at-bat number (actual at-bats)
                atBatOutcomes = stats.compactMap { stat in
                    guard let atBatNumber = stat.atBatNumber else { return nil }
                    let outcome = formatAtBatOutcome(stat)
                    return (number: atBatNumber, outcome: outcome, statType: stat.type, inning: stat.inning)
                }.sorted { $0.number < $1.number } // Sort by at-bat number to ensure proper order
                
                // Use real hit data from stats that have hit locations
                mockHitStats = stats.filter { $0.hitLocation != nil }
                
                await MainActor.run {
                    collectionView.reloadData()
                }
                
                // Present spray sheet automatically after data loads
//                await MainActor.run {
//                    self.presentSpraySheet()
//                }
            } catch {
                print("Error loading player data: \(error)")
                // Fallback to empty data
                playerStats = PlayerGameStats(player: player, stats: [])
                playerAtBats = []
                atBatOutcomes = []
                mockHitStats = []
                
                await MainActor.run {
                    collectionView.reloadData()
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
    
    /// Call this method when an at-bat is recorded to refresh the data
    func refreshAfterAtBat() {
        loadData()
        // Also refresh the spray sheet if it's presented
        refreshSpraySheet()
    }
    
    private func presentInteractiveDiamond() {
        guard let player = player, let game = currentGame else { return }
        
        let recordAtBatVC = RecordAtBatViewController()
        recordAtBatVC.configure(game: game, player: player)
        recordAtBatVC.onAtBatSaved = { [weak self] in
            self?.refreshAfterAtBat()
        }
        
        let navController = UINavigationController(rootViewController: recordAtBatVC)
        
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(navController, animated: true)
    }
    
    private func presentSpraySheet() {
        guard let player = player, let game = currentGame else { return }
        
        // Don't present if already presented
        if spraySheetViewController != nil { return }
        
        let spraySheetVC = SpraySheetViewController()
        spraySheetVC.configure(with: player, game: game, atBats: playerAtBats)
        
        let navController = UINavigationController(rootViewController: spraySheetVC)
        
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.largestUndimmedDetentIdentifier = .medium
            sheet.prefersGrabberVisible = true
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        
        // Store reference to update it later
        spraySheetViewController = spraySheetVC
        
        present(navController, animated: true)
        
        // Clear reference when dismissed
        navController.presentationController?.delegate = self
    }
    
    private func refreshSpraySheet() {
        guard let spraySheetVC = spraySheetViewController,
              let player = player,
              let game = currentGame else { return }
        
        spraySheetVC.configure(with: player, game: game, atBats: playerAtBats)
        spraySheetVC.updateSelectedAtBat(selectedAtBatIndex)
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
            return 1 // Always show diamond visualization section
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
                cell.configure(atBatNumber: outcome.number, outcome: outcome.outcome, statType: outcome.statType, inning: outcome.inning)
                return cell
            } else {
                // "Add new at-bat" cell
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AddAtBatCell.identifier, for: indexPath) as! AddAtBatCell
                return cell
            }
            
        case 2:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiamondVisualizationCell.identifier, for: indexPath) as! DiamondVisualizationCell
            
            // Show hits with real data from this game
            let hitsWithLocation = playerAtBats.filter { $0.hitLocation != nil }
            cell.configure(with: hitsWithLocation, selectedAtBatNumber: selectedAtBatIndex)
            
            // TEMPORARY: Enable grid visibility for debugging (remove this later)
            DispatchQueue.main.async {
                if let diamondView = cell.subviews.first(where: { $0 is DiamondVisualizationView }) as? DiamondVisualizationView {
                    diamondView.setGridVisible(true)
                }
            }
            
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
                header.configure(title: "SPRAY CHART")
                return header
            default:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
                header.configure(title: "")
                return header
            }
        } else if kind == UICollectionView.elementKindSectionFooter {
            // Only section 2 (spray chart) has a footer
            if indexPath.section == 2 {
                let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SprayChartLegendFooterView.identifier, for: indexPath) as! SprayChartLegendFooterView
                return footer
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
                // Handle existing at-bat outcome tap - highlight corresponding hit
                let tappedAtBatNumber = atBatOutcomes[indexPath.item].number // Use actual at-bat number from data
                
                if selectedAtBatIndex == tappedAtBatNumber {
                    // Deselect if already selected
                    selectedAtBatIndex = nil
                } else {
                    // Select this at-bat for highlighting
                    selectedAtBatIndex = tappedAtBatNumber
                }
                
                // Reload the diamond visualization section to update highlighting
                collectionView.reloadSections(IndexSet([2]))
                
                // Also update the spray sheet if it's presented
                spraySheetViewController?.updateSelectedAtBat(selectedAtBatIndex)
                
                print("At-bat #\(tappedAtBatNumber) tapped - highlighting: \(selectedAtBatIndex != nil)")
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
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension PlayerStatViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        // Clear the spray sheet reference when it's dismissed
        spraySheetViewController = nil
    }
}
