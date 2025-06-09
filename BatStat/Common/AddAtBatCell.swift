import UIKit

class AddAtBatCell: UICollectionViewListCell {
    static let identifier = "AddAtBatCell"
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "plus.circle.fill")
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Add New At-Bat"
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .systemBlue
        label.textAlignment = .center
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
        // Set blue background
        var backgroundConfig = UIBackgroundConfiguration.listGroupedCell()
        backgroundConfiguration = backgroundConfig
        
        addSubview(iconImageView)
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 22),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 20),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -22)
        ])
    }
    
//    override var isHighlighted: Bool {
//        didSet {
//            UIView.animate(withDuration: 0.1) {
//                var backgroundConfig = UIBackgroundConfiguration.listGroupedCell()
//                backgroundConfig.backgroundColor = self.isHighlighted ? .systemBlue.withAlphaComponent(0.8) : .systemBlue
//                self.backgroundConfiguration = backgroundConfig
//            }
//        }
//    }
}
