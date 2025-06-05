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
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.identifier)
        
        // Enable drag and drop for reordering
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.dragInteractionEnabled = true
        
        return collectionView
    }()
    
    private let mockDataManager = MockDataManager.shared
    private var currentGame: Game?
    private var teamName: String = ""
    private var gameDate: Date = Date()
    private var rosterPlayers: [Player] = []
    
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
        
        teamName = game.opponent
        gameDate = game.date
        rosterPlayers = mockDataManager.getPlayersInGame(gameId: game.id)
        
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
        title = "Edit Game"
        
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
        configuration.trailingSwipeActionsConfigurationProvider = nil
        configuration.leadingSwipeActionsConfigurationProvider = nil
        
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
        // TODO: Save the game changes
        print("Saving game changes:")
        print("- Team Name: \(teamName)")
        print("- Game Date: \(gameDate)")
        print("- Roster Count: \(rosterPlayers.count)")
        
        dismiss(animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension EditGameViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2 // Team name and date picker
        case 1:
            return rosterPlayers.count // Roster section
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            if indexPath.item == 0 {
                // Team name text field
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TextFieldCell.identifier, for: indexPath) as! TextFieldCell
                cell.configure(placeholder: "Team Name", text: teamName)
                cell.onTextChanged = { [weak self] text in
                    self?.teamName = text
                }
                return cell
            } else {
                // Date picker
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
            
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            switch indexPath.section {
            case 1:
                let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
                header.configure(title: "ROSTER")
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