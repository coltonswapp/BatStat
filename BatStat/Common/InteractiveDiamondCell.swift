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
    
    private let heightSlider: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0.3 // Start with a more realistic ground ball default
        slider.minimumTrackTintColor = .systemBlue
        return slider
    }()
    
    var onHitRecorded: ((CGPoint, CGFloat) -> Void)?
    
    // Expose the interactive diamond view for coordinate calculations
    var interactiveDiamondView: InteractiveDiamondView {
        return _interactiveDiamondView
    }
    
    private let _interactiveDiamondView: InteractiveDiamondView = {
        let view = InteractiveDiamondView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        addSubview(containerView)
        containerView.addSubview(_interactiveDiamondView)
        containerView.addSubview(heightSlider)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -0),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -0),
            
            heightSlider.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            heightSlider.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            heightSlider.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            
            _interactiveDiamondView.topAnchor.constraint(equalTo: heightSlider.bottomAnchor, constant: 16),
            _interactiveDiamondView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            _interactiveDiamondView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            _interactiveDiamondView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -0),
            _interactiveDiamondView.heightAnchor.constraint(equalTo: _interactiveDiamondView.widthAnchor, multiplier: 0.95)
        ])
    }
    
    private func setupActions() {
        heightSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        
        // Set up hit recording callback
        _interactiveDiamondView.onHitRecorded = { [weak self] point in
            guard let self = self else { return }
            let height = CGFloat(self.heightSlider.value)
            self.onHitRecorded?(point, height)
        }
    }
    
    @objc private func sliderChanged() {
        let height = CGFloat(heightSlider.value)
        _interactiveDiamondView.updateHeight(to: height)
    }
    
    func configure() {
        // TEMPORARY: Enable grid visibility for debugging (remove this later)
        _interactiveDiamondView.setGridVisible(true)
        
        // Re-set the callback in case it was cleared
        _interactiveDiamondView.onHitRecorded = { [weak self] point in
            guard let self = self else { return }
            let height = CGFloat(self.heightSlider.value)
            self.onHitRecorded?(point, height)
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        heightSlider.value = 0.3
        onHitRecorded = nil
    }
}
