import UIKit

class SelectRBIViewController: UIViewController {
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.allowsMultipleSelection = true
        
        // Register cells
        collectionView.register(PlayerSelectionCell.self, forCellWithReuseIdentifier: PlayerSelectionCell.identifier)
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.identifier)
        
        return collectionView
    }()
    
    private let playerService = PlayerService()
    private let statService = StatService.shared
    private var currentGame: Game?
    private var rosterPlayers: [Player] = []
    private var rbiCount: Int = 0
    private var currentInning: Int = 1
    private var selectedPlayerIds: Set<UUID> = []
    
    // Completion handler to notify parent when runs are recorded
    var onRunsRecorded: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    func configure(game: Game, rbiCount: Int, inning: Int = 1) {
        self.currentGame = game
        self.rbiCount = rbiCount
        self.currentInning = inning
        loadRosterPlayers()
        updateTitle()
    }
    
    private func updateTitle() {
        title = "Award RBIs (\(rbiCount))"
    }
    
    private func loadRosterPlayers() {
        guard let game = currentGame else { return }
        
        Task {
            do {
                let players = try await playerService.fetchPlayersInGame(gameId: game.id)
                await MainActor.run {
                    self.rosterPlayers = players
                    self.collectionView.reloadData()
                }
            } catch {
                await MainActor.run {
                    print("Error loading roster players: \(error)")
                    showAlert(title: "Error", message: "Failed to load roster players: \(error.localizedDescription)")
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
        
        // Initially disable save until correct number of players are selected
        updateSaveButtonState()
    }
    
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, environment in
            let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
            let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
            
            // Add section header
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
            section.boundarySupplementaryItems = [header]
            
            return section
        })
    }
    
    private func updateSaveButtonState() {
        navigationItem.rightBarButtonItem?.isEnabled = selectedPlayerIds.count == rbiCount
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        guard selectedPlayerIds.count == rbiCount,
              let game = currentGame else {
            return
        }
        
        Task {
            do {
                // Record a run stat for each selected player using recordAtBat method
                for playerId in selectedPlayerIds {
                    _ = try await statService.recordAtBat(
                        gameId: game.id,
                        playerId: playerId,
                        type: .run,
                        outcome: "Run",
                        runsBattedIn: nil,
                        inning: currentInning,
                        atBatNumber: nil, // Runs don't have at-bat numbers
                        hitLocation: nil
                    )
                }
                
                await MainActor.run {
                    // Call completion handler to notify parent
                    onRunsRecorded?()
                    
                    // Dismiss the view controller
                    dismiss(animated: true)
                }
            } catch {
                await MainActor.run {
                    print("Error recording runs: \(error)")
                    showAlert(title: "Error", message: "Failed to record runs: \(error.localizedDescription)")
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

extension SelectRBIViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return rosterPlayers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlayerSelectionCell.identifier, for: indexPath) as! PlayerSelectionCell
        let player = rosterPlayers[indexPath.item]
        let isSelected = selectedPlayerIds.contains(player.id)
        cell.configure(with: player, isSelected: isSelected)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
            header.configure(title: "SELECT PLAYERS WHO SCORED (\(selectedPlayerIds.count)/\(rbiCount))")
            return header
        }
        return UICollectionReusableView()
    }
}

// MARK: - UICollectionViewDelegate

extension SelectRBIViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let player = rosterPlayers[indexPath.item]
        
        if selectedPlayerIds.contains(player.id) {
            // Deselect player
            selectedPlayerIds.remove(player.id)
        } else {
            // Select player only if we haven't reached the limit
            if selectedPlayerIds.count < rbiCount {
                selectedPlayerIds.insert(player.id)
            }
        }
        
        // Update the cell
        if let cell = collectionView.cellForItem(at: indexPath) as? PlayerSelectionCell {
            let isSelected = selectedPlayerIds.contains(player.id)
            cell.configure(with: player, isSelected: isSelected)
        }
        
        // Update save button state and header
        updateSaveButtonState()
        collectionView.reloadSections(IndexSet([0])) // Reload to update header
        
        // Deselect the cell to remove the highlight
        collectionView.deselectItem(at: indexPath, animated: true)
    }
} 
