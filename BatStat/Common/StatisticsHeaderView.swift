import UIKit

class StatisticsHeaderView: UICollectionReusableView {
    static let identifier = "StatisticsHeaderView"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .secondaryLabel
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
    
    private let abHeaderLabel = UILabel()
    private let rHeaderLabel = UILabel()
    private let hHeaderLabel = UILabel()
    private let rbiHeaderLabel = UILabel()
    private let hrHeaderLabel = UILabel()
    private let avgHeaderLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Setup header labels
        let headerLabels = [
            (abHeaderLabel, "AB"),
            (rHeaderLabel, "R"),
            (hHeaderLabel, "H"),
            (rbiHeaderLabel, "RBI"),
            (hrHeaderLabel, "HR"),
            (avgHeaderLabel, "AVG")
        ]
        
        for (label, text) in headerLabels {
            label.font = .monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            label.text = text
            statsStackView.addArrangedSubview(label)
        }
        
//        backgroundColor = .red.withAlphaComponent(0.2)
        
        addSubview(titleLabel)
        addSubview(statsStackView)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            statsStackView.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 16),
            statsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            statsStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }
    
    func configure(title: String) {
        titleLabel.text = title.uppercased()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }
}
