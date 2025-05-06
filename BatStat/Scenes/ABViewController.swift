//
//  ABViewController.swift
//  BatStat
//
//  Created by Colton Swapp on 5/5/25.
//

import UIKit

class ABViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private var statView: BlurBackgroundLabel!
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    // MARK: - Properties
    
    private var player: Player
    private var currentBalls = 0
    private var currentStrikes = 0
    private let maxBalls = 4
    private let maxStrikes = 3
    
    // Completion handler for when at-bat is completed
    var onAtBatComplete: ((String, Bool) -> Void)?
    
    // MARK: - Initialization
    
    init(player: Player) {
        self.player = player
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupTableView()
        setupStatLabel()
        updateCurrentBatter()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Create custom title view with stackview
        let titleStackView = UIStackView()
        titleStackView.axis = .vertical
        titleStackView.alignment = .center
        titleStackView.spacing = 2
        
        let titleLabel = UILabel()
        titleLabel.text = "Record At-Bat"
        titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        
        let playerInitial = player.firstName.prefix(1)
        let subtitleLabel = UILabel()
        subtitleLabel.text = "\(playerInitial). \(player.lastName)"
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabel
        
        titleStackView.addArrangedSubview(titleLabel)
        titleStackView.addArrangedSubview(subtitleLabel)
        
        navigationItem.titleView = titleStackView
        
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
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.contentInset.bottom = -32.0
    }
    
    private func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 60
    }
    
    private func updateCurrentBatter() {
        updateCountDisplay()
    }
    
    private func updateCountDisplay() {
        statView.text = "B\(currentBalls) S\(currentStrikes)"
    }
    
    private func setupStatLabel() {
        statView = BlurBackgroundLabel(with: .systemThinMaterial)
        statView.translatesAutoresizingMaskIntoConstraints = false
        statView.text = "B0 S0"
        statView.font = .systemFont(ofSize: 16, weight: .regular)
        statView.textColor = .secondaryLabel
        
        statView.layer.shadowColor = UIColor.black.cgColor
        statView.layer.shadowOpacity = 0.3
        statView.layer.shadowOffset = CGSize(width: 4, height: 8)
        statView.layer.shadowRadius = 8
        
        view.addSubview(statView)
        
        NSLayoutConstraint.activate([
            statView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            statView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statView.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.8)
        ])
    }
    
    // MARK: - Count Management
    
    private func resetCount() {
        currentBalls = 0
        currentStrikes = 0
        updateCountDisplay()
    }
    
    private func updateCount(balls: Int, strikes: Int) {
        currentBalls = balls
        currentStrikes = strikes
        updateCountDisplay()
        
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
            self?.completeAtBat(result: "BB", isOut: false)
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
            self?.completeAtBat(result: "K", isOut: true)
        })
        
        present(alert, animated: true)
    }
    
    private func completeAtBat(result: String, isOut: Bool) {
        // Call the completion handler with the result
        onAtBatComplete?(result, isOut)
        
        // Dismiss the view controller
        dismiss(animated: true)
    }
    
    // MARK: - Actions
    
    @objc private func dismissViewController() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension ABViewController: UITableViewDelegate, UITableViewDataSource {
    
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
            
            // Out
            let outAction = UIAlertAction(title: "Out", style: .default) { [weak self] _ in
                self?.completeAtBat(result: "Out", isOut: true)
            }
            outAction.setValue(UIImage(systemName: "xmark.circle"), forKey: "image")
            alert.addAction(outAction)
            
            // Single
            let singleAction = UIAlertAction(title: "Single", style: .default) { [weak self] _ in
                self?.completeAtBat(result: "1B", isOut: false)
            }
            singleAction.setValue(UIImage(systemName: "1.circle"), forKey: "image")
            alert.addAction(singleAction)
            
            // Double
            let doubleAction = UIAlertAction(title: "Double", style: .default) { [weak self] _ in
                self?.completeAtBat(result: "2B", isOut: false)
            }
            doubleAction.setValue(UIImage(systemName: "2.circle"), forKey: "image")
            alert.addAction(doubleAction)
            
            // Triple
            let tripleAction = UIAlertAction(title: "Triple", style: .default) { [weak self] _ in
                self?.completeAtBat(result: "3B", isOut: false)
            }
            tripleAction.setValue(UIImage(systemName: "3.circle"), forKey: "image")
            alert.addAction(tripleAction)
            
            // Home Run
            let hrAction = UIAlertAction(title: "Home Run", style: .default) { [weak self] _ in
                self?.completeAtBat(result: "HR", isOut: false)
            }
            hrAction.setValue(UIImage(systemName: "star.circle"), forKey: "image")
            alert.addAction(hrAction)
            
            // Cancel
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            alert.addAction(cancelAction)
            
            // For iPad support
            if let popoverController = alert.popoverPresentationController {
                popoverController.sourceView = tableView.cellForRow(at: indexPath)
                popoverController.sourceRect = tableView.cellForRow(at: indexPath)?.bounds ?? CGRect.zero
            }
            
            present(alert, animated: true)
        }
    }
} 
