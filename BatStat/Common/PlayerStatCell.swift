import UIKit

class PlayerStatCell: UICollectionViewListCell {
    static let identifier = "PlayerStatCell"
    
    private let playerNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .label
        return label
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
        // Setup stat labels
        let statLabels = [abLabel, rLabel, hLabel, rbiLabel, hrLabel, avgLabel]
        for label in statLabels {
            label.font = .systemFont(ofSize: 13, weight: .regular)
            label.textColor = .label
            label.textAlignment = .center
            statsStackView.addArrangedSubview(label)
        }
        
        addSubview(playerNameLabel)
        addSubview(statsStackView)
        
        NSLayoutConstraint.activate([
            playerNameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22),
            playerNameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            playerNameLabel.widthAnchor.constraint(equalToConstant: 120),
            
//            statsStackView.leadingAnchor.constraint(equalTo: playerNameLabel.trailingAnchor, constant: 16),
            statsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
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
        avgLabel.text = avg >= 1.0 ? String(format: "%.3f", avg) : String(String(format: "%.3f", avg).dropFirst())
        
        // Use backgroundConfiguration for UICollectionViewListCell
        var backgroundConfig = UIBackgroundConfiguration.listGroupedCell()
        if isCurrentAtBat {
            backgroundConfig.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        }
        backgroundConfiguration = backgroundConfig
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
        backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
    }
}
