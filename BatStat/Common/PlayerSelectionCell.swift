import UIKit

class PlayerSelectionCell: UICollectionViewListCell {
    static let identifier = "PlayerSelectionCell"
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private let numberLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "checkmark.circle.fill")
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
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
        addSubview(nameLabel)
        addSubview(numberLabel)
        addSubview(checkmarkImageView)
        
        NSLayoutConstraint.activate([
            
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            numberLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
            numberLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            checkmarkImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            checkmarkImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 24),
            checkmarkImageView.leadingAnchor.constraint(greaterThanOrEqualTo: numberLabel.trailingAnchor, constant: 16)
        ])
    }
    
    func configure(with player: Player, isSelected: Bool) {
        nameLabel.text = player.name
        if let number = player.number {
            numberLabel.text = "#\(number)"
        } else {
            numberLabel.text = ""
        }
        
        checkmarkImageView.isHidden = !isSelected
        
        // Update background color based on selection
        if isSelected {
            var backgroundConfig = UIBackgroundConfiguration.listGroupedCell()
            backgroundConfig.backgroundColor = .systemBlue.withAlphaComponent(0.1)
            backgroundConfiguration = backgroundConfig
        } else {
            backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        numberLabel.text = nil
        checkmarkImageView.isHidden = true
        backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
    }
} 
