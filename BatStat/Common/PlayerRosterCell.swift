import UIKit

class PlayerRosterCell: UICollectionViewListCell {
    static let identifier = "PlayerRosterCell"
    
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
    
    private let reorderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "line.3.horizontal")
        imageView.tintColor = .tertiaryLabel
        imageView.contentMode = .scaleAspectFit
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
        addSubview(numberLabel)
        addSubview(nameLabel)
        addSubview(reorderImageView)
        
        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            numberLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
//            numberLabel.widthAnchor.constraint(equalToConstant: 40),
            
            numberLabel.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 12),
            nameLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            reorderImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -22),
            reorderImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            reorderImageView.widthAnchor.constraint(equalToConstant: 20),
            reorderImageView.heightAnchor.constraint(equalToConstant: 20),
            reorderImageView.leadingAnchor.constraint(greaterThanOrEqualTo: nameLabel.trailingAnchor, constant: 16)
        ])
    }
    
    func configure(with player: Player) {
        nameLabel.text = player.name
        if let number = player.number {
            numberLabel.text = "#\(number)"
        }
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        numberLabel.text = nil
    }
}
