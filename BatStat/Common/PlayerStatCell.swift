import UIKit

class PlayerStatCell: UICollectionViewListCell {
    static let identifier = "PlayerStatCell"
    
    private let atBatIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "figure.baseball")
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true // Hidden by default
        return imageView
    }()
    
    private let playerNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private let fakeHeaderStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 2
        stackView.alpha = 0 // Make it invisible
        return stackView
    }()
    
    private let statsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 2
        return stackView
    }()
    
    private let abLabel = UILabel()
    private let rLabel = UILabel()
    private let hLabel = UILabel()
    private let rbiLabel = UILabel()
    private let hrLabel = UILabel()
    private let avgLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Create fake header labels to match the header layout
        let fakeHeaderLabels = ["AB", "R", "H", "RBI", "HR", "AVG"]
        for text in fakeHeaderLabels {
            let label = UILabel()
            label.text = text
            label.font = .systemFont(ofSize: 13, weight: .semibold)
            label.textAlignment = .center
            fakeHeaderStackView.addArrangedSubview(label)
        }
        
        // Setup stat labels
        let statLabels = [abLabel, rLabel, hLabel, rbiLabel, hrLabel, avgLabel]
        for label in statLabels {
            label.font = .monospacedDigitSystemFont(ofSize: 13, weight: .regular)
            label.textColor = .label
            label.textAlignment = .center
            statsStackView.addArrangedSubview(label)
        }
        
        addSubview(atBatIconImageView)
        addSubview(playerNameLabel)
        addSubview(fakeHeaderStackView)
        addSubview(statsStackView)
        
        NSLayoutConstraint.activate([
            atBatIconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            atBatIconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            atBatIconImageView.widthAnchor.constraint(equalToConstant: 16),
            atBatIconImageView.heightAnchor.constraint(equalToConstant: 16),
            
            playerNameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22),
            playerNameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            fakeHeaderStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            fakeHeaderStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            statsStackView.leadingAnchor.constraint(equalTo: fakeHeaderStackView.leadingAnchor),
            statsStackView.trailingAnchor.constraint(equalTo: fakeHeaderStackView.trailingAnchor),
            statsStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func configure(with playerStats: PlayerGameStats, isCurrentAtBat: Bool = false) {
        playerNameLabel.text = playerStats.player.name
        
        abLabel.text = "\(playerStats.atBats)"
        rLabel.text = "\(playerStats.runs)"
        hLabel.text = "\(playerStats.hits)"
        rbiLabel.text = "\(playerStats.rbis)"
        hrLabel.text = "\(playerStats.homeRuns)"
        let avg = playerStats.battingAverage
        if avg >= 1.0 {
            avgLabel.text = String(format: "%.2f", avg)  // Show "1.0" for perfect average
        } else {
            avgLabel.text = String(format: ".%03d", Int(round(avg * 1000)))  // Show ".333" format
        }
        
        // Show/hide the baseball icon based on current at-bat status
        atBatIconImageView.isHidden = !isCurrentAtBat
        
        // Use standard background configuration (no more blue background)
        backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        playerNameLabel.text = nil
        abLabel.text = nil
        rLabel.text = nil
        hLabel.text = nil
        rbiLabel.text = nil
        hrLabel.text = nil
        avgLabel.text = nil
        atBatIconImageView.isHidden = true
        backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
    }
}
