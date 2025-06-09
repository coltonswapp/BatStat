import UIKit

class PlayersListViewController: UIViewController {
    
    private let playerService = PlayerService()
    private var players: [Player] = []
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .systemGroupedBackground
        
        // Register cells
        collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: "PlayerCell")
        collectionView.register(UICollectionViewListCell.self, forCellWithReuseIdentifier: "AddPlayerCell")
        
        return collectionView
    }()
    
    enum PlayersSection: Int, CaseIterable {
        case addPlayer = 0
        case players = 1
        
        var title: String {
            switch self {
            case .addPlayer: return ""
            case .players: return "Players"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        loadPlayers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadPlayers()
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
        title = "Players"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addPlayerTapped)
        )
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }
    
    private func loadPlayers() {
        Task {
            do {
                let fetchedPlayers = try await playerService.fetchAllPlayers()
                await MainActor.run {
                    self.players = fetchedPlayers
                    self.collectionView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.showAlert(title: "Error", message: "Failed to load players: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc private func addPlayerTapped() {
        showAddPlayerAlert()
    }
    
    private func showAddPlayerAlert() {
        let alert = UIAlertController(title: "Add Player", message: "Enter player details", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Player Name"
        }
        
        alert.addTextField { textField in
            textField.placeholder = "Jersey Number"
            textField.keyboardType = .numberPad
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            guard let nameField = alert.textFields?[0],
                  let numberField = alert.textFields?[1],
                  let name = nameField.text, !name.isEmpty else {
                self.showAlert(title: "Error", message: "Please fill in required fields")
                return
            }
            
            let jerseyNumber = Int(numberField.text ?? "")
            self.createPlayer(name: name, number: jerseyNumber)
        })
        
        present(alert, animated: true)
    }
    
    private func createPlayer(name: String, number: Int?) {
        Task {
            do {
                let newPlayer = try await playerService.createPlayer(
                    name: name,
                    jerseyNumber: number
                )
                await MainActor.run {
                    self.players.append(newPlayer)
                    self.collectionView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.showAlert(title: "Error", message: "Failed to create player: \(error.localizedDescription)")
                }
                
                print(error.localizedDescription)
            }
        }
    }
    
    private func showEditPlayerAlert(for player: Player) {
        let alert = UIAlertController(title: "Edit Player", message: "Update player details", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.text = player.name
            textField.placeholder = "Player Name"
        }
        
        alert.addTextField { textField in
            if let number = player.number {
                textField.text = "\(number)"
            }
            textField.placeholder = "Jersey Number (optional)"
            textField.keyboardType = .numberPad
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { _ in
            guard let nameField = alert.textFields?[0],
                  let numberField = alert.textFields?[1],
                  let name = nameField.text, !name.isEmpty else {
                self.showAlert(title: "Error", message: "Please fill in required fields")
                return
            }
            
            let jerseyNumber = Int(numberField.text ?? "")
            self.updatePlayer(player, name: name, number: jerseyNumber)
        })
        
        present(alert, animated: true)
    }
    
    private func updatePlayer(_ player: Player, name: String, number: Int?) {
        Task {
            do {
                var updatedPlayer = player
                updatedPlayer.name = name
                updatedPlayer.number = number
                
                let savedPlayer = try await playerService.updatePlayer(updatedPlayer)
                await MainActor.run {
                    if let index = self.players.firstIndex(where: { $0.id == player.id }) {
                        self.players[index] = savedPlayer
                        self.collectionView.reloadData()
                    }
                }
            } catch {
                await MainActor.run {
                    self.showAlert(title: "Error", message: "Failed to update player: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func deletePlayer(_ player: Player) {
        let alert = UIAlertController(
            title: "Delete Player",
            message: "Are you sure you want to delete \(player.name)?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.performDeletePlayer(player)
        })
        
        present(alert, animated: true)
    }
    
    private func performDeletePlayer(_ player: Player) {
        Task {
            do {
                try await playerService.deletePlayer(id: player.id)
                await MainActor.run {
                    if let index = self.players.firstIndex(where: { $0.id == player.id }) {
                        self.players.remove(at: index)
                        self.collectionView.reloadData()
                    }
                }
            } catch {
                await MainActor.run {
                    self.showAlert(title: "Error", message: "Failed to delete player: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showPlayerSummary(for player: Player) {
        let playerSummaryVC = PlayerSummaryViewController()
        playerSummaryVC.configure(with: player)
        navigationController?.pushViewController(playerSummaryVC, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension PlayersListViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return PlayersSection.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let playersSection = PlayersSection(rawValue: section) else { return 0 }
        
        switch playersSection {
        case .addPlayer:
            return 1
        case .players:
            return players.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let playersSection = PlayersSection(rawValue: indexPath.section) else {
            return UICollectionViewCell()
        }
        
        switch playersSection {
        case .addPlayer:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddPlayerCell", for: indexPath) as! UICollectionViewListCell
            var content = cell.defaultContentConfiguration()
            content.text = "Add New Player"
            content.image = UIImage(systemName: "plus.circle.fill")
            content.imageProperties.tintColor = .systemBlue
            cell.contentConfiguration = content
            return cell
            
        case .players:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlayerCell", for: indexPath) as! UICollectionViewListCell
            let player = players[indexPath.item]
            
            var content = cell.defaultContentConfiguration()
            content.text = player.name
            
            var secondaryText: String = ""
            if let number = player.number {
                secondaryText = "#\(number)"
            }
            content.secondaryText = secondaryText
            
            cell.contentConfiguration = content
            cell.accessories = [.disclosureIndicator()]
            
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegate

extension PlayersListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        guard let playersSection = PlayersSection(rawValue: indexPath.section) else { return }
        
        switch playersSection {
        case .addPlayer:
            addPlayerTapped()
        case .players:
            let player = players[indexPath.item]
            showPlayerActions(for: player)
        }
    }
    
    private func showPlayerActions(for player: Player) {
        let actionSheet = UIAlertController(title: player.name, message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "View Stats", style: .default) { _ in
            self.showPlayerSummary(for: player)
        })
        
        actionSheet.addAction(UIAlertAction(title: "Edit", style: .default) { _ in
            self.showEditPlayerAlert(for: player)
        })
        
        actionSheet.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.deletePlayer(player)
        })
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        // For iPad support
        if let popover = actionSheet.popoverPresentationController {
            let cell = collectionView.cellForItem(at: IndexPath(item: players.firstIndex(where: { $0.id == player.id }) ?? 0, section: PlayersSection.players.rawValue))
            popover.sourceView = cell
            popover.sourceRect = cell?.bounds ?? CGRect.zero
        }
        
        present(actionSheet, animated: true)
    }
}
