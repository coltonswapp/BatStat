import UIKit

class EditGameViewController: UIViewController {
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .systemGroupedBackground
        
        // Register cells
        collectionView.register(TextFieldCell.self, forCellWithReuseIdentifier: TextFieldCell.identifier)
        collectionView.register(DatePickerCell.self, forCellWithReuseIdentifier: DatePickerCell.identifier)
        collectionView.register(PlayerRosterCell.self, forCellWithReuseIdentifier: PlayerRosterCell.identifier)
        collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: "PlayerBankCell")
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.identifier)
        
        // Enable drag and drop for reordering
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.dragInteractionEnabled = true
        
        return collectionView
    }()
    
    private let playerService = PlayerService()
    private let gameService = GameService.shared
    private var currentGame: Game?
    private var teamName: String = ""
    private var gameDate: Date = Date()
    private var allPlayers: [Player] = []
    private var rosterPlayers: [Player] = []
    private var availablePlayers: [Player] = []
    private var isNewGame: Bool = true
    private let maxRosterSize = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadData()
    }
    
    func configure(with game: Game) {
        self.currentGame = game
        self.isNewGame = false
        loadData()
    }
    
    private func loadData() {
        loadPlayers()
        
        if let game = currentGame {
            // Editing existing game
            teamName = game.opponent
            gameDate = game.date
            loadGameRoster(gameId: game.id)
        } else {
            // Creating new game - start with empty roster
            teamName = ""
            gameDate = Date()
            rosterPlayers = []
            updateAvailablePlayers()
        }
        
        collectionView.reloadData()
    }
    
    private func loadPlayers() {
        Task {
            do {
                Logger.debug("Starting to fetch players...", category: .games)
                let players = try await playerService.fetchAllPlayers()
                await MainActor.run {
                    self.allPlayers = players
                    self.updateAvailablePlayers()
                    self.collectionView.reloadData()
                    Logger.info("Loaded \(players.count) players for game editing", category: .games)
                }
            } catch {
                await MainActor.run {
                    Logger.error("Failed to load players: \(error.localizedDescription)", category: .games)
                    self.showAlert(title: "Error", message: "Failed to load players: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func loadGameRoster(gameId: UUID) {
        Task {
            do {
                let players = try await playerService.fetchPlayersInGame(gameId: gameId)
                await MainActor.run {
                    self.rosterPlayers = players
                    self.collectionView.reloadData()
                    Logger.info("Loaded \(players.count) players in game roster", category: .games)
                }
            } catch {
                await MainActor.run {
                    Logger.error("Failed to load game roster: \(error.localizedDescription)", category: .games)
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
        title = isNewGame ? "New Game" : "Edit Game"
        
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
    }
    
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, environment in
            switch sectionIndex {
            case 0:
                return self.createGameDetailsSection(environment: environment)
            case 1:
                return self.createRosterSection(environment: environment)
            case 2:
                return self.createPlayerBankSection(environment: environment)
            default:
                return self.createGameDetailsSection(environment: environment)
            }
        })
    }
    
    private func createGameDetailsSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
        
        return section
    }
    
    private func createRosterSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        var configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        configuration.trailingSwipeActionsConfigurationProvider = { [weak self] indexPath in
            let deleteAction = UIContextualAction(style: .destructive, title: "Remove") { _, _, completion in
                self?.removePlayerFromRoster(at: indexPath.item)
                completion(true)
            }
            deleteAction.image = UIImage(systemName: "minus.circle")
            return UISwipeActionsConfiguration(actions: [deleteAction])
        }
        
        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
        
        // Add section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    private func createPlayerBankSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
        
        // Add section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    @objc private func cancelTapped() {
        dismiss(animated: true)
    }
    
    @objc private func saveTapped() {
        guard !teamName.isEmpty else {
            showAlert(title: "Missing Information", message: "Please fill in opponent team name.")
            return
        }
        
        if isNewGame {
            createNewGame()
        } else {
            updateExistingGame()
        }
    }
    
    private func createNewGame() {
        Task {
            do {
                Logger.info("Creating new game: \(teamName)", category: .games)
                
                let newGame = try await gameService.createGame(
                    opponent: teamName,
                    location: "TBD", // Default location since it's not in the tech specs
                    date: gameDate
                )
                
                Logger.info("Game created successfully, now adding \(rosterPlayers.count) players to roster", category: .games)
                
                // Add players to game roster
                for (index, player) in rosterPlayers.enumerated() {
                    Logger.debug("Adding player \(index + 1)/\(rosterPlayers.count): \(player.name)", category: .games)
                    try await playerService.addPlayerToGame(
                        playerId: player.id,
                        gameId: newGame.id,
                        battingOrder: index + 1
                    )
                }
                
                await MainActor.run {
                    Logger.info("Successfully created game with \(self.rosterPlayers.count) players", category: .games)
                    self.dismiss(animated: true)
                }
            } catch {
                await MainActor.run {
                    Logger.error("Failed to create game: \(error.localizedDescription)", category: .games)
                    self.showAlert(title: "Error", message: "Failed to create game: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updateExistingGame() {
        // TODO: Implement game update functionality
        Logger.info("Updating existing game functionality not yet implemented", category: .games)
        dismiss(animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func removePlayerFromRoster(at index: Int) {
        guard index < rosterPlayers.count else { return }
        let removedPlayer = rosterPlayers.remove(at: index)
        updateAvailablePlayers()
        collectionView.reloadData()
        Logger.info("Removed player \(removedPlayer.name) from roster", category: .games)
    }
    
    private func addPlayerToRosterFromBank(at index: Int) {
        guard index < availablePlayers.count else { return }
        guard rosterPlayers.count < maxRosterSize else {
            showAlert(title: "Roster Full", message: "The roster is limited to \(maxRosterSize) players.")
            return
        }
        
        let player = availablePlayers[index]
        rosterPlayers.append(player)
        updateAvailablePlayers()
        collectionView.reloadData()
        Logger.info("Added player \(player.name) to roster", category: .games)
    }
    
    private func updateAvailablePlayers() {
        availablePlayers = allPlayers.filter { player in
            !rosterPlayers.contains { $0.id == player.id }
        }
        Logger.debug("Updated available players: \(availablePlayers.count) out of \(allPlayers.count) total", category: .games)
    }
}

// MARK: - UICollectionViewDataSource

extension EditGameViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2 // Team name and date picker (per tech specs)
        case 1:
            return rosterPlayers.count // Roster section (limited to 10)
        case 2:
            return availablePlayers.count // Player bank section
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            if indexPath.item == 0 {
                // Team name text field (as per tech specs)
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TextFieldCell.identifier, for: indexPath) as! TextFieldCell
                cell.configure(placeholder: "Team Name", text: teamName)
                cell.onTextChanged = { [weak self] text in
                    self?.teamName = text
                }
                return cell
            } else {
                // Date picker (defaulted to today as per tech specs)
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DatePickerCell.identifier, for: indexPath) as! DatePickerCell
                cell.configure(date: gameDate)
                cell.onDateChanged = { [weak self] date in
                    self?.gameDate = date
                }
                return cell
            }
            
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PlayerRosterCell.identifier, for: indexPath) as! PlayerRosterCell
            let player = rosterPlayers[indexPath.item]
            cell.configure(with: player)
            return cell
            
        case 2:
            // Player bank section - list of available players
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlayerBankCell", for: indexPath) as! UICollectionViewListCell
            let player = availablePlayers[indexPath.item]
            
            var content = cell.defaultContentConfiguration()
            content.text = player.name
            if let number = player.number {
                content.secondaryText = "#\(number)"
            }
            content.image = UIImage(systemName: "person.circle")
            content.imageProperties.tintColor = .systemGray2
            cell.contentConfiguration = content
            return cell
            
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            switch indexPath.section {
            case 1:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
                header.configure(title: "ROSTER (\(rosterPlayers.count)/\(maxRosterSize))")
                return header
            case 2:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
                header.configure(title: "PLAYER BANK")
                return header
            default:
                break
            }
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1 // Only allow reordering in roster section
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        guard sourceIndexPath.section == 1 && destinationIndexPath.section == 1 else { return }
        
        let movedPlayer = rosterPlayers.remove(at: sourceIndexPath.item)
        rosterPlayers.insert(movedPlayer, at: destinationIndexPath.item)
    }
}

// MARK: - UICollectionViewDelegate

extension EditGameViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        if indexPath.section == 2 {
            // Player bank section - add player to roster when tapped
            addPlayerToRosterFromBank(at: indexPath.item)
        }
    }
}

// MARK: - UICollectionViewDragDelegate

extension EditGameViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard indexPath.section == 1 else { return [] }
        
        let player = rosterPlayers[indexPath.item]
        let itemProvider = NSItemProvider(object: player.name as NSString)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = player
        return [dragItem]
    }
}

// MARK: - UICollectionViewDropDelegate

extension EditGameViewController: UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard let destinationIndexPath = destinationIndexPath,
              destinationIndexPath.section == 1,
              session.localDragSession != nil else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
        
        return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath,
              destinationIndexPath.section == 1 else { return }
        
        for item in coordinator.items {
            guard let sourceIndexPath = item.sourceIndexPath,
                  sourceIndexPath.section == 1 else { continue }
            
            collectionView.performBatchUpdates({
                let movedPlayer = rosterPlayers.remove(at: sourceIndexPath.item)
                rosterPlayers.insert(movedPlayer, at: destinationIndexPath.item)
                collectionView.moveItem(at: sourceIndexPath, to: destinationIndexPath)
            })
            
            coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
        }
    }
}