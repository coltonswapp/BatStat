//
//  GameDetailViewController.swift
//  BatStat
//
//  Created by Colton Swapp on 5/5/25.
//

import UIKit
import CoreData

struct Player: Hashable, Identifiable {
    let id = UUID()
    let firstName: String
    let lastName: String
    let number: Int
}

// MARK: - SectionHeaderView
class SectionHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "SectionHeaderView"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .regular)
        label.textColor = .tertiaryLabel
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    func configure(title: String) {
        titleLabel.text = title.uppercased()
    }
}

final class GameDetailViewController: UIViewController {
    
    enum Section: Int, CaseIterable {
        case opponent
        case lineup
    }
    
    enum Mode {
        case create
        case view
        case edit
    }
    
    // Define a custom identifier type that can include either String or Player
    enum GameItemIdentifier: Hashable {
        case opponent(String)
        case player(Player)
    }
    
    // Update DataSource and Snapshot typealias to use our new identifier type
    typealias DataSource = UICollectionViewDiffableDataSource<Section, GameItemIdentifier>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, GameItemIdentifier>
    
    private var collectionView: UICollectionView!
    private var dataSource: DataSource!
    private var players: [Player] = []
    
    // Add a property for the opponent name
    private var opponentName: String = ""
    
    // Reference to the game manager
    private let gameManager = GameManager.shared
    
    // Properties for existing game
    private var existingGame: GameEntity?
    private var currentMode: Mode = .create
    
    // Completion handler to be called when the view controller is dismissed
    var onDismiss: (() -> Void)?
    
    // MARK: - Initialization
    
    convenience init(game: GameEntity? = nil) {
        self.init()
        self.existingGame = game
        self.currentMode = game == nil ? .create : .view
    }
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupCollectionView()
        configureDataSource()
        loadData()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        
        if currentMode == .create {
            title = "New Game"
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Save",
                style: .done,
                target: self,
                action: #selector(saveGame)
            )
        } else {
            title = existingGame?.opponentName ?? "Game Details"
            
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Edit",
                style: .plain,
                target: self,
                action: #selector(toggleEditMode)
            )
        }
    }
    
    // MARK: - Data Loading
    
    private func loadData() {
        if let game = existingGame {
            // Load existing game data
            opponentName = game.opponentName ?? "Unknown Opponent"
            players = gameManager.getPlayersForGame(game)
        } else {
            // Load default players for a new game
            players = [
                Player(firstName: "John", lastName: "Smith", number: 10),
                Player(firstName: "Mike", lastName: "Johnson", number: 22),
                Player(firstName: "David", lastName: "Brown", number: 5),
                Player(firstName: "Chris", lastName: "Wilson", number: 18),
                Player(firstName: "James", lastName: "Davis", number: 7),
                Player(firstName: "Robert", lastName: "Miller", number: 33),
                Player(firstName: "Daniel", lastName: "Thomas", number: 42),
                Player(firstName: "Kevin", lastName: "Anderson", number: 9),
                Player(firstName: "Brian", lastName: "Taylor", number: 15),
                Player(firstName: "Mark", lastName: "White", number: 24)
            ]
        }
        
        applySnapshot()
    }
    
    // MARK: - Collection View Setup
    
    private func setupCollectionView() {
        let layout = createLayout()
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.delegate = self
        
        // Enable drag and drop for reordering
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.dragInteractionEnabled = true
        
        view.addSubview(collectionView)
        
        // Register cell types
        collectionView.register(InfoCell.self, forCellWithReuseIdentifier: "InfoCell")
        collectionView.register(PlayerLineupCell.self, forCellWithReuseIdentifier: "PlayerLineupCell")
        
        // Register header
        collectionView.register(
            SectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SectionHeaderView.reuseIdentifier
        )
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { [weak self] sectionIndex, layoutEnvironment in
            guard let section = Section(rawValue: sectionIndex) else { 
                fatalError("Unknown section") 
            }
            
            switch section {
            case .opponent:
                return self?.createOpponentSection(layoutEnvironment: layoutEnvironment)
            case .lineup:
                return self?.createLineupSection(layoutEnvironment: layoutEnvironment)
            }
        }
        
        return layout
    }
    
    private func createOpponentSection(layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.headerMode = .supplementary
        config.showsSeparators = true
        
        // Reduce spacing between header and first item
        let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(44)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        header.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    private func createLineupSection(layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        var config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        config.headerMode = .supplementary
        config.showsSeparators = true
        
        // Reduce spacing between header and first item
        let section = NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
        
        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(44)
        )
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: headerSize,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
        header.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    // MARK: - Data Source Configuration
    
    private func configureDataSource() {
        // Create data source
        dataSource = UICollectionViewDiffableDataSource<Section, GameItemIdentifier>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, identifier in
            guard let self = self, let section = Section(rawValue: indexPath.section) else {
                return nil
            }
            
            switch section {
            case .opponent:
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "InfoCell",
                    for: indexPath
                ) as! InfoCell
                
                cell.configure(
                    title: "Opponent Name",
                    detail: self.opponentName,
                    placeholder: "Team Name"
                )
                
                // Disable editing in view mode
                cell.setEditable(self.currentMode != .view)
                
                return cell
                
            case .lineup:
                guard case .player(let player) = identifier else { return nil }
                
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "PlayerLineupCell",
                    for: indexPath
                ) as! PlayerLineupCell
                
                cell.configure(with: player)
                // Only show reorder controls in edit mode
                cell.showReorderControl(self.currentMode == .edit || self.currentMode == .create)
                
                return cell
            }
        }
        
        // Enable reordering only in edit or create mode
        dataSource.reorderingHandlers.canReorderItem = { [weak self] identifier in
            guard let self = self else { return false }
            if case .player = identifier, (self.currentMode == .edit || self.currentMode == .create) {
                return true
            }
            return false
        }
        
        dataSource.reorderingHandlers.didReorder = { [weak self] transaction in
            guard let self = self else { return }
            
            // Update the players array to match the new order
            let playerIdentifiers = transaction.finalSnapshot.itemIdentifiers(inSection: .lineup)
            let newPlayers = playerIdentifiers.compactMap { identifier -> Player? in
                if case .player(let player) = identifier {
                    return player
                }
                return nil
            }
            
            if !newPlayers.isEmpty {
                self.players = newPlayers
            }
        }
        
        // Configure header provider
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            if kind == UICollectionView.elementKindSectionHeader {
                let header = collectionView.dequeueReusableSupplementaryView(
                    ofKind: kind,
                    withReuseIdentifier: SectionHeaderView.reuseIdentifier,
                    for: indexPath
                ) as! SectionHeaderView
                
                if let section = Section(rawValue: indexPath.section) {
                    switch section {
                    case .opponent:
                        header.configure(title: "Opponent Info")
                    case .lineup:
                        header.configure(title: "Batting Lineup")
                    }
                }
                
                return header
            }
            
            return nil
        }
    }
    
    private func applySnapshot() {
        var snapshot = Snapshot()
        snapshot.appendSections([.opponent, .lineup])
        
        // Add opponent section item
        snapshot.appendItems([.opponent("opponent")], toSection: .opponent)
        
        // Add lineup section items - convert Player objects to identifiers
        let playerIdentifiers = players.map { GameItemIdentifier.player($0) }
        snapshot.appendItems(playerIdentifiers, toSection: .lineup)
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    // MARK: - Actions
    
    @objc private func toggleEditMode() {
        if currentMode == .view {
            // Switch to edit mode
            currentMode = .edit
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Save",
                style: .done,
                target: self,
                action: #selector(saveGame)
            )
            
            // Enable drag & drop
            collectionView.dragInteractionEnabled = true
        } else {
            // Switch to view mode
            currentMode = .view
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Edit",
                style: .plain,
                target: self,
                action: #selector(toggleEditMode)
            )
            
            // Disable drag & drop
            collectionView.dragInteractionEnabled = false
        }
        
        // Update cell appearance for edit mode
        applySnapshot()
    }
    
    @objc private func saveGame() {
        // Get the opponent name from the cell
        let indexPath = IndexPath(item: 0, section: Section.opponent.rawValue)
        if let cell = collectionView.cellForItem(at: indexPath) as? InfoCell {
            opponentName = cell.getTextFieldText() ?? "Unknown Opponent"
        }
        
        if let existingGame = existingGame {
            // Update existing game
            existingGame.opponentName = opponentName
            
            // Use the updated lineup handling method to prevent duplication
            gameManager.updateGameLineup(game: existingGame, players: players)
            
            // Post notification that game data has changed
            NotificationCenter.default.post(name: NSNotification.Name("GameDataChanged"), object: nil)
            
            // Switch back to view mode
            currentMode = .view
            setupUI()
            
            // Apply updated UI changes
            applySnapshot()
        } else {
            // Create a new game
            let _ = gameManager.createGame(opponentName: opponentName, players: players)
            
            // Post notification that game data has changed
            NotificationCenter.default.post(name: NSNotification.Name("GameDataChanged"), object: nil)
            
            // Dismiss the view controller
            dismiss(animated: true) { [weak self] in
                // Call the dismissal handler if it exists
                self?.onDismiss?()
            }
        }
    }
    
    // Override dismiss method to ensure onDismiss is called
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag) { [weak self] in
            completion?()
            self?.onDismiss?()
        }
    }
}

// MARK: - UICollectionViewDelegate
extension GameDetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, targetIndexPathForMoveFromItemAt originalIndexPath: IndexPath, toProposedIndexPath proposedIndexPath: IndexPath) -> IndexPath {
        // Only allow reordering within the lineup section
        if originalIndexPath.section == Section.lineup.rawValue && proposedIndexPath.section == Section.lineup.rawValue {
            return proposedIndexPath
        }
        return originalIndexPath
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return false
    }
}

// MARK: - Drag and Drop for Reordering
extension GameDetailViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        // Only allow dragging in edit/create mode and in the lineup section
        guard (currentMode == .edit || currentMode == .create),
              indexPath.section == Section.lineup.rawValue,
              let identifier = dataSource.itemIdentifier(for: indexPath),
              case .player = identifier else {
            return []
        }
        
        let itemProvider = NSItemProvider()
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = identifier
        
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        // Only allow dropping in the lineup section
        if let indexPath = destinationIndexPath, indexPath.section == Section.lineup.rawValue {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        
        return UICollectionViewDropProposal(operation: .forbidden)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath,
              destinationIndexPath.section == Section.lineup.rawValue else {
            return
        }
        
        // Handle the reordering
        coordinator.items.forEach { dropItem in
            guard let sourceIndexPath = dropItem.sourceIndexPath,
                  sourceIndexPath.section == Section.lineup.rawValue,
                  let identifier = dropItem.dragItem.localObject as? GameItemIdentifier else {
                return
            }
            
            // Update the data source
            var snapshot = self.dataSource.snapshot()
            
            if sourceIndexPath.row < destinationIndexPath.row {
                // Moving down
                snapshot.deleteItems([identifier])
                if destinationIndexPath.row <= snapshot.itemIdentifiers(inSection: .lineup).count {
                    let afterIndex = min(destinationIndexPath.row - 1, snapshot.itemIdentifiers(inSection: .lineup).count - 1)
                    let afterItem = snapshot.itemIdentifiers(inSection: .lineup)[afterIndex]
                    snapshot.insertItems([identifier], afterItem: afterItem)
                } else {
                    snapshot.appendItems([identifier], toSection: .lineup)
                }
            } else {
                // Moving up
                snapshot.deleteItems([identifier])
                if destinationIndexPath.row < snapshot.itemIdentifiers(inSection: .lineup).count {
                    let playerAtDestination = snapshot.itemIdentifiers(inSection: .lineup)[destinationIndexPath.row]
                    snapshot.insertItems([identifier], beforeItem: playerAtDestination)
                } else {
                    snapshot.appendItems([identifier], toSection: .lineup)
                }
            }
            
            dataSource.apply(snapshot, animatingDifferences: true)
            
            // Update the players array based on the new order
            let playerIdentifiers = snapshot.itemIdentifiers(inSection: .lineup)
            let newPlayers = playerIdentifiers.compactMap { identifier -> Player? in
                if case .player(let player) = identifier {
                    return player
                }
                return nil
            }
            
            if !newPlayers.isEmpty {
                self.players = newPlayers
            }
            
            // Notify the coordinator that the drop is complete
            coordinator.drop(dropItem.dragItem, toItemAt: destinationIndexPath)
        }
    }
}

// MARK: - InfoCell
class InfoCell: UICollectionViewListCell {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = .secondaryLabel
        label.textAlignment = .left
        return label
    }()
    
    private let detailTextField: UITextField = {
        let textField = UITextField()
        textField.font = .systemFont(ofSize: 16, weight: .regular)
        textField.textColor = .label
        textField.placeholder = "Enter name"
        return textField
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, detailTextField])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .leading
        stack.distribution = .equalSpacing
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor, constant: -8),
            detailTextField.widthAnchor.constraint(equalTo: stackView.widthAnchor)
        ])
    }
    
    func configure(title: String, detail: String?, placeholder: String) {
        titleLabel.text = title.uppercased()
        if let detail, !detail.isEmpty {
            detailTextField.text = detail
        }
        detailTextField.placeholder = placeholder
    }
    
    func getTextFieldText() -> String? {
        return detailTextField.text
    }
    
    func setEditable(_ isEditable: Bool) {
        detailTextField.isEnabled = isEditable
        detailTextField.textColor = isEditable ? .label : .secondaryLabel
    }
}

// MARK: - PlayerLineupCell
class PlayerLineupCell: UICollectionViewListCell {
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let numberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()
    
    private let reorderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "line.3.horizontal")
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray3
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        return imageView
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [nameLabel, numberLabel, reorderImageView])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(with player: Player) {
        nameLabel.text = "\(player.firstName) \(player.lastName)"
        numberLabel.text = "#\(player.number)"
    }
    
    func showReorderControl(_ show: Bool) {
        reorderImageView.isHidden = !show
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        numberLabel.text = nil
    }
}

class ActionCell: UICollectionViewListCell {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17)
        return label
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray3
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.widthAnchor.constraint(equalToConstant: 20).isActive = true
        return imageView
    }()
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [titleLabel, iconImageView])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor, constant: -8)
        ])
    }
    
    func configure(title: String, imageName: String, destructive: Bool = false) {
        titleLabel.text = title
        titleLabel.textColor = destructive ? .systemRed : .label
        
        iconImageView.image = UIImage(systemName: imageName)
        iconImageView.tintColor = destructive ? .systemRed : .systemGray3
    }
}
