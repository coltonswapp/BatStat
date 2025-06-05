import UIKit

class InteractiveDiamondCell: UICollectionViewListCell {
    static let identifier = "InteractiveDiamondCell"
    
    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.secondarySystemGroupedBackground
        view.layer.cornerRadius = 12
        view.layer.cornerCurve = .continuous
        return view
    }()
    
    private let interactiveDiamondView: InteractiveDiamondView = {
        let view = InteractiveDiamondView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let heightSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0.5
        return slider
    }()
    
    private let heightLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Ball Height"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    var onHitRecorded: ((CGPoint, CGFloat) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(interactiveDiamondView)
        containerView.addSubview(heightLabel)
        containerView.addSubview(heightSlider)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -0),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -0),
            
            heightLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            heightLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            heightSlider.topAnchor.constraint(equalTo: heightLabel.bottomAnchor, constant: 8),
            heightSlider.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            heightSlider.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            interactiveDiamondView.topAnchor.constraint(equalTo: heightSlider.bottomAnchor, constant: 16),
            interactiveDiamondView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            interactiveDiamondView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            interactiveDiamondView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -0),
            interactiveDiamondView.heightAnchor.constraint(equalTo: interactiveDiamondView.widthAnchor, multiplier: 0.95)
        ])
    }
    
    private func setupActions() {
        heightSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
    }
    
    @objc private func sliderChanged() {
        interactiveDiamondView.updateHeight(to: CGFloat(heightSlider.value))
    }
    
    func configure() {
        // Configuration if needed
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        heightSlider.value = 0.5
        onHitRecorded = nil
    }
}
