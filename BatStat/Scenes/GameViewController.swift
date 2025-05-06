//
//  GameViewController.swift
//  BatStat
//
//  Created by Colton Swapp on 5/5/25.
//

import UIKit
import CoreData

// MARK: - PlayerStat
struct PlayerStat {
    let player: Player
    let atBats: Int
    let runs: Int
    let hits: Int
    let rbis: Int
    let homeRuns: Int
    let walks: Int
    let strikeouts: Int
    let average: String  // Formatted as string (e.g., ".275")
}

class GameViewController: UIViewController {
    
    // MARK: - Properties
    
    private let game: GameEntity
    private let gameManager = GameManager.shared
    private var players: [Player] = []
    private var playerStats: [PlayerStat] = []
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    // Section indices
    private enum Section: Int, CaseIterable {
        case gameInfo = 0
        case interactiveView = 1
        case stats = 2
    }
    
    // Define constants for layout to ensure consistency between headers and cells
    struct StatColumnWidth {
        static let playerName: CGFloat = 120
        static let stats: [CGFloat] = [24, 20, 20, 25, 20, 20, 20, 40]
        static let spacing: CGFloat = 0
        static let leftPadding: CGFloat = 150
        
        // Positions for each column (calculated from left edge)
        static let positions: [CGFloat] = {
            var positions: [CGFloat] = []
            var currentPosition = leftPadding
            
            for width in stats {
                positions.append(currentPosition)
                currentPosition += width + spacing
            }
            
            return positions
        }()
    }
    
    // MARK: - Initialization
    
    init(game: GameEntity) {
        self.game = game
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = game.opponentName
        view.backgroundColor = .systemBackground
        
        setupNavigationBar()
        setupTableView()
        loadPlayers()
        generateDummyStats()
        
        // Register for notifications when game data changes
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
        
        // Refresh the title in case it was edited
        title = game.opponentName
    }
    
    // MARK: - Setup
    
    private func setupNavigationBar() {
        navigationItem.largeTitleDisplayMode = .never
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .edit,
            target: self,
            action: #selector(editGame)
        )
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PlayerCell")
        tableView.register(StatsCell.self, forCellReuseIdentifier: "StatsCell")
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "Header")
    }
    
    // MARK: - Data
    
    private func loadPlayers() {
        players = gameManager.getPlayersForGame(game)
        tableView.reloadData()
    }
    
    private func generateDummyStats() {
        // Create dummy stats for each player
        playerStats = players.map { player in
            // Generate random stats
            let atBats = Int.random(in: 0...5)
            let hits = atBats > 0 ? Int.random(in: 0...atBats) : 0
            let runs = hits > 0 ? Int.random(in: 0...hits) : 0
            let homeRuns = hits > 0 ? Int.random(in: 0...(hits > 1 ? 1 : 0)) : 0
            let rbis = hits > 0 ? Int.random(in: 0...3) : 0
            let walks = Int.random(in: 0...2)
            let strikeouts = atBats - hits > 0 ? Int.random(in: 0...(atBats - hits)) : 0
            
            // Calculate batting average
            let average = atBats > 0 ? String(format: ".%03d", Int(Double(hits) / Double(atBats) * 1000)) : ".000"
            
            return PlayerStat(
                player: player,
                atBats: atBats,
                runs: runs,
                hits: hits,
                rbis: rbis,
                homeRuns: homeRuns,
                walks: walks,
                strikeouts: strikeouts,
                average: average
            )
        }
        
        tableView.reloadData()
    }
    
    @objc private func handleGameDataChanged() {
        // Refresh players when notification is received
        loadPlayers()
        generateDummyStats()
        
        // Update the title in case it changed
        title = game.opponentName
    }
    
    // MARK: - Actions
    
    @objc private func editGame() {
        let gameDetailVC = GameDetailViewController(game: game)
        let navController = UINavigationController(rootViewController: gameDetailVC)
        present(navController, animated: true)
    }
    
    // MARK: - Table Header Views
    
    private func createStatsHeaderView() -> UIView {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 40))
        headerView.backgroundColor = .systemGroupedBackground
        
        // Main title
        let titleLabel = UILabel()
        titleLabel.text = "Player Statistics".uppercased()
        titleLabel.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        titleLabel.textColor = .secondaryLabel
        
        // Stats column titles
        let statLabels = ["AB", "R", "H", "RBI", "HR", "BB", "K", "AVG"]
        
        // Add all labels to the header
        headerView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
        ])
        
        // Add stat abbreviation labels
        for (index, title) in statLabels.enumerated() {
            let label = UILabel()
            label.text = title
            label.font = UIFont.systemFont(ofSize: 10, weight: .regular)
            label.textColor = .tertiaryLabel
            label.textAlignment = .center
            
            headerView.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: headerView.leadingAnchor, constant: StatColumnWidth.positions[index] + StatColumnWidth.stats[index]/2),
                label.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8),
                label.widthAnchor.constraint(equalToConstant: StatColumnWidth.stats[index])
            ])
        }
        
        return headerView
    }
}

// MARK: - StatsCell
class StatsCell: UITableViewCell {
    private let playerNameLabel = UILabel()
    
    // Stat labels
    private let abLabel = UILabel()
    private let rLabel = UILabel()
    private let hLabel = UILabel()
    private let rbiLabel = UILabel()
    private let hrLabel = UILabel()
    private let bbLabel = UILabel()
    private let kLabel = UILabel()
    private let avgLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        // Player name at left
        playerNameLabel.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        playerNameLabel.textColor = .label
        
        contentView.addSubview(playerNameLabel)
        playerNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            playerNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            playerNameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playerNameLabel.widthAnchor.constraint(equalToConstant: GameViewController.StatColumnWidth.playerName)
        ])
        
        // Configure and position stat labels with absolute positioning
        let labels = [abLabel, rLabel, hLabel, rbiLabel, hrLabel, bbLabel, kLabel, avgLabel]
        
        for (index, label) in labels.enumerated() {
            label.font = UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
            label.textAlignment = .center
            
            contentView.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: contentView.leadingAnchor, constant: GameViewController.StatColumnWidth.positions[index] + GameViewController.StatColumnWidth.stats[index]/2),
                label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                label.widthAnchor.constraint(equalToConstant: GameViewController.StatColumnWidth.stats[index])
            ])
        }
        
        // Add separator line at bottom
        let separatorLine = UIView()
        separatorLine.backgroundColor = .separator
        contentView.addSubview(separatorLine)
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            separatorLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        
        // Set proper cell height
        contentView.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
    
    func configure(with stat: PlayerStat) {
        let player = stat.player
        playerNameLabel.text = "\(player.firstName.prefix(1)). \(player.lastName) #\(player.number)"
        
        abLabel.text = "\(stat.atBats)"
        rLabel.text = "\(stat.runs)"
        hLabel.text = "\(stat.hits)"
        rbiLabel.text = "\(stat.rbis)"
        hrLabel.text = "\(stat.homeRuns)"
        bbLabel.text = "\(stat.walks)"
        kLabel.text = "\(stat.strikeouts)"
        avgLabel.text = stat.average
    }
}

// MARK: - UITableViewDataSource

extension GameViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionType = Section(rawValue: section) else { return 0 }
        
        switch sectionType {
        case .gameInfo:
            return 1
        case .interactiveView:
            return 2
        case .stats:
            return playerStats.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else {
            return UITableViewCell()
        }
        
        switch section {
        case .gameInfo:
            // Game info section
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            
            if let date = game.date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                content.text = "Game Date"
                content.secondaryText = formatter.string(from: date)
            }
            
            cell.contentConfiguration = content
            return cell
            
        case .interactiveView:
            // Interactive View section
            let cell = tableView.dequeueReusableCell(withIdentifier: "PlayerCell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            
            if indexPath.row == 0 {
                content.text = "Open Interactive Diamond View"
                content.image = UIImage(systemName: "baseball.diamond.bases")
            } else {
                content.text = "Record Play-by-Play"
                content.image = UIImage(systemName: "sportscourt.fill")
            }
            content.imageProperties.tintColor = .systemBlue
            
            cell.contentConfiguration = content
            cell.accessoryType = .disclosureIndicator
            return cell
            
        case .stats:
            // Stats section
            let cell = tableView.dequeueReusableCell(withIdentifier: "StatsCell", for: indexPath) as! StatsCell
            cell.configure(with: playerStats[indexPath.row])
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let sectionType = Section(rawValue: section) else { return nil }
        
        switch sectionType {
        case .gameInfo:
            return "Game Information"
        case .interactiveView:
            return "Interactive View"
        case .stats:
            return "Player Statistics"
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == Section.stats.rawValue else { return nil }
        
        return createStatsHeaderView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section == Section.stats.rawValue ? 40 : UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return indexPath.section == Section.stats.rawValue ? 44 : UITableView.automaticDimension
    }
    
    // MARK: - Table View Customizations
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if section == Section.stats.rawValue, let header = view as? UITableViewHeaderFooterView {
            // Set the background color of the header
            header.contentView.backgroundColor = .systemGroupedBackground
        }
    }
}

// MARK: - UITableViewDelegate

extension GameViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let section = Section(rawValue: indexPath.section) else { return }
        
        if section == .interactiveView {
            if indexPath.row == 0 {
                presentInteractiveDiamondView()
            } else if indexPath.row == 1 {
                presentPlayEntryView()
            }
        } else if section == .stats {
            // Player row tapped - present ABViewController
            presentAtBatView(for: playerStats[indexPath.row].player)
        }
    }
    
    private func presentInteractiveDiamondView() {
        let interactiveDiamondVC = InteractiveDiamondViewController()
        
        if let sheet = interactiveDiamondVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        
        present(interactiveDiamondVC, animated: true)
    }
    
    private func presentPlayEntryView() {
        let playEntryVC = PlayEntryViewController()
        let navController = UINavigationController(rootViewController: playEntryVC)
        
        if let sheet = navController.sheetPresentationController {
            
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        
        playEntryVC.isModalInPresentation = true
        navController.isModalInPresentation = true
        
        present(navController, animated: true)
    }
    
    private func presentAtBatView(for player: Player) {
        let abVC = ABViewController(player: player)
        let navController = UINavigationController(rootViewController: abVC)
        
        // Set up completion handler
        abVC.onAtBatComplete = { [weak self] result, isOut in
            guard let self = self else { return }
            
            print("At-bat complete: \(player.firstName) \(player.lastName) - \(result)")
            
            // Find the player's index in the playerStats array
            if let index = self.playerStats.firstIndex(where: { $0.player.id == player.id }) {
                // Update player stats based on the at-bat result
                var updatedStat = self.playerStats[index]
                
                // Increment at-bats
                let newAtBats = updatedStat.atBats + 1
                
                // Default values
                var newHits = updatedStat.hits
                var newRuns = updatedStat.runs
                var newRbis = updatedStat.rbis
                var newHomeRuns = updatedStat.homeRuns
                var newWalks = updatedStat.walks
                var newStrikeouts = updatedStat.strikeouts
                
                // Update stats based on result
                switch result {
                case "K":
                    newStrikeouts += 1
                case "BB":
                    newWalks += 1
                    // Walk doesn't count as an at-bat in baseball stats
                    // Revert at-bat increment for walks
                    let correctedAtBats = newAtBats - 1
                case "1B":
                    newHits += 1
                case "2B":
                    newHits += 1
                case "3B":
                    newHits += 1
                case "HR":
                    newHits += 1
                    newHomeRuns += 1
                    newRuns += 1
                    // Add at least 1 RBI for the batter
                    newRbis += 1
                case "Out":
                    // No change needed for outs
                    break
                default:
                    break
                }
                
                // Calculate updated batting average
                let average = newAtBats > 0 ? String(format: ".%03d", Int(Double(newHits) / Double(newAtBats) * 1000)) : ".000"
                
                // Create updated player stat
                let updatedPlayerStat = PlayerStat(
                    player: player,
                    atBats: result == "BB" ? updatedStat.atBats : newAtBats,
                    runs: newRuns,
                    hits: newHits,
                    rbis: newRbis,
                    homeRuns: newHomeRuns,
                    walks: newWalks,
                    strikeouts: newStrikeouts,
                    average: average
                )
                
                // Update the playerStats array
                self.playerStats[index] = updatedPlayerStat
                
                // Refresh the table
                self.tableView.reloadSections(IndexSet(integer: Section.stats.rawValue), with: .automatic)
            }
        }
        
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        
        present(navController, animated: true)
    }
} 
