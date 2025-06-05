import UIKit

class DiamondVisualizationCell: UICollectionViewListCell {
    static let identifier = "DiamondVisualizationCell"
    
    private let diamondView: DiamondVisualizationView = {
        let view = DiamondVisualizationView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(diamondView)
        
        NSLayoutConstraint.activate([
            diamondView.topAnchor.constraint(equalTo: topAnchor, constant: 0),
            diamondView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0),
            diamondView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -0),
            diamondView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 0),
            diamondView.heightAnchor.constraint(equalTo: diamondView.widthAnchor, multiplier: 1.0) // Maintain aspect ratio
        ])
    }
    
    func configure(with hits: [Stat]) {
        diamondView.plotHits(hits)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        diamondView.clearHits()
    }
}

// Read-only diamond view for visualization
class DiamondVisualizationView: UIView {
    private let imageView = UIImageView()
    private let hitsLayer = HitsDrawingView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = UIColor.secondarySystemGroupedBackground
        layer.cornerRadius = 12
        layer.cornerCurve = .continuous
        
        // Setup diamond image
        imageView.image = UIImage(named: "diamond")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        
        // Setup hits overlay
        hitsLayer.translatesAutoresizingMaskIntoConstraints = false
        hitsLayer.backgroundColor = .clear
        addSubview(hitsLayer)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            hitsLayer.topAnchor.constraint(equalTo: topAnchor),
            hitsLayer.leadingAnchor.constraint(equalTo: leadingAnchor),
            hitsLayer.trailingAnchor.constraint(equalTo: trailingAnchor),
            hitsLayer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func plotHits(_ hits: [Stat]) {
        hitsLayer.plotHits(hits)
    }
    
    func clearHits() {
        hitsLayer.clearHits()
    }
}

// Separate view for drawing hits
class HitsDrawingView: UIView {
    private var hitStats: [Stat] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }
    
    func plotHits(_ hits: [Stat]) {
        hitStats = hits.filter { $0.hitLocation != nil }
        setNeedsDisplay()
    }
    
    func clearHits() {
        hitStats = []
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        // Get home plate position (same as InteractiveDiamondViewController)
        let home = getHomePlatePosition()
        
        for hit in hitStats {
            guard let hitLocation = hit.hitLocation else { continue }
            
            let endPoint = hitLocation.toCGPoint(for: bounds.size)
            let color = UIColor.systemRed
            let height = CGFloat(hitLocation.height)
            
            // Draw shadow trajectory line (flat)
            ctx.beginPath()
            ctx.setStrokeColor(UIColor.black.withAlphaComponent(0.15).cgColor)
            ctx.setLineWidth(1)
            ctx.move(to: home)
            ctx.addLine(to: endPoint)
            ctx.strokePath()
            
            // Draw arc trajectory (height)
            ctx.beginPath()
            ctx.setLineDash(phase: 0, lengths: [3, 6])
            ctx.setStrokeColor(color.withAlphaComponent(0.8).cgColor)
            ctx.setLineWidth(2)
            ctx.setLineCap(.round)
            
            if height > 0.01 {
                // Draw curved trajectory for fly balls
                let control = CGPoint(
                    x: (home.x + endPoint.x) / 2,
                    y: min(home.y, endPoint.y) - 60 * height // Smaller arc for visualization
                )
                ctx.move(to: home)
                ctx.addQuadCurve(to: endPoint, control: control)
            } else {
                // Draw straight line for ground balls
                ctx.move(to: home)
                ctx.addLine(to: endPoint)
            }
            ctx.strokePath()
            
            // Reset line dash for other drawing
            ctx.setLineDash(phase: 0, lengths: [])
            
            // Draw at-bat number label instead of dot
            if let atBatNumber = hit.value {
                drawAtBatLabel(ctx: ctx, number: atBatNumber, at: endPoint, color: color)
            }
        }
    }
    
    private func getHomePlatePosition() -> CGPoint {
        // Position home plate at the bottom middle of the view with a 4-point inset
        return CGPoint(x: bounds.midX, y: bounds.maxY - 8)
    }
    
    private func drawAtBatLabel(ctx: CGContext, number: Int, at point: CGPoint, color: UIColor) {
        let labelSize: CGFloat = 20
        let labelRect = CGRect(
            x: point.x - labelSize/2,
            y: point.y - labelSize/2,
            width: labelSize,
            height: labelSize
        )
        
        // Draw colored circle background
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: labelRect)
        
        // Draw white border
        ctx.setStrokeColor(UIColor.white.cgColor)
        ctx.setLineWidth(2)
        ctx.strokeEllipse(in: labelRect)
        
        // Draw at-bat number
        let numberString = "\(number)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        
        let attributedString = NSAttributedString(string: numberString, attributes: attributes)
        let textSize = attributedString.size()
        let textRect = CGRect(
            x: point.x - textSize.width/2,
            y: point.y - textSize.height/2,
            width: textSize.width,
            height: textSize.height
        )
        
        attributedString.draw(in: textRect)
    }
    
}
