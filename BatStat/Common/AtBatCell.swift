import UIKit

class AtBatCell: UICollectionViewCell {
    static let identifier = "AtBatCell"
    
    var onPreviousPlayer: (() -> Void)?
    var onNextPlayer: (() -> Void)?
    var onAtBatTapped: (() -> Void)?
    var onInningIncrement: (() -> Void)?
    var onInningDecrement: (() -> Void)?
    
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
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 16
        return stackView
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
        
        // Add buttons and player label to horizontal stack
        stackView.addArrangedSubview(previousButton)
        stackView.addArrangedSubview(playerLabel)
        stackView.addArrangedSubview(nextButton)
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            // Button constraints
            previousButton.widthAnchor.constraint(equalToConstant: 40),
            previousButton.heightAnchor.constraint(equalToConstant: 40),
            nextButton.widthAnchor.constraint(equalToConstant: 40),
            nextButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Stack view constraints
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
        ])
        
        // Player label should expand to fill available space
        playerLabel.setContentHuggingPriority(UILayoutPriority(249), for: .horizontal)
    }
    
    private func setupActions() {
        previousButton.addTarget(self, action: #selector(previousButtonTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextButtonTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        addGestureRecognizer(tapGesture)
        
        // Add context menu interaction for inning control
        let contextMenuInteraction = UIContextMenuInteraction(delegate: self)
        addInteraction(contextMenuInteraction)
    }
    
    func configure(with player: Player) {
        let displayName = "#\(player.number ?? 0) \(player.name)"
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
        onInningIncrement = nil
        onInningDecrement = nil
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.alpha = self.isHighlighted ? 0.8 : 1.0
            }
        }
    }
}

// MARK: - UIContextMenuInteractionDelegate

extension AtBatCell: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            let incrementAction = UIAction(
                title: "Next Inning",
                image: UIImage(systemName: "plus.circle"),
                handler: { [weak self] _ in
                    self?.onInningIncrement?()
                }
            )
            
            let decrementAction = UIAction(
                title: "Previous Inning",
                image: UIImage(systemName: "minus.circle"),
                handler: { [weak self] _ in
                    self?.onInningDecrement?()
                }
            )
            
            return UIMenu(title: "Inning Control", children: [incrementAction, decrementAction])
        }
    }
}
