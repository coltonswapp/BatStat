import UIKit

class InningDetailViewController: UIViewController {
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .systemGroupedBackground
        
        // Register cells
        collectionView.register(InningTotalsCell.self, forCellWithReuseIdentifier: InningTotalsCell.identifier)
        collectionView.register(AtBatOutcomeCell.self, forCellWithReuseIdentifier: AtBatOutcomeCell.identifier)
        collectionView.register(DiamondVisualizationCell.self, forCellWithReuseIdentifier: DiamondVisualizationCell.identifier)
        collectionView.register(InningStatsHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: InningStatsHeaderView.identifier)
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.identifier)
        
        return collectionView
    }()
    
    private let statService = StatService.shared
    private let playerService = PlayerService()
    
    private var currentGame: Game!
    private var inningNumber: Int = 1
    private var inningStats: [Stat] = []
    private var inningHits: [Stat] = []
    private var selectedAtBatNumber: Int?
    private var inningTotals: (ab: Int, r: Int, h: Int, rbi: Int, hr: Int) = (0, 0, 0, 0, 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadData()
    }
    
    func configure(with game: Game, inning: Int) {
        self.currentGame = game
        self.inningNumber = inning
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
        title = "Inning \(inningNumber)"
    }
    
    private func loadData() {
        Task {
            do {
                Logger.debug("Loading inning \(inningNumber) data for game \(currentGame.id)", category: .games)
                
                // Load all stats for this inning
                let allStats = try await statService.fetchStatsForGame(gameId: currentGame.id)
                let inningOnlyStats = allStats.filter { $0.inning == inningNumber }
                
                // Separate hits from other stats for spray chart
                let hits = inningOnlyStats.filter { stat in
                    return stat.hitLocation != nil && [.single, .double, .triple, .homeRun].contains(stat.type)
                }
                
                // Sort hits by timestamp to ensure proper numbering
                let sortedHits = hits.sorted { $0.timestamp < $1.timestamp }
                
                // Create modified hits with sequential numbering (1, 2, 3, etc.)
                let hitsWithSequentialNumbers = sortedHits.enumerated().map { index, hit in
                    var modifiedHit = hit
                    modifiedHit.atBatNumber = index + 1 // Sequential numbering starting from 1
                    return modifiedHit
                }
                
                // Calculate inning totals
                let totals = self.calculateInningTotals(from: inningOnlyStats)
                
                await MainActor.run {
                    self.inningStats = inningOnlyStats
                    self.inningHits = hitsWithSequentialNumbers
                    self.inningTotals = totals
                    self.collectionView.reloadData()
                    Logger.info("Successfully loaded \(inningOnlyStats.count) stats for inning \(self.inningNumber)", category: .games)
                }
            } catch {
                await MainActor.run {
                    Logger.error("Failed to load inning data: \(error.localizedDescription)", category: .games)
                    self.showAlert(title: "Error", message: "Failed to load inning data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func calculateInningTotals(from stats: [Stat]) -> (ab: Int, r: Int, h: Int, rbi: Int, hr: Int) {
        var ab = 0, r = 0, h = 0, rbi = 0, hr = 0
        
        for stat in stats {
            switch stat.type {
            case .atBat, .strikeOut, .single, .double, .triple, .homeRun, .flyOut, .error, .fieldersChoice:
                ab += 1
            case .walk:
                // Walks don't count as at-bats
                break
            default:
                break
            }
            
            if [.single, .double, .triple, .homeRun].contains(stat.type) {
                h += 1
            }
            
            if stat.type == .homeRun {
                hr += 1
                r += 1 // Home runs always count as runs for the batter
            }
            
            if stat.type == .run {
                r += 1
            }
            
            if let rbiCount = stat.runsBattedIn {
                rbi += rbiCount
            }
        }
        
        return (ab: ab, r: r, h: h, rbi: rbi, hr: hr)
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
                return self.createAtBatsSection(environment: environment)
            case 1:
                return self.createSprayChartSection(environment: environment)
            default:
                return self.createAtBatsSection(environment: environment)
            }
        })
    }
    
    private func createAtBatsSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
        
        // Add section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    private func createSprayChartSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(300))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(300))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
        
        // Add section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
}

// MARK: - UICollectionViewDataSource

extension InningDetailViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2 // At-bats section and spray chart section
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: // At-bats (InningTotalsCell + at-bat outcome cells)
            return 1 + inningStats.count // 1 for totals cell + number of at-bats
        case 1: // Spray chart
            return inningHits.isEmpty ? 0 : 1
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0: // At-bats
            if indexPath.item == 0 {
                // First cell: InningTotalsCell
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InningTotalsCell.identifier, for: indexPath) as! InningTotalsCell
                cell.configure(title: "Inning \(inningNumber) Totals", ab: inningTotals.ab, r: inningTotals.r, h: inningTotals.h, rbi: inningTotals.rbi, hr: inningTotals.hr)
                return cell
            } else {
                // Subsequent cells: AtBatOutcomeCells
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AtBatOutcomeCell.identifier, for: indexPath) as! AtBatOutcomeCell
                let stat = inningStats[indexPath.item - 1] // Subtract 1 because first cell is totals
                
                // Configure with stat data - load player info asynchronously
                Task {
                    do {
                        let player = try await playerService.fetchPlayer(by: stat.playerId)
                        await MainActor.run {
                            cell.configure(
                                playerName: player.name,
                                outcome: stat.outcome ?? stat.type.rawValue,
                                statType: stat.type
                            )
                        }
                    } catch {
                        Logger.error("Failed to load player for stat: \(error.localizedDescription)", category: .games)
                        // Fallback configuration
                        await MainActor.run {
                            cell.configure(
                                playerName: "Unknown Player",
                                outcome: stat.outcome ?? stat.type.rawValue,
                                statType: stat.type
                            )
                        }
                    }
                }
                
                return cell
            }
            
        case 1: // Spray chart
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DiamondVisualizationCell.identifier, for: indexPath) as! DiamondVisualizationCell
            cell.configure(with: inningHits, selectedAtBatNumber: selectedAtBatNumber)
            
            // Add tap gesture to handle hit selection
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(sprayChartTapped(_:)))
            cell.addGestureRecognizer(tapGesture)
            cell.isUserInteractionEnabled = true
            
            return cell
            
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            switch indexPath.section {
            case 0:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: InningStatsHeaderView.identifier, for: indexPath) as! InningStatsHeaderView
                header.configure(title: "Inning \(inningNumber) At-Bats")
                return header
            case 1:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
                header.configure(title: "SPRAY CHART")
                return header
            default:
                break
            }
        }
        return UICollectionReusableView()
    }
}

// MARK: - UICollectionViewDelegate

extension InningDetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        // Handle at-bat cell taps to highlight corresponding hit
        if indexPath.section == 0 && indexPath.item > 0 { // Skip the totals cell (item 0)
            let stat = inningStats[indexPath.item - 1] // Subtract 1 because first cell is totals
            
            // Find if this stat corresponds to a hit in our sequential hit list
            if let originalAtBatNumber = stat.atBatNumber,
               let hitIndex = inningHits.firstIndex(where: { hit in
                   // Find the original hit by matching other properties since we changed atBatNumber
                   return hit.playerId == stat.playerId && 
                          hit.timestamp == stat.timestamp &&
                          hit.type == stat.type
               }) {
                let sequentialHitNumber = hitIndex + 1 // Convert to 1-based numbering
                
                // Toggle selection if tapping the same hit, otherwise select new one
                if selectedAtBatNumber == sequentialHitNumber {
                    selectedAtBatNumber = nil
                } else {
                    selectedAtBatNumber = sequentialHitNumber
                }
                
                // Reload spray chart to update highlighting
                if collectionView.numberOfItems(inSection: 1) > 0 {
                    let sprayChartIndexPath = IndexPath(item: 0, section: 1)
                    collectionView.reloadItems(at: [sprayChartIndexPath])
                }
            }
        }
    }
    
    @objc private func sprayChartTapped(_ gesture: UITapGestureRecognizer) {
        guard let cell = gesture.view as? DiamondVisualizationCell else { return }
        
        let location = gesture.location(in: cell)
        
        // Find the closest hit to the tap location
        var closestHit: Stat?
        var closestDistance: CGFloat = CGFloat.greatestFiniteMagnitude
        
        for hit in inningHits {
            guard let hitLocation = hit.hitLocation else { continue }
            
            // Convert hit location to screen coordinates
            let cellBounds = cell.bounds
            let screenPoint = CGPoint(
                x: CGFloat(hitLocation.x) * cellBounds.width,
                y: CGFloat(hitLocation.y) * cellBounds.height
            )
            
            let distance = sqrt(pow(location.x - screenPoint.x, 2) + pow(location.y - screenPoint.y, 2))
            
            if distance < closestDistance && distance < 30 { // 30 point hit detection radius
                closestDistance = distance
                closestHit = hit
            }
        }
        
        // Update selection based on closest hit
        if let hit = closestHit, let sequentialHitNumber = hit.atBatNumber {
            // Toggle selection if tapping the same hit, otherwise select new one
            if selectedAtBatNumber == sequentialHitNumber {
                selectedAtBatNumber = nil
            } else {
                selectedAtBatNumber = sequentialHitNumber
            }
            
            // Reload spray chart to update highlighting
            collectionView.reloadItems(at: [IndexPath(item: 0, section: 1)])
            
            // Find the corresponding stat in the original stats list
            let hitIndex = sequentialHitNumber - 1 // Convert to 0-based index
            if hitIndex < inningHits.count {
                let hitToMatch = inningHits[hitIndex]
                
                // Find the corresponding stat by matching properties
                if let statIndex = inningStats.firstIndex(where: { stat in
                    return stat.playerId == hitToMatch.playerId &&
                           stat.timestamp == hitToMatch.timestamp &&
                           stat.type == hitToMatch.type
                }) {
                    let atBatIndexPath = IndexPath(item: statIndex + 1, section: 0) // Add 1 because first cell is totals
                    collectionView.scrollToItem(at: atBatIndexPath, at: .top, animated: true)
                    
                    // Briefly select the cell to show the connection
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.collectionView.selectItem(at: atBatIndexPath, animated: true, scrollPosition: [])
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.collectionView.deselectItem(at: atBatIndexPath, animated: true)
                        }
                    }
                }
            }
        } else {
            // Tapped empty area, clear selection
            selectedAtBatNumber = nil
            collectionView.reloadItems(at: [IndexPath(item: 0, section: 1)])
        }
    }
}
