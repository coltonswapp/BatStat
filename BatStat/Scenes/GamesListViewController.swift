//
//  GamesListViewController.swift
//  BatStat
//
//  Created by Colton Swapp on 5/5/25.
//

import UIKit
import CoreData

class GamesListViewController: UIViewController {
    
    // Use GameEntity directly since it's the only identifier we need here
    typealias DataSource = UITableViewDiffableDataSource<Section, NSManagedObjectID>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, NSManagedObjectID>
    
    enum Section {
        case main
    }
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var dataSource: DataSource!
    private var games: [GameEntity] = []
    
    private let gameManager = GameManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "My Games"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        
        setupTableView()
        configureDataSource()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewGame)
        )
        
        // Register for notifications when a game is created or updated
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGameDataChanged),
            name: NSNotification.Name("GameDataChanged"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Refresh games list when view appears
        loadGames()
    }
    
    @objc private func handleGameDataChanged() {
        // Reload games when notification is received
        loadGames()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "GameCell")
        tableView.delegate = self
    }
    
    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<Section, NSManagedObjectID>(
            tableView: tableView
        ) { [weak self] tableView, indexPath, objectID in
            guard let self = self,
                  let context = self.games.first?.managedObjectContext,
                  let game = try? context.existingObject(with: objectID) as? GameEntity else {
                return UITableViewCell()
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "GameCell", for: indexPath)
            
            var content = cell.defaultContentConfiguration()
            content.text = game.opponentName
            
            if let date = game.date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                content.secondaryText = formatter.string(from: date)
            }
            
            cell.contentConfiguration = content
            cell.accessoryType = .disclosureIndicator
            
            return cell
        }
    }
    
    private func loadGames() {
        games = gameManager.fetchGames()
        applySnapshot()
    }
    
    private func applySnapshot() {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        
        // Use object IDs instead of the objects themselves
        let gameIDs = games.map { $0.objectID }
        snapshot.appendItems(gameIDs)
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    @objc private func addNewGame() {
        let gameDetailVC = GameDetailViewController()
        
        // Set up a completion handler to reload data
        gameDetailVC.onDismiss = { [weak self] in
            self?.loadGames()
        }
        
        let navController = UINavigationController(rootViewController: gameDetailVC)
        present(navController, animated: true)
    }
}

// MARK: - UITableViewDelegate
extension GamesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let objectID = dataSource.itemIdentifier(for: indexPath),
              let context = games.first?.managedObjectContext,
              let game = try? context.existingObject(with: objectID) as? GameEntity else {
            return
        }
        
        // Navigate to GameViewController instead of GameDetailViewController
        let gameVC = GameViewController(game: game)
        navigationController?.pushViewController(gameVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let objectID = dataSource.itemIdentifier(for: indexPath),
              let context = games.first?.managedObjectContext,
              let game = try? context.existingObject(with: objectID) as? GameEntity else {
            return nil
        }
        
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            self?.gameManager.deleteGame(game)
            self?.loadGames()
            completion(true)
        }
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
} 
