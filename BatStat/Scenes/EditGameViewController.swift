import UIKit

protocol EditGameViewControllerProtocol: AnyObject {
    func gameDeleted()
}

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
        collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: "ActionButtonCell")
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
    private var homeScore: Int = 0
    private var opponentScore: Int = 0
    private var allPlayers: [Player] = []
    private var rosterPlayers: [Player] = []
    private var availablePlayers: [Player] = []
    private var isNewGame: Bool = true
    private let maxRosterSize = 10
    
    weak var delegate: EditGameViewControllerProtocol?
    
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
    
    private var isGameComplete: Bool {
        return currentGame?.isComplete ?? false
    }
    
    private func loadData() {
        loadPlayers()
        
        if let game = currentGame {
            // Editing existing game
            teamName = game.opponent
            gameDate = game.date
            homeScore = game.homeScore ?? 0
            opponentScore = game.opponentScore ?? 0
            loadGameRoster(gameId: game.id)
        } else {
            // Creating new game - start with empty roster
            teamName = ""
            gameDate = Date()
            homeScore = 0
            opponentScore = 0
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
        if isGameComplete {
            title = "Game Complete"
            title = "Game Complete"
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(cancelTapped)
            )
            navigationItem.rightBarButtonItem = nil
        } else {
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
            case 3:
                return self.createDeleteSection(environment: environment)
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
            // Disable swipe actions if game is complete
            guard !(self?.isGameComplete ?? true) else {
                return nil
            }
            
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
    
    private func createDeleteSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        let section = NSCollectionLayoutSection.list(using: configuration, layoutEnvironment: environment)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
        
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
                    // Notify the presenting view controller to reload
                    NotificationCenter.default.post(name: NSNotification.Name("GameCreated"), object: nil)
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
        guard let gameId = currentGame?.id else { return }
        
        Task {
            do {
                Logger.info("Updating existing game: \(teamName)", category: .games)
                
                // Update basic game info
                var updatedGame = currentGame!
                updatedGame.opponent = teamName
                updatedGame.date = gameDate
                updatedGame.homeScore = homeScore
                updatedGame.opponentScore = opponentScore
                
                let result = try await gameService.updateGame(updatedGame)
                
                await MainActor.run {
                    Logger.info("Successfully updated game", category: .games)
                    self.dismiss(animated: true)
                }
            } catch {
                await MainActor.run {
                    Logger.error("Failed to update game: \(error.localizedDescription)", category: .games)
                    self.showAlert(title: "Error", message: "Failed to update game: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func markGameAsComplete() {
        guard let gameId = currentGame?.id else { return }
        
        Task {
            do {
                Logger.info("Marking game as complete with scores - Home: \(homeScore), Opponent: \(opponentScore)", category: .games)
                
                // Update scores first
                let gameWithScores = try await gameService.updateGameScore(gameId: gameId, homeScore: homeScore, opponentScore: opponentScore)
                
                // Then mark as complete
                let completedGame = try await gameService.markGameAsFinished(gameId: gameId)
                
                await MainActor.run {
                    self.currentGame = completedGame
                    Logger.info("Successfully marked game as complete", category: .games)
                    self.setupNavigationBar() // Update navigation bar
                    self.collectionView.reloadData() // Refresh UI
                }
            } catch {
                await MainActor.run {
                    Logger.error("Failed to mark game as complete: \(error.localizedDescription)", category: .games)
                    self.showAlert(title: "Error", message: "Failed to mark game as complete: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func confirmDeleteGame() {
        guard let game = currentGame else { return }
        
        let alert = UIAlertController(
            title: "Delete Game",
            message: "Are you sure you want to delete this game against \(game.opponent)? This will permanently delete the game and all associated stats. This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.deleteGame()
        })
        
        present(alert, animated: true)
    }
    
    private func deleteGame() {
        guard let gameId = currentGame?.id else { return }
        
        Task {
            do {
                Logger.info("Deleting game: \(currentGame?.opponent ?? "Unknown")", category: .games)
                
                try await gameService.deleteGame(id: gameId)
                
                await MainActor.run {
                    Logger.info("Successfully deleted game", category: .games)
                    // Notify the presenting view controller to reload
                    NotificationCenter.default.post(name: NSNotification.Name("GameDeleted"), object: nil)
                    self.dismiss(animated: true) {
                        self.delegate?.gameDeleted()
                    }
                }
            } catch {
                await MainActor.run {
                    Logger.error("Failed to delete game: \(error.localizedDescription)", category: .games)
                    self.showAlert(title: "Error", message: "Failed to delete game: \(error.localizedDescription)")
                }
            }
        }
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
        return isNewGame ? 3 : 4 // Add delete section for existing games
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            if isNewGame {
                return 2 // Team name and date picker for new games
            } else if isGameComplete {
                return 4 // Team name, date, home score, opponent score (read-only)
            } else {
                return 5 // Team name, date, home score, opponent score, complete button
            }
        case 1:
            return rosterPlayers.count // Roster section (limited to 10)
        case 2:
            return availablePlayers.count // Player bank section
        case 3:
            return isNewGame ? 0 : 1 // Delete button section (only for existing games)
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            switch indexPath.item {
            case 0:
                // Team name text field
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TextFieldCell.identifier, for: indexPath) as! TextFieldCell
                cell.configure(placeholder: "Team Name", text: teamName)
                if !isGameComplete {
                    cell.onTextChanged = { [weak self] text in
                        self?.teamName = text
                    }
                }
                return cell
            case 1:
                // Date picker
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DatePickerCell.identifier, for: indexPath) as! DatePickerCell
                cell.configure(date: gameDate)
                if !isGameComplete {
                    cell.onDateChanged = { [weak self] date in
                        self?.gameDate = date
                    }
                }
                return cell
            case 2:
                // Home score (only shown for existing games)
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TextFieldCell.identifier, for: indexPath) as! TextFieldCell
                cell.configure(placeholder: "Home Score", text: "\(homeScore)")
                if !isGameComplete {
                    cell.onTextChanged = { [weak self] text in
                        self?.homeScore = Int(text) ?? 0
                    }
                }
                return cell
            case 3:
                // Opponent score (only shown for existing games)
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TextFieldCell.identifier, for: indexPath) as! TextFieldCell
                cell.configure(placeholder: "Opponent Score", text: "\(opponentScore)")
                if !isGameComplete {
                    cell.onTextChanged = { [weak self] text in
                        self?.opponentScore = Int(text) ?? 0
                    }
                }
                return cell
            case 4:
                // Complete game button (only shown for incomplete games)
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ActionButtonCell", for: indexPath) as! UICollectionViewListCell
                var content = cell.defaultContentConfiguration()
                content.text = "Mark Game Complete"
                content.textProperties.color = .systemBlue
                content.textProperties.alignment = .center
                cell.contentConfiguration = content
                return cell
            default:
                return UICollectionViewCell()
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
            
        case 3:
            // Delete game button (only for existing games)
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ActionButtonCell", for: indexPath) as! UICollectionViewListCell
            var content = cell.defaultContentConfiguration()
            content.text = "Delete Game"
            content.textProperties.color = .systemRed
            content.textProperties.alignment = .center
            content.image = UIImage(systemName: "trash")
            content.imageProperties.tintColor = .systemRed
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
        
        // Handle complete game button tap
        if indexPath.section == 0 && indexPath.item == 4 && !isGameComplete {
            markGameAsComplete()
            return
        }
        
        // Handle delete game button tap
        if indexPath.section == 3 && indexPath.item == 0 && !isNewGame {
            confirmDeleteGame()
            return
        }
        
        // Prevent editing if game is complete
        guard !isGameComplete else { return }
        
        if indexPath.section == 2 {
            // Player bank section - add player to roster when tapped
            addPlayerToRosterFromBank(at: indexPath.item)
        }
    }
}

// MARK: - UICollectionViewDragDelegate

extension EditGameViewController: UICollectionViewDragDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        // Prevent drag and drop if game is complete
        guard !isGameComplete else { return [] }
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
        // Prevent drop if game is complete
        guard !isGameComplete else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
        
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
