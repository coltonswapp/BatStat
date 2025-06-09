import UIKit

// MARK: - Diamond Visualization Cell with Grid Support

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
    
    func configure(with hits: [Stat], selectedAtBatNumber: Int? = nil) {
        diamondView.plotHits(hits, selectedAtBatNumber: selectedAtBatNumber)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        diamondView.clearHits()
    }
}

// Read-only diamond view for visualization using grid system
class DiamondVisualizationView: UIView {
    private let imageView = UIImageView()
    private let gridLayer = VisualizationGridLayer()
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
        
        // Setup diamond image (bottom layer)
        imageView.image = UIImage(named: "diamond")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        
        // Setup grid overlay (middle layer) - hidden by default in visualization
        gridLayer.translatesAutoresizingMaskIntoConstraints = false
        gridLayer.backgroundColor = .clear
        addSubview(gridLayer)
        
        // Setup hits overlay (top layer)
        hitsLayer.translatesAutoresizingMaskIntoConstraints = false
        hitsLayer.backgroundColor = .clear
        addSubview(hitsLayer)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            gridLayer.topAnchor.constraint(equalTo: topAnchor),
            gridLayer.leadingAnchor.constraint(equalTo: leadingAnchor),
            gridLayer.trailingAnchor.constraint(equalTo: trailingAnchor),
            gridLayer.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            hitsLayer.topAnchor.constraint(equalTo: topAnchor),
            hitsLayer.leadingAnchor.constraint(equalTo: leadingAnchor),
            hitsLayer.trailingAnchor.constraint(equalTo: trailingAnchor),
            hitsLayer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func plotHits(_ hits: [Stat], selectedAtBatNumber: Int? = nil) {
        hitsLayer.plotHits(hits, selectedAtBatNumber: selectedAtBatNumber)
    }
    
    func clearHits() {
        hitsLayer.clearHits()
    }
    
    // For debugging - show/hide grid
    func setGridVisible(_ visible: Bool) {
        gridLayer.setGridVisible(visible)
    }
}

// MARK: - Grid Layer for Visualization (Usually Hidden)

class VisualizationGridLayer: UIView {
    private var isGridVisible = false // Hidden by default in visualization mode
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard isGridVisible, let ctx = UIGraphicsGetCurrentContext() else { return }
        
        // Draw lighter grid for visualization mode
        ctx.setStrokeColor(UIColor.systemGray.withAlphaComponent(0.2).cgColor)
        ctx.setLineWidth(0.3)
        
        let gridSize = DiamondGrid.gridSize
        let stepX = bounds.width / CGFloat(gridSize)
        let stepY = bounds.height / CGFloat(gridSize)
        
        // Vertical lines
        for i in 0...gridSize {
            let x = CGFloat(i) * stepX
            ctx.move(to: CGPoint(x: x, y: 0))
            ctx.addLine(to: CGPoint(x: x, y: bounds.height))
        }
        
        // Horizontal lines
        for i in 0...gridSize {
            let y = CGFloat(i) * stepY
            ctx.move(to: CGPoint(x: 0, y: y))
            ctx.addLine(to: CGPoint(x: bounds.width, y: y))
        }
        
        ctx.strokePath()
    }
    
    func setGridVisible(_ visible: Bool) {
        isGridVisible = visible
        setNeedsDisplay()
    }
}

// MARK: - Updated Hits Drawing with Grid Support

class HitsDrawingView: UIView {
    private var hitStats: [Stat] = []
    private var selectedAtBatNumber: Int?
    private var displayLink: CADisplayLink?
    private var animationPhase: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        setupAnimation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        setupAnimation()
    }
    
    deinit {
        stopAnimation()
    }
    
    private func setupAnimation() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    private func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func updateAnimation() {
        // Decrement phase for reverse marching ants effect
        animationPhase -= 0.5 // Negative for reverse direction
        if animationPhase < 0 { // Reset when it goes negative
            animationPhase = 16 // Reset to 16 (4 + 12 from dash pattern)
        }
        setNeedsDisplay()
    }
    
    func plotHits(_ hits: [Stat], selectedAtBatNumber: Int? = nil) {
        // Filter for hits that have location data
        hitStats = hits.filter { $0.hitLocation != nil }
        self.selectedAtBatNumber = selectedAtBatNumber
        
        // Start animation only if we have a selected hit, stop otherwise
        if selectedAtBatNumber != nil {
            if displayLink?.isPaused == true {
                displayLink?.isPaused = false
            }
        } else {
            displayLink?.isPaused = true
        }
        
        setNeedsDisplay()
    }
    
    func clearHits() {
        hitStats = []
        displayLink?.isPaused = true
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        
        // Get home plate position using grid system
        let homePlateNormalized = DiamondGrid.getHomePlatePosition()
        let homePlateScreen = DiamondGrid.denormalizePoint(homePlateNormalized, in: bounds)
        
        // Draw hit trajectories and markers
        for (index, hit) in hitStats.enumerated() {
            guard let hitLocation = hit.hitLocation else { continue }
            
            // Use the normalized coordinates from the hit location
            let normalizedPoint = CGPoint(x: hitLocation.x, y: hitLocation.y)
            let screenPoint = DiamondGrid.denormalizePoint(normalizedPoint, in: bounds)
            
            let color = getHitColor(for: hit)
            let height = CGFloat(hitLocation.height)
            
            // Determine if this hit should be dimmed
            let shouldDim = selectedAtBatNumber != nil && hit.atBatNumber != selectedAtBatNumber
            let alpha: CGFloat = shouldDim ? 0.5 : 1.0
            
            
            // Draw shadow trajectory line (flat)
            if height > 0.01 {
                ctx.beginPath()
                ctx.setStrokeColor(UIColor.black.withAlphaComponent(0.1 * alpha).cgColor)
                ctx.setLineWidth(1.5)
                ctx.move(to: homePlateScreen)
                ctx.addLine(to: screenPoint)
                ctx.strokePath()
            }
            
            // Draw arc trajectory (height)
            ctx.beginPath()
            
            // Make selected hit have marching ants, others static dashed
            if selectedAtBatNumber != nil && hit.atBatNumber == selectedAtBatNumber {
                // Selected hit: animated dashed line with marching ants
                ctx.setLineDash(phase: animationPhase, lengths: [4, 12])
            } else {
                // Non-selected hits: static dashed line
                ctx.setLineDash(phase: 0, lengths: [4, 12])
            }
            
            ctx.setStrokeColor(color.withAlphaComponent(alpha).cgColor)
            ctx.setLineWidth(4)
            ctx.setLineCap(.round)
            
            if height > 0.01 {
                // Draw curved trajectory for fly balls
                let control = CGPoint(
                    x: (homePlateScreen.x + screenPoint.x) / 2,
                    y: min(homePlateScreen.y, screenPoint.y) - 40 * height // Smaller arc for visualization
                )
                ctx.move(to: homePlateScreen)
                ctx.addQuadCurve(to: screenPoint, control: control)
            } else {
                // Draw straight line for ground balls
                ctx.move(to: homePlateScreen)
                ctx.addLine(to: screenPoint)
            }
            ctx.strokePath()
            
            // Reset line dash for other drawing
            ctx.setLineDash(phase: 0, lengths: [])
            
            // Draw at-bat number label
            if let atBatNumber = hit.atBatNumber {
                drawAtBatLabel(ctx: ctx, number: atBatNumber, at: screenPoint, color: color, alpha: alpha)
            } else {
                // Fallback to simple dot if no at-bat number
                drawHitDot(ctx: ctx, at: screenPoint, color: color, alpha: alpha)
            }
        }
    }
    
    private func getHitColor(for hit: Stat) -> UIColor {
        // Color-code hits based on type
        return hit.type.color
    }
    
    private func drawAtBatLabel(ctx: CGContext, number: Int, at point: CGPoint, color: UIColor, alpha: CGFloat) {
        let labelSize: CGFloat = 18
        let labelRect = CGRect(
            x: point.x - labelSize/2,
            y: point.y - labelSize/2,
            width: labelSize,
            height: labelSize
        )
        
        // Draw colored circle background with alpha
        ctx.setFillColor(color.withAlphaComponent(alpha).cgColor)
        ctx.fillEllipse(in: labelRect)
        
        // Draw white border with alpha
        ctx.setStrokeColor(UIColor.white.withAlphaComponent(alpha).cgColor)
        ctx.setLineWidth(1.5)
        ctx.strokeEllipse(in: labelRect)
        
        // Draw at-bat number
        let numberString = "\(number)"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11, weight: .bold),
            .foregroundColor: UIColor.white.withAlphaComponent(alpha)
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
    
    private func drawHitDot(ctx: CGContext, at point: CGPoint, color: UIColor, alpha: CGFloat) {
        let dotSize: CGFloat = 8
        let dotRect = CGRect(
            x: point.x - dotSize/2,
            y: point.y - dotSize/2,
            width: dotSize,
            height: dotSize
        )
        
        ctx.setFillColor(color.withAlphaComponent(alpha).cgColor)
        ctx.fillEllipse(in: dotRect)
        
        ctx.setStrokeColor(UIColor.white.withAlphaComponent(alpha).cgColor)
        ctx.setLineWidth(1)
        ctx.strokeEllipse(in: dotRect)
    }
}
