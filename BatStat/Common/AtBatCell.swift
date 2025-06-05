import UIKit

class AtBatCell: UICollectionViewCell {
    static let identifier = "AtBatCell"
    
    var onPreviousPlayer: (() -> Void)?
    var onNextPlayer: (() -> Void)?
    var onAtBatTapped: (() -> Void)?
    
    private let previousButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .systemBlue
        button.layer.cornerRadius = 14
        return button
    }()
    
    private let nextButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "chevron.right"), for: .normal)
        button.tintColor = .systemBlue
        button.layer.cornerRadius = 14
        return button
    }()
    
    private let playerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .label
        label.textAlignment = .center
        return label
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.secondarySystemGroupedBackground
        layer.cornerRadius = 12
        layer.cornerCurve = .continuous
        
        addSubview(previousButton)
        addSubview(nextButton)
        addSubview(playerLabel)
        
        NSLayoutConstraint.activate([
            // Previous button on left
            previousButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            previousButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            previousButton.widthAnchor.constraint(equalToConstant: 40),
            previousButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Next button on right
            nextButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            nextButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            nextButton.widthAnchor.constraint(equalToConstant: 40),
            nextButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Player label in center
            playerLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            playerLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            playerLabel.leadingAnchor.constraint(greaterThanOrEqualTo: previousButton.trailingAnchor, constant: 16),
            playerLabel.trailingAnchor.constraint(lessThanOrEqualTo: nextButton.leadingAnchor, constant: -16)
        ])
    }
    
    private func setupActions() {
        previousButton.addTarget(self, action: #selector(previousButtonTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        addGestureRecognizer(tapGesture)
    }
    
    func configure(with player: Player) {
        let displayName = "\(player.name) #\(player.number ?? 0)"
        playerLabel.text = displayName
    }
    
    @objc private func previousButtonTapped() {
        onPreviousPlayer?()
    }
    
    @objc private func nextButtonTapped() {
        onNextPlayer?()
    }
    
    @objc private func cellTapped() {
        onAtBatTapped?()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        playerLabel.text = nil
        onPreviousPlayer = nil
        onNextPlayer = nil
        onAtBatTapped = nil
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.alpha = self.isHighlighted ? 0.8 : 1.0
            }
        }
    }
}
