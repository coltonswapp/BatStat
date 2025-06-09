import UIKit

class AtBatOutcomeCell: UICollectionViewListCell {
    static let identifier = "AtBatOutcomeCell"
    
    private let atBatNumberLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private let outcomeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        return label
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(atBatNumberLabel)
        addSubview(outcomeLabel)
        addSubview(iconImageView)
        
        NSLayoutConstraint.activate([
            atBatNumberLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22),
            atBatNumberLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            iconImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            outcomeLabel.trailingAnchor.constraint(equalTo: iconImageView.leadingAnchor, constant: -12),
            outcomeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            outcomeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: atBatNumberLabel.trailingAnchor, constant: 16)
        ])
    }
    
    func configure(atBatNumber: Int, outcome: String) {
        atBatNumberLabel.text = "#\(atBatNumber)"
        outcomeLabel.text = outcome
        iconImageView.image = nil // No icon for basic configuration
    }
    
    func configure(playerName: String, outcome: String) {
        atBatNumberLabel.text = playerName
        outcomeLabel.text = outcome
        iconImageView.image = nil // No icon for basic configuration
    }
    
    // Helper method to map outcome strings to StatType (for mock data compatibility)
    private func mapOutcomeToStatType(_ outcome: String) -> StatType {
        let lowercaseOutcome = outcome.lowercased()
        
        if lowercaseOutcome.contains("single") {
            return .single
        } else if lowercaseOutcome.contains("double") {
            return .double
        } else if lowercaseOutcome.contains("triple") {
            return .triple
        } else if lowercaseOutcome.contains("home run") {
            return .homeRun
        } else if lowercaseOutcome.contains("strikeout") {
            return .strikeOut
        } else if lowercaseOutcome.contains("walk") {
            return .walk
        } else if lowercaseOutcome.contains("fly out") || lowercaseOutcome.contains("flyout") {
            return .flyOut
        } else if lowercaseOutcome.contains("ground out") || lowercaseOutcome.contains("out") {
            return .atBat
        } else if lowercaseOutcome.contains("error") {
            return .error
        } else if lowercaseOutcome.contains("sacrifice") {
            return .sacrifice
        } else if lowercaseOutcome.contains("fielder") {
            return .fieldersChoice
        } else {
            return .atBat // Default fallback
        }
    }
    
    // Configure method for cases where StatType is available
    func configure(atBatNumber: Int, outcome: String, statType: StatType) {
        atBatNumberLabel.text = "AB \(atBatNumber)"
        outcomeLabel.text = outcome
        iconImageView.image = UIImage(named: getIconName(for: statType))
    }
    
    // Configure method with inning information
    func configure(atBatNumber: Int, outcome: String, statType: StatType, inning: Int?) {
        if let inning = inning {
            atBatNumberLabel.text = "AB \(atBatNumber) • Inn \(inning)"
        } else {
            atBatNumberLabel.text = "AB \(atBatNumber)"
        }
        outcomeLabel.text = outcome
        iconImageView.image = UIImage(named: getIconName(for: statType))
    }
    
    // Configure method for cases where StatType needs to be inferred (like PlayByPlayViewController)
    func configure(playerName: String, outcome: String, statType: StatType? = nil) {
        atBatNumberLabel.text = playerName
        outcomeLabel.text = outcome
        
        let finalStatType = statType ?? mapOutcomeToStatType(outcome)
        iconImageView.image = UIImage(named: getIconName(for: finalStatType))
    }
    
    private func getIconName(for statType: StatType) -> String {
        switch statType {
        case .atBat:
            return "oaf_icon" // Out at first for generic outs
        case .single, .hit:
            return "first_icon"
        case .double:
            return "second_icon"
        case .triple:
            return "third_icon"
        case .homeRun:
            return "hr_icon"
        case .strikeOut:
            return "strikeout_icon"
        case .walk:
            return "walk_icon"
        case .flyOut:
            return "flyout_icon"
        case .rbi:
            return "rbi_icon"
        case .run:
            return "run_icon" // Use single icon for runs
        case .error:
            return "oaf_icon" // Use out icon for errors
        case .fieldersChoice:
            return "oaf_icon" // Use out icon for fielder's choice
        case .sacrifice:
            return "oaf_icon" // Use out icon for sacrifice
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        atBatNumberLabel.text = nil
        outcomeLabel.text = nil
        iconImageView.image = nil
    }
}
