//
//  ViewController.swift
//  BatStat
//
//  Created by Colton Swapp on 4/29/25.
//

import UIKit

class ViewController: UIViewController {
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .systemGroupedBackground
        
        // Register cells
        collectionView.register(ActionButtonCell.self, forCellWithReuseIdentifier: ActionButtonCell.identifier)
        collectionView.register(GameCell.self, forCellWithReuseIdentifier: GameCell.identifier)
        collectionView.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.identifier)
        
        return collectionView
    }()
    
    private let gameService = GameService.shared
    private var games: [Game] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupNavigationBar()
        loadGames()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadGames()
    }
    
    private func loadGames() {
        Task {
            do {
                Logger.debug("Loading games from GameService", category: .games)
                let fetchedGames = try await gameService.fetchAllGames()
                await MainActor.run {
                    self.games = fetchedGames
                    self.collectionView.reloadData()
                    Logger.info("Successfully loaded \(fetchedGames.count) games", category: .games)
                }
            } catch {
                await MainActor.run {
                    Logger.error("Failed to load games: \(error.localizedDescription)", category: .games)
                    self.showAlert(title: "Error", message: "Failed to load games: \(error.localizedDescription)")
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
        title = "BatStat"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Add settings gear icon
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gear"),
            style: .plain,
            target: self,
            action: #selector(settingsTapped)
        )
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        
        return UICollectionViewCompositionalLayout(sectionProvider: { sectionIndex, environment in
            switch sectionIndex {
            case 0:
                return self.createActionButtonsSection(environment: environment)
            case 1:
                return self.createGamesGridSection()
            default:
                return self.createActionButtonsSection(environment: environment)
            }
        }, configuration: configuration)
    }
    
    private func createActionButtonsSection(environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(50))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
        section.interGroupSpacing = 0
        
        return section
    }
    
    private func createGamesGridSection() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(120))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 6)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(120))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 14, bottom: 20, trailing: 14)
        section.interGroupSpacing = 12
        
        // Add section header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return section
    }
    
    @objc func addNewGameTapped() {
        let editGameVC = EditGameViewController()
        let navController = UINavigationController(rootViewController: editGameVC)
        
        // Add completion handler to reload games when EditGameViewController is dismissed
        navController.presentationController?.delegate = self
        
        present(navController, animated: true)
    }
    
    @objc func playersAndStatsTapped() {
        let playersVC = PlayersListViewController()
        navigationController?.pushViewController(playersVC, animated: true)
    }
    
    @objc func settingsTapped() {
        let settingsVC = SettingsViewController()
        let navController = UINavigationController(rootViewController: settingsVC)
        present(navController, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func markGameAsFinished(_ game: Game) {
        Task {
            do {
                Logger.info("Marking game as finished: \(game.opponent)", category: .games)
                let updatedGame = try await gameService.markGameAsFinished(gameId: game.id)
                await MainActor.run {
                    if let index = self.games.firstIndex(where: { $0.id == game.id }) {
                        self.games[index] = updatedGame
                        self.collectionView.reloadData()
                        Logger.info("Successfully marked game as finished", category: .games)
                    }
                }
            } catch {
                await MainActor.run {
                    Logger.error("Failed to mark game as finished: \(error.localizedDescription)", category: .games)
                    self.showAlert(title: "Error", message: "Failed to update game: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension ViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2 // Players & Stats, New Game
        case 1:
            return games.count
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        switch indexPath.section {
        case 0:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ActionButtonCell.identifier, for: indexPath) as! ActionButtonCell
            
            let isLastItem = indexPath.item == 1 // Hide separator on last item
            
            if indexPath.item == 0 {
                cell.configure(title: "Players & Stats", systemImage: "figure.baseball", showSeparator: !isLastItem)
            } else {
                cell.configure(title: "New Game", systemImage: "plus.circle.fill", showSeparator: !isLastItem)
            }
            
            return cell
            
        case 1:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GameCell.identifier, for: indexPath) as! GameCell
            let game = games[indexPath.item]
            cell.configure(with: game)
            return cell
            
        default:
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader && indexPath.section == 1 {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
            let completedGames = games.filter { $0.isComplete }.count
            let totalGames = games.count
            header.configure(title: "GAMES (\(completedGames)/\(totalGames) completed)")
            return header
        }
        return UICollectionReusableView()
    }
}

// MARK: - UICollectionViewDelegate

extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            if indexPath.item == 0 {
                playersAndStatsTapped()
            } else {
                addNewGameTapped()
            }
        case 1:
            let game = games[indexPath.item]
            let gameVC = GameViewController()
            gameVC.configure(with: game)
            navigationController?.pushViewController(gameVC, animated: true)
        default:
            break
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension ViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        // Reload games when EditGameViewController is dismissed
        Logger.debug("EditGameViewController dismissed, reloading games", category: .games)
        loadGames()
    }
}
