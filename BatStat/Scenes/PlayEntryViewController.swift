//
//  PlayEntryViewController.swift
//  BatStat
//
//  Created by Colton Swapp on 5/5/25.
//

import UIKit

enum AtBatOption: String, CaseIterable {
    case ball = "Ball"
    case strike = "Strike"
    case swingAndMiss = "Swing & Miss"
    case foulBall = "Foul Ball"
    case ballInPlay = "Ball in Play"
    
    var icon: UIImage? {
        switch self {
        case .ball:
            return UIImage(systemName: "b.circle")
        case .strike:
            return UIImage(systemName: "k.square.fill")
        case .swingAndMiss:
            // Create a backwards K using a custom configuration
            let config = UIImage.SymbolConfiguration(scale: .large)
            return UIImage(systemName: "k.square.fill", withConfiguration: config)
        case .foulBall:
            return UIImage(systemName: "f.circle")
        case .ballInPlay:
            return UIImage(systemName: "baseball")
        }
    }
}

class PlayerAtBat {
    let player: Player
    var balls: Int
    var strikes: Int
    
    init(player: Player, balls: Int = 0, strikes: Int = 0) {
        self.player = player
        self.balls = balls
        self.strikes = strikes
    }
}

class CurrentBatterView: UIView {
    // MARK: - UI Elements
    
    private let previousButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    
    private let batterNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textAlignment = .center
        label.text = "J. Smith"
        return label
    }()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.text = "B0 S0"
        return label
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.tintColor = .systemBlue
        return button
    }()
    
    // MARK: - Properties
    
    var onPreviousTapped: (() -> Void)?
    var onNextTapped: (() -> Void)?
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupViews() {
        backgroundColor = .systemBackground
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        
        // Add bottom border
        let borderView = UIView()
        borderView.backgroundColor = .separator
        addSubview(borderView)
        
        // Add subviews
        addSubview(previousButton)
        addSubview(batterNameLabel)
        addSubview(countLabel)
        addSubview(nextButton)
        
        // Setup constraints
        previousButton.translatesAutoresizingMaskIntoConstraints = false
        batterNameLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        nextButton.translatesAutoresizingMaskIntoConstraints = false
        borderView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Previous button
            previousButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            previousButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            previousButton.widthAnchor.constraint(equalToConstant: 44),
            previousButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Batter name label
            batterNameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            batterNameLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            batterNameLabel.leadingAnchor.constraint(greaterThanOrEqualTo: previousButton.trailingAnchor, constant: 8),
            batterNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: nextButton.leadingAnchor, constant: -8),
            
            // Count label
            countLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            countLabel.topAnchor.constraint(equalTo: batterNameLabel.bottomAnchor, constant: 2),
            countLabel.leadingAnchor.constraint(greaterThanOrEqualTo: previousButton.trailingAnchor, constant: 8),
            countLabel.trailingAnchor.constraint(lessThanOrEqualTo: nextButton.leadingAnchor, constant: -8),
            
            // Next button
            nextButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            nextButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 44),
            nextButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Border view
            borderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            borderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            borderView.bottomAnchor.constraint(equalTo: bottomAnchor),
            borderView.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        
        // Add actions
        previousButton.addTarget(self, action: #selector(previousButtonTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Public Methods
    
    func updateBatterName(firstName: String, lastName: String) {
        batterNameLabel.text = "\(firstName.prefix(1)). \(lastName)"
    }
    
    func updateCount(balls: Int, strikes: Int) {
        countLabel.text = "B\(balls) S\(strikes)"
    }
    
    // MARK: - Actions
    
    @objc private func previousButtonTapped() {
        onPreviousTapped?()
    }
    
    @objc private func nextButtonTapped() {
        onNextTapped?()
    }
}

class PlayEntryViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let currentBatterView = CurrentBatterView()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    // MARK: - Properties
    
    private var currentBatterIndex = 0
    private var playerAtBats: [PlayerAtBat] = []
    
    // Track count for current batter
    private var currentBalls = 0
    private var currentStrikes = 0
    private let maxBalls = 4
    private let maxStrikes = 3
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupTableView()
        loadDummyPlayers()
        updateCurrentBatter()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Play Ball"
        
        // Add close button to navigation bar
        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(dismissViewController)
        )
        navigationItem.rightBarButtonItem = closeButton
                
        // Add tableView
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add and configure current batter view
        view.addSubview(currentBatterView)
        currentBatterView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            currentBatterView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            currentBatterView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            currentBatterView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            currentBatterView.heightAnchor.constraint(equalToConstant: 55),
            
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.contentInset.top = 45.0
        
        // Set up callbacks
        currentBatterView.onPreviousTapped = { [weak self] in
            self?.goToPreviousBatter()
        }
        
        currentBatterView.onNextTapped = { [weak self] in
            self?.goToNextBatter()
        }
    }
    
    private func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 60
    }
    
    // MARK: - Data Loading
    
    private func loadDummyPlayers() {
        // Load sample lineup
        playerAtBats = [
            PlayerAtBat(player: Player(firstName: "John", lastName: "Smith", number: 10)),
            PlayerAtBat(player: Player(firstName: "Mike", lastName: "Johnson", number: 22)),
            PlayerAtBat(player: Player(firstName: "David", lastName: "Brown", number: 5)),
            PlayerAtBat(player: Player(firstName: "Chris", lastName: "Wilson", number: 18)),
            PlayerAtBat(player: Player(firstName: "James", lastName: "Davis", number: 7)),
            PlayerAtBat(player: Player(firstName: "Robert", lastName: "Miller", number: 33)),
            PlayerAtBat(player: Player(firstName: "Daniel", lastName: "Thomas", number: 42)),
            PlayerAtBat(player: Player(firstName: "Kevin", lastName: "Anderson", number: 9)),
            PlayerAtBat(player: Player(firstName: "Brian", lastName: "Taylor", number: 15))
        ]
    }
    
    private func updateCurrentBatter() {
        guard !playerAtBats.isEmpty else { return }
        
        let playerAtBat = playerAtBats[currentBatterIndex]
        currentBatterView.updateBatterName(firstName: playerAtBat.player.firstName, lastName: playerAtBat.player.lastName)
        
        // Load this batter's count
        currentBalls = playerAtBat.balls
        currentStrikes = playerAtBat.strikes
        currentBatterView.updateCount(balls: currentBalls, strikes: currentStrikes)
    }
    
    // MARK: - Count Management
    
    private func resetCount() {
        currentBalls = 0
        currentStrikes = 0
    }
    
    private func updateCount(balls: Int, strikes: Int) {
        currentBalls = balls
        currentStrikes = strikes
        currentBatterView.updateCount(balls: currentBalls, strikes: currentStrikes)
        
        // Check if the count results in a walk or strikeout
        if currentBalls >= maxBalls {
            handleWalk()
        } else if currentStrikes >= maxStrikes {
            handleStrikeOut()
        }
    }
    
    private func handleWalk() {
        // Show alert for walk
        let alert = UIAlertController(
            title: "Walk",
            message: "Batter advances to first base",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.goToNextBatter()
        })
        
        present(alert, animated: true)
    }
    
    private func handleStrikeOut() {
        // Show alert for strikeout
        let alert = UIAlertController(
            title: "Strike Out",
            message: "Batter is out",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.goToNextBatter()
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Navigation
    
    private func goToPreviousBatter() {
        guard !playerAtBats.isEmpty else { return }
        
        // Save current batter's count
        playerAtBats[currentBatterIndex].balls = currentBalls
        playerAtBats[currentBatterIndex].strikes = currentStrikes
        
        // Move to previous batter
        currentBatterIndex = (currentBatterIndex - 1 + playerAtBats.count) % playerAtBats.count
        updateCurrentBatter()
    }
    
    private func goToNextBatter() {
        guard !playerAtBats.isEmpty else { return }
        
        // Save current batter's count
        playerAtBats[currentBatterIndex].balls = currentBalls
        playerAtBats[currentBatterIndex].strikes = currentStrikes
        
        // Move to next batter
        currentBatterIndex = (currentBatterIndex + 1) % playerAtBats.count
        updateCurrentBatter()
    }
    
    // MARK: - Actions
    
    @objc private func dismissViewController() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension PlayEntryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return AtBatOption.allCases.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Select Play Outcome"
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "Tap an option to record the result for the current batter"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let option = AtBatOption.allCases[indexPath.row]
        
        // Configure the cell
        var config = cell.defaultContentConfiguration()
        config.text = option.rawValue
        
        config.imageProperties.tintColor = .systemBlue
        
        if let icon = option.icon {
            if option == .strike {
                
                // Create a bitmap context with the same properties as the original image
                let format = UIGraphicsImageRendererFormat()
                format.scale = icon.scale
                format.opaque = false
                
                let renderer = UIGraphicsImageRenderer(size: icon.size, format: format)
                let flippedImage = renderer.image { context in
                    // Flip horizontally
                    context.cgContext.translateBy(x: icon.size.width, y: 0)
                    context.cgContext.scaleBy(x: -1, y: 1)
                    
                    // Draw the original image
                    icon.draw(in: CGRect(origin: .zero, size: icon.size))
                }
                
                config.image = flippedImage
            } else {
                config.image = icon
            }
        }
        
        // Set icon tint color
        if option == .swingAndMiss {
            config.imageProperties.tintColor = .systemRed
        } else {
            config.imageProperties.tintColor = .systemBlue
        }
        
        // Set image to standard size
        config.imageProperties.maximumSize = CGSize(width: 30, height: 30)
        
        cell.contentConfiguration = config
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Handle selection
        let option = AtBatOption.allCases[indexPath.row]
        print("Selected: \(option.rawValue)")
        
        // Update count based on the selected option
        switch option {
        case .ball:
            updateCount(balls: currentBalls + 1, strikes: currentStrikes)
            
        case .strike, .swingAndMiss:
            updateCount(balls: currentBalls, strikes: currentStrikes + 1)
            
        case .foulBall:
            // Foul balls count as strikes, except when already at 2 strikes
            if currentStrikes < 2 {
                updateCount(balls: currentBalls, strikes: currentStrikes + 1)
            }
            
        case .ballInPlay:
            // Ball in play means the at-bat is over, go to next batter
            let alert = UIAlertController(
                title: "Ball in Play",
                message: "Select the result",
                preferredStyle: .actionSheet
            )
            
            alert.addAction(UIAlertAction(title: "Out", style: .default) { [weak self] _ in
                self?.goToNextBatter()
            })
            
            alert.addAction(UIAlertAction(title: "Single", style: .default) { [weak self] _ in
                self?.goToNextBatter()
            })
            
            alert.addAction(UIAlertAction(title: "Double", style: .default) { [weak self] _ in
                self?.goToNextBatter()
            })
            
            alert.addAction(UIAlertAction(title: "Triple", style: .default) { [weak self] _ in
                self?.goToNextBatter()
            })
            
            alert.addAction(UIAlertAction(title: "Home Run", style: .default) { [weak self] _ in
                self?.goToNextBatter()
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            // For iPad support
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = tableView.cellForRow(at: indexPath)
                popoverController.sourceRect = tableView.cellForRow(at: indexPath)?.bounds ?? CGRect.zero
            }
            
            present(alert, animated: true)
        }
    }
} 
