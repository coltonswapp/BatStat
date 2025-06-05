import UIKit

class AtBatOptionCell: UICollectionViewListCell {
    static let identifier = "AtBatOptionCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .label
        return label
    }()
    
    private let rbiButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("0 RBI", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.systemBlue, for: .normal)
        button.isHidden = true // Only show for RBI option
        return button
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        imageView.isHidden = true
        return imageView
    }()
    
    private let checkmarkImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(systemName: "checkmark")
        imageView.tintColor = .systemBlue
        imageView.isHidden = true
        return imageView
    }()
    
    var onRBISelection: ((Int) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupRBIMenu()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(rbiButton)
        addSubview(checkmarkImageView)
        
        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            checkmarkImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            checkmarkImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 20),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 20),
            
            rbiButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            rbiButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            rbiButton.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 16)
        ])
    }
    
    private func setupRBIMenu() {
        let menuActions = [
            UIAction(title: "0 RBI", handler: { [weak self] _ in
                self?.rbiButton.setTitle("0 RBI", for: .normal)
                self?.onRBISelection?(0)
            }),
            UIAction(title: "1 RBI", handler: { [weak self] _ in
                self?.rbiButton.setTitle("1 RBI", for: .normal)
                self?.onRBISelection?(1)
            }),
            UIAction(title: "2 RBI", handler: { [weak self] _ in
                self?.rbiButton.setTitle("2 RBI", for: .normal)
                self?.onRBISelection?(2)
            }),
            UIAction(title: "3 RBI", handler: { [weak self] _ in
                self?.rbiButton.setTitle("3 RBI", for: .normal)
                self?.onRBISelection?(3)
            })
        ]
        
        rbiButton.menu = UIMenu(title: "Select RBI Count", children: menuActions)
        rbiButton.showsMenuAsPrimaryAction = true
    }
    
    func configure(with option: AtBatOption, isSelected: Bool = false) {
        titleLabel.text = option.title
        rbiButton.isHidden = !option.showRBIButton
        checkmarkImageView.isHidden = !isSelected
        
        iconImageView.image = UIImage(named: option.type.imageName)
        iconImageView.isHidden = false
        
        if option.showRBIButton {
            rbiButton.setTitle("0 RBI", for: .normal)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        rbiButton.isHidden = true
        checkmarkImageView.isHidden = true
        iconImageView.isHidden = true
        rbiButton.setTitle("0 RBI", for: .normal)
        onRBISelection = nil
    }
}

struct AtBatOption {
    let title: String
    let showRBIButton: Bool
    let type: AtBatOptionType
    
    init(option: AtBatOptionType) {
        title = option.rawValue
        showRBIButton = option == .rbi
        type = option
    }
    
    enum AtBatOptionType: String, CaseIterable {
        case outAtFirst = "Out at First"
        case single = "Single"
        case double = "Double"
        case triple = "Triple"
        case foulBall = "Foul Ball"
        case homeRun = "Home Run"
        case rbi = "RBI"
        case flyOut = "Fly Out"
        case strikeout = "Strikeout"
        case walk = "Walk"
        
        var imageName: String {
            switch self {
            case .outAtFirst:
                return "oaf_icon"
            case .single:
                return "first_icon"
            case .double:
                return "second_icon"
            case .triple:
                return "third_icon"
            case .foulBall:
                return "foul_icon"
            case .homeRun:
                return "hr_icon"
            case .rbi:
                return "rbi_icon"
            case .flyOut:
                return "flyout_icon"
            case .strikeout:
                return "strikeout_icon"
            case .walk:
                return "walk_icon"
            }
        }
    }
}
