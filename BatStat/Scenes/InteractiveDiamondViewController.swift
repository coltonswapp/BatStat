//
//  InteractiveDiamondViewController.swift
//  BatStat
//
//  Created by Colton Swapp on 5/5/25.
//

import UIKit

// MARK: - Interactive Diamond for Recording Hit Locations

class InteractiveDiamondViewController: UIViewController {
    
    let interactiveDiamondView = InteractiveDiamondView()
    let heightSlider = UISlider()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.secondarySystemGroupedBackground
        
        title = "Tap or drag place a hit"
        
        // Interactive diamond view
        interactiveDiamondView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(interactiveDiamondView)
        
        NSLayoutConstraint.activate([
            interactiveDiamondView.heightAnchor.constraint(equalToConstant: view.frame.size.width),
            interactiveDiamondView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            interactiveDiamondView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            interactiveDiamondView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        setupSlider()
    }
    
    private func setupSlider() {
        // Configure the slider
        heightSlider.translatesAutoresizingMaskIntoConstraints = false
        heightSlider.minimumValue = 0
        heightSlider.maximumValue = 1
        heightSlider.value = 0.3
        heightSlider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        
        // Add to view
        view.addSubview(heightSlider)
        
        // Position vertical slider on right edge
        NSLayoutConstraint.activate([
            heightSlider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            heightSlider.widthAnchor.constraint(equalToConstant: view.frame.width * 0.8),
            heightSlider.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12)
        ])
    }
    
    @objc func sliderChanged() {
        interactiveDiamondView.updateHeight(to: CGFloat(heightSlider.value))
    }
}

class InteractiveDiamondView: UIView {
    private let imageView = UIImageView()
    private let gridLayer = GridVisualizationLayer()
    private let trajectoryLayer = TrajectoryLayer()
    
    // Callback for when a hit is recorded - now provides normalized coordinates
    var onHitRecorded: ((CGPoint) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        // Setup image view (bottom layer)
        imageView.image = UIImage(named: "diamond")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        
        // Setup grid visualization layer (middle layer) - visible during development
        gridLayer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(gridLayer)
        
        // Setup trajectory layer (top layer)
        trajectoryLayer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(trajectoryLayer)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            gridLayer.topAnchor.constraint(equalTo: topAnchor),
            gridLayer.leadingAnchor.constraint(equalTo: leadingAnchor),
            gridLayer.trailingAnchor.constraint(equalTo: trailingAnchor),
            gridLayer.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            trajectoryLayer.topAnchor.constraint(equalTo: topAnchor),
            trajectoryLayer.leadingAnchor.constraint(equalTo: leadingAnchor),
            trajectoryLayer.trailingAnchor.constraint(equalTo: trailingAnchor),
            trajectoryLayer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Setup gestures
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        addGestureRecognizer(tapGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        addGestureRecognizer(panGesture)
        
        // Enable user interaction
        isUserInteractionEnabled = true
    }
    
    @objc private func handleGesture(_ gesture: UIGestureRecognizer) {
        let screenPoint: CGPoint
        
        if let tapGesture = gesture as? UITapGestureRecognizer {
            screenPoint = tapGesture.location(in: self)
        } else if let panGesture = gesture as? UIPanGestureRecognizer {
            if panGesture.state == .began || panGesture.state == .changed {
                screenPoint = panGesture.location(in: self)
            } else {
                return
            }
        } else {
            return
        }
        
        // Convert to normalized grid coordinates
        let normalizedPoint = DiamondGrid.normalizePoint(screenPoint, in: bounds)
        let gridSnappedPoint = DiamondGrid.snapToGrid(normalizedPoint)
        
        // Convert back to screen coordinates for display
        let displayPoint = DiamondGrid.denormalizePoint(gridSnappedPoint, in: bounds)
        
        updateHit(to: displayPoint, normalizedPoint: gridSnappedPoint)
        
        // Callback with normalized coordinates for storage
        onHitRecorded?(gridSnappedPoint)
    }
    
    func updateHit(to screenPoint: CGPoint, normalizedPoint: CGPoint) {
        trajectoryLayer.updateHit(to: screenPoint, normalizedPoint: normalizedPoint)
    }
    
    func updateHeight(to height: CGFloat) {
        trajectoryLayer.updateHeight(to: height)
    }
    
    // For debugging - show/hide grid
    func setGridVisible(_ visible: Bool) {
        gridLayer.setGridVisible(visible)
    }
}

// MARK: - Grid Visualization Layer (Visible during development)

class GridVisualizationLayer: UIView {
    private var isGridVisible = true // Set to false to hide grid
    
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
        
        // Draw grid lines
        ctx.setStrokeColor(UIColor.systemBlue.withAlphaComponent(0.3).cgColor)
        ctx.setLineWidth(0.5)
        
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
        
        // Draw home plate position
        let homePlateNormalized = DiamondGrid.getHomePlatePosition()
        let homePlateScreen = DiamondGrid.denormalizePoint(homePlateNormalized, in: bounds)
        
        ctx.setFillColor(UIColor.systemRed.cgColor)
        let plateSize: CGFloat = 6
        ctx.fillEllipse(in: CGRect(
            x: homePlateScreen.x - plateSize/2,
            y: homePlateScreen.y - plateSize/2,
            width: plateSize,
            height: plateSize
        ))
        
        // Draw grid coordinates for debugging
        ctx.setFillColor(UIColor.systemBlue.withAlphaComponent(0.7).cgColor)
        let font = UIFont.systemFont(ofSize: 8)
        
        for i in 0...4 { // Show coordinates every 5 grid points
            for j in 0...4 {
                let gridX = i * (gridSize / 4)
                let gridY = j * (gridSize / 4)
                let screenX = CGFloat(gridX) * stepX
                let screenY = CGFloat(gridY) * stepY
                
                let coordText = "\(gridX),\(gridY)"
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: UIColor.systemBlue
                ]
                
                coordText.draw(at: CGPoint(x: screenX + 2, y: screenY + 2), withAttributes: attributes)
            }
        }
    }
    
    func setGridVisible(_ visible: Bool) {
        isGridVisible = visible
        setNeedsDisplay()
    }
}

// MARK: - Updated Trajectory Layer with Grid Support

class TrajectoryLayer: UIView {
    private var hitScreenPoint: CGPoint?
    private var hitNormalizedPoint: CGPoint?
    private var height: CGFloat = 0.5
    
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
    
    func updateHit(to screenPoint: CGPoint, normalizedPoint: CGPoint) {
        hitScreenPoint = screenPoint
        hitNormalizedPoint = normalizedPoint
        setNeedsDisplay()
    }
    
    func updateHeight(to newHeight: CGFloat) {
        height = newHeight
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let ctx = UIGraphicsGetCurrentContext(),
              let screenEnd = hitScreenPoint,
              let normalizedEnd = hitNormalizedPoint else { return }
        
        // Get home plate position using grid system
        let homePlateNormalized = DiamondGrid.getHomePlatePosition()
        let homePlateScreen = DiamondGrid.denormalizePoint(homePlateNormalized, in: bounds)
        
        // Draw shadow trajectory line (flat)
        if height > 0.01 {
            ctx.beginPath()
            ctx.setStrokeColor(UIColor.black.withAlphaComponent(0.2).cgColor)
            ctx.setLineWidth(2)
            ctx.move(to: homePlateScreen)
            ctx.addLine(to: screenEnd)
            ctx.strokePath()
        }
        
        // Draw 'X' marker at landing spot
        let xSize: CGFloat = 8
        ctx.beginPath()
        ctx.setStrokeColor(UIColor.systemRed.cgColor)
        ctx.setLineWidth(3)
        // First diagonal
        ctx.move(to: CGPoint(x: screenEnd.x - xSize, y: screenEnd.y - xSize))
        ctx.addLine(to: CGPoint(x: screenEnd.x + xSize, y: screenEnd.y + xSize))
        // Second diagonal
        ctx.move(to: CGPoint(x: screenEnd.x - xSize, y: screenEnd.y + xSize))
        ctx.addLine(to: CGPoint(x: screenEnd.x + xSize, y: screenEnd.y - xSize))
        ctx.strokePath()
        
        // Draw trajectory arc
        ctx.beginPath()
        ctx.setLineDash(phase: 0, lengths: [4, 8])
        ctx.setStrokeColor(UIColor.systemRed.withAlphaComponent(0.7).cgColor)
        ctx.setLineWidth(3)
        ctx.setLineCap(.round)
        
        if height > 0.01 {
            let control = CGPoint(
                x: (homePlateScreen.x + screenEnd.x) / 2,
                y: min(homePlateScreen.y, screenEnd.y) - 80 * height
            )
            ctx.move(to: homePlateScreen)
            ctx.addQuadCurve(to: screenEnd, control: control)
        } else {
            ctx.move(to: homePlateScreen)
            ctx.addLine(to: screenEnd)
        }
        
        ctx.strokePath()
        
        // Draw coordinate info for debugging
        let coordText = String(format: "Grid: (%.2f, %.2f)", normalizedEnd.x, normalizedEnd.y)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: UIColor.systemRed,
            .backgroundColor: UIColor.white.withAlphaComponent(0.8)
        ]
        
        coordText.draw(at: CGPoint(x: screenEnd.x + 10, y: screenEnd.y - 20), withAttributes: attributes)
    }
}

