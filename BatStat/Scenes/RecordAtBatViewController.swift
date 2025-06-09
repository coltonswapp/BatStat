import UIKit

class RecordAtBatViewController: UIViewController {
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .systemGroupedBackground
        
        // Register cells
        collectionView.register(AtBatOptionCell.self, forCellWithReuseIdentifier: AtBatOptionCell.identifier)
        collectionView.register(InteractiveDiamondCell.self, forCellWithReuseIdentifier: InteractiveDiamondCell.identifier)
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.identifier)
        collectionView.register(SectionFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: SectionFooterView.identifier)
        
        return collectionView
    }()
    
    // Section-based organization of at-bat options
    private let rbiOptions: [AtBatOption] = {
        return [AtBatOption(option: .rbi)]
    }()
    
    private let onBaseOptions: [AtBatOption] = {
        return [
            AtBatOption(option: .single),
            AtBatOption(option: .double),
            AtBatOption(option: .triple),
            AtBatOption(option: .homeRun),
            AtBatOption(option: .walk)
        ]
    }()
    
    private let outOptions: [AtBatOption] = {
        return [
            AtBatOption(option: .outAtFirst),
            AtBatOption(option: .flyOut),
            AtBatOption(option: .strikeout),
            AtBatOption(option: .foulBall)
        ]
    }()
    
    // All options for easy access when needed
    private lazy var allAtBatOptions: [AtBatOption] = {
        return rbiOptions + onBaseOptions + outOptions
    }()
    
    private let statService = StatService.shared
    private var currentGame: Game?
    private var currentPlayer: Player?
    private var currentInning: Int = 1
    private var selectedOptionIndex: Int?
    private var selectedRBICount: Int?
    private var hitLocation: HitLocation?
    
    // Completion handler to notify parent when at-bat is saved
    var onAtBatSaved: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    func configure(game: Game, player: Player, inning: Int = 1) {
        self.currentGame = game
        self.currentPlayer = player
        self.currentInning = inning
        updateTitle()
    }
    
    private func updateTitle() {
        if let player = currentPlayer {
            title = "\(player.name) At Bat"
        } else {
            title = "Record At-Bat"
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
        title = "Record At-Bat"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )
        
        // Initially disable save until user makes selections
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, environment in
            switch sectionIndex {
            case 0: // RBI section (with footer)
                return self.createAtBatOptionsSectionWithFooter(environment: environment)
            case 1, 2: // On Base and Out sections
                return self.createAtBatOptionsSection(environment: environment)
            case 3: // Interactive Diamond section
                return self.createInteractiveDiamondSection(environment: environment)
            default:
                return self.createAtBatOptionsSection(environment: environment)
            }
        })
    }
    
    private func createAtBatOptionsSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
        // Add section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    private func createAtBatOptionsSectionWithFooter(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 12, trailing: 14)
        
        // Add section header and footer
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        
        let footerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(32))
        let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: footerSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)
        
        section.boundarySupplementaryItems = [header, footer]
        
        return section
    }
    
    private func createInteractiveDiamondSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
        // Add section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    private func getGlobalIndex(for indexPath: IndexPath) -> Int {
        switch indexPath.section {
        case 0: // RBI section
            return indexPath.item
        case 1: // On Base section
            return rbiOptions.count + indexPath.item
        case 2: // Out section
            return rbiOptions.count + onBaseOptions.count + indexPath.item
        default:
            return 0
        }
    }
    
    private func updateSaveButtonState() {
        guard let selectedIndex = selectedOptionIndex else {
            navigationItem.rightBarButtonItem?.isEnabled = false
            return
        }
        
        let selectedOption = allAtBatOptions[selectedIndex]
        let hasRBICountIfNeeded = !selectedOption.showRBIButton || selectedRBICount != nil
        
        navigationItem.rightBarButtonItem?.isEnabled = hasRBICountIfNeeded
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        guard let selectedIndex = selectedOptionIndex,
              let game = currentGame,
              let player = currentPlayer else {
            return
        }
        
        let selectedOption = allAtBatOptions[selectedIndex]
        
        // For home runs, automatically add 1 RBI for the batter, plus any RBIs from the RBI section
        var finalRBICount = selectedRBICount ?? 0
        if selectedOption.type == .homeRun {
            finalRBICount = 1 + finalRBICount // Home run is 1 RBI for batter + any additional RBIs
        }
        
        // If RBIs were recorded, present SelectRBIViewController first
        if finalRBICount > 0 {
            // For home runs, only select the additional runners, not the batter
            let runnersToSelect = selectedOption.type == .homeRun ? (selectedRBICount ?? 0) : finalRBICount
            
            if runnersToSelect > 0 {
                presentSelectRBIViewController(game: game, rbiCount: runnersToSelect) { [weak self] in
                    // After runs are recorded, record the at-bat
                    self?.recordAtBat(game: game, player: player, selectedOption: selectedOption, finalRBICount: finalRBICount)
                }
            } else {
                // No additional runners for home run, record the at-bat directly
                recordAtBat(game: game, player: player, selectedOption: selectedOption, finalRBICount: finalRBICount)
            }
        } else {
            // No RBIs, record the at-bat directly
            recordAtBat(game: game, player: player, selectedOption: selectedOption, finalRBICount: finalRBICount)
        }
    }
    
    private func presentSelectRBIViewController(game: Game, rbiCount: Int, completion: @escaping () -> Void) {
        let selectRBIVC = SelectRBIViewController()
        selectRBIVC.configure(game: game, rbiCount: rbiCount, inning: currentInning)
        
        // Set completion handler to record the at-bat after runs are recorded
        selectRBIVC.onRunsRecorded = completion
        
        let navController = UINavigationController(rootViewController: selectRBIVC)
        
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(navController, animated: true)
    }
    
    private func recordAtBat(game: Game, player: Player, selectedOption: AtBatOption, finalRBICount: Int) {
        Task {
            do {
                // Calculate next at-bat number for this player in this game
                let existingStats = try await statService.fetchPlayerGameStats(gameId: game.id, playerId: player.id)
                
                // Count only actual at-bats (stats that already have an at-bat number or represent at-bats)
                let existingAtBats = existingStats.filter { stat in
                    // Count stats that either have an at-bat number OR represent actual at-bats
                    stat.atBatNumber != nil || isAtBatStat(stat.type)
                }
                
                let nextAtBatNumber = existingAtBats.count + 1
                
                print("📈 Recording at-bat #\(nextAtBatNumber) for \(player.name) (found \(existingAtBats.count) existing at-bats out of \(existingStats.count) total stats)")
                
                _ = try await statService.recordAtBat(
                    gameId: game.id,
                    playerId: player.id,
                    type: convertToStatType(selectedOption.type),
                    outcome: selectedOption.title,
                    runsBattedIn: finalRBICount,
                    inning: currentInning,
                    atBatNumber: nextAtBatNumber, // Include the at-bat number
                    hitLocation: hitLocation
                )
                
                await MainActor.run {
                    // Call completion handler to notify parent
                    onAtBatSaved?()
                    
                    // Dismiss the view controller
                    dismiss(animated: true)
                }
            } catch {
                await MainActor.run {
                    print("Error recording at-bat: \(error)")
                    showAlert(title: "Error", message: "Failed to record at-bat: \(error.localizedDescription)")
                }
            }
        }
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
    
    private func convertToStatType(_ optionType: AtBatOption.AtBatOptionType) -> StatType {
        switch optionType {
        case .outAtFirst:
            return .atBat
        case .single:
            return .single
        case .double:
            return .double
        case .triple:
            return .triple
        case .foulBall:
            return .atBat
        case .homeRun:
            return .homeRun
        case .rbi:
            return .rbi
        case .flyOut:
            return .flyOut
        case .strikeout:
            return .strikeOut
        case .walk:
            return .walk
        }
    }
    
    private func formatOutcome(_ optionType: AtBatOption.AtBatOptionType) -> String {
        switch optionType {
        case .outAtFirst:
            return "Out at First"
        case .single:
            return "Single"
        case .double:
            return "Double"
        case .triple:
            return "Triple"
        case .foulBall:
            return "Foul Ball"
        case .homeRun:
            return "Home Run"
        case .rbi:
            return "RBI"
        case .flyOut:
            return "Fly Out"
        case .strikeout:
            return "Strikeout"
        case .walk:
            return "Walk"
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension RecordAtBatViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 5 // RBI, On Base, Out, Interactive Diamond, empty section for spacing
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0: // RBI section
            return rbiOptions.count
        case 1: // On Base section
            return onBaseOptions.count
        case 2: // Out section
            return outOptions.count
        case 3: // Interactive diamond section
            return 1
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0: // RBI section
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AtBatOptionCell.identifier, for: indexPath) as! AtBatOptionCell
            let option = rbiOptions[indexPath.item]
            let globalIndex = getGlobalIndex(for: indexPath)
            let isSelected = selectedOptionIndex == globalIndex
            cell.configure(with: option, isSelected: isSelected)
            
            // Handle RBI selection
            cell.onRBISelection = { [weak self] rbiCount in
                self?.selectedRBICount = rbiCount
                self?.updateSaveButtonState()
            }
            
            return cell
            
        case 1: // On Base section
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AtBatOptionCell.identifier, for: indexPath) as! AtBatOptionCell
            let option = onBaseOptions[indexPath.item]
            let globalIndex = getGlobalIndex(for: indexPath)
            let isSelected = selectedOptionIndex == globalIndex
            cell.configure(with: option, isSelected: isSelected)
            
            return cell
            
        case 2: // Out section
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AtBatOptionCell.identifier, for: indexPath) as! AtBatOptionCell
            let option = outOptions[indexPath.item]
            let globalIndex = getGlobalIndex(for: indexPath)
            let isSelected = selectedOptionIndex == globalIndex
            cell.configure(with: option, isSelected: isSelected)
            
            return cell
            
        case 3: // Interactive diamond section
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InteractiveDiamondCell.identifier, for: indexPath) as! InteractiveDiamondCell
            cell.configure()
            
            // Handle hit recording - coordinates are already normalized and grid-snapped
            cell.onHitRecorded = { [weak self] location, height in
                guard let self = self else { return }
                
                print("🎯 Recording hit: already-normalized(\(location.x), \(location.y)) height=\(height)")
                
                // The InteractiveDiamondView already provides normalized, grid-snapped coordinates
                // No further processing needed!
                self.hitLocation = HitLocation(
                    normalizedPoint: location, // Use coordinates directly
                    height: Double(height),
                    gridResolution: DiamondGrid.gridSize
                )
                
                print("✅ Hit location created: normalized(\(location.x), \(location.y)) height=\(height) gridRes=\(DiamondGrid.gridSize)")
            }
            
            return cell
            
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
            
            switch indexPath.section {
            case 0:
                header.configure(title: "LOG RBI")
            case 1:
                header.configure(title: "ON BASE")
            case 2:
                header.configure(title: "OUT")
            case 3:
                header.configure(title: "LOG HIT")
            default:
                header.configure(title: "")
            }
            
            return header
        } else if kind == UICollectionView.elementKindSectionFooter {
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionFooterView.identifier, for: indexPath) as! SectionFooterView
            
            switch indexPath.section {
            case 0: // RBI section footer
                footer.configure(title: "HRs = 1 RBI automatically. Add RBIs for any runners on base.")
            default:
                footer.configure(title: "")
            }
            
            return footer
        }
        return UICollectionReusableView()
    }
}

// MARK: - UICollectionViewDelegate

extension RecordAtBatViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0, 1, 2: // RBI, On Base, Out sections
            let selectedOption: AtBatOption
            switch indexPath.section {
            case 0:
                selectedOption = rbiOptions[indexPath.item]
            case 1:
                selectedOption = onBaseOptions[indexPath.item]
            case 2:
                selectedOption = outOptions[indexPath.item]
            default:
                return
            }
            
            // Don't allow selecting the RBI cell directly - only the button
            if selectedOption.type == .rbi {
                return
            }
            
            // Select at-bat option
            selectedOptionIndex = getGlobalIndex(for: indexPath)
            
            // Reset RBI count if not RBI option
            if !selectedOption.showRBIButton {
                selectedRBICount = nil
            }
            
            updateSaveButtonState()
            
            // Update checkmarks without animation - reload all at-bat sections
            UIView.performWithoutAnimation {
                collectionView.reloadSections(IndexSet([0, 1, 2]))
            }
            
            print("Selected: \(selectedOption.title)")
            
        case 3:
            // Interactive diamond tapped - no action needed, handled by the cell
            break
            
        default:
            break
        }
    }
}
