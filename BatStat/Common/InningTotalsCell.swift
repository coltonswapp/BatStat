import UIKit

class InningTotalsCell: UICollectionViewListCell {
    static let identifier = "InningTotalsCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .label
        label.text = "Inning Totals"
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Create fake header labels to match the header layout
        let fakeHeaderLabels = ["AB", "R", "H", "RBI", "HR"]
        for text in fakeHeaderLabels {
            let label = UILabel()
            label.text = text
            label.font = .systemFont(ofSize: 13, weight: .semibold)
            label.textAlignment = .center
            fakeHeaderStackView.addArrangedSubview(label)
        }
        
        let statLabels = [abLabel, rLabel, hLabel, rbiLabel, hrLabel]
        
        for label in statLabels {
            label.font = .systemFont(ofSize: 15, weight: .medium)
            label.textColor = .label
            label.textAlignment = .center
            statsStackView.addArrangedSubview(label)
        }
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(fakeHeaderStackView)
        contentView.addSubview(statsStackView)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            fakeHeaderStackView.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 16),
            fakeHeaderStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            fakeHeaderStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            
            statsStackView.leadingAnchor.constraint(equalTo: fakeHeaderStackView.leadingAnchor),
            statsStackView.trailingAnchor.constraint(equalTo: fakeHeaderStackView.trailingAnchor),
            statsStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configure(ab: Int, r: Int, h: Int, rbi: Int, hr: Int) {
        abLabel.text = "\(ab)"
        rLabel.text = "\(r)"
        hLabel.text = "\(h)"
        rbiLabel.text = "\(rbi)"
        hrLabel.text = "\(hr)"
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        abLabel.text = nil
        rLabel.text = nil
        hLabel.text = nil
        rbiLabel.text = nil
        hrLabel.text = nil
    }
}
