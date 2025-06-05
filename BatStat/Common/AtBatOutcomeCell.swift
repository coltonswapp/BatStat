import UIKit

class AtBatOutcomeCell: UICollectionViewListCell {
    static let identifier = "AtBatOutcomeCell"
    
    private let atBatNumberLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private let outcomeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 15, weight: .regular)
        label.textColor = .secondaryLabel
        label.textAlignment = .right
        return label
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
        
        NSLayoutConstraint.activate([
            atBatNumberLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22),
            atBatNumberLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            outcomeLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22),
            outcomeLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            outcomeLabel.leadingAnchor.constraint(greaterThanOrEqualTo: atBatNumberLabel.trailingAnchor, constant: 16)
        ])
    }
    
    func configure(atBatNumber: Int, outcome: String) {
        atBatNumberLabel.text = "#\(atBatNumber)"
        outcomeLabel.text = outcome
    }
    
    func configure(playerName: String, outcome: String) {
        atBatNumberLabel.text = playerName
        outcomeLabel.text = outcome
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        atBatNumberLabel.text = nil
        outcomeLabel.text = nil
    }
}
