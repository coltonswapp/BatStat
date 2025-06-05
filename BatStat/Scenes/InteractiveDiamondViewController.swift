//
//  InteractiveDiamondViewController.swift
//  BatStat
//
//  Created by Colton Swapp on 5/5/25.
//

import UIKit

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
        heightSlider.value = 0.5
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
    private let trajectoryLayer = TrajectoryLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
//        // Setup view styling
//        backgroundColor = .secondarySystemBackground
//        layer.cornerRadius = 18
        
        // Setup image view (bottom layer)
        imageView.image = UIImage(named: "diamond")
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Setup trajectory layer (top layer)
        trajectoryLayer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(trajectoryLayer)
        
        NSLayoutConstraint.activate([
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
        if let tapGesture = gesture as? UITapGestureRecognizer {
            let point = tapGesture.location(in: self)
            updateHit(to: point)
        } else if let panGesture = gesture as? UIPanGestureRecognizer {
            if panGesture.state == .began || panGesture.state == .changed {
                let point = panGesture.location(in: self)
                updateHit(to: point)
            }
        }
    }
    
    func updateHit(to point: CGPoint) {
        trajectoryLayer.updateHit(to: point)
    }
    
    func updateHeight(to newHeight: CGFloat) {
        trajectoryLayer.updateHeight(to: newHeight)
    }
}

// Separate view just for drawing trajectories
class TrajectoryLayer: UIView {
    private var hitEndPoint: CGPoint?
    private var height: CGFloat = 0.5 // 0...1, from slider
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false // Pass touches through to parent
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    func updateHit(to point: CGPoint) {
        hitEndPoint = point
        setNeedsDisplay()
    }
    
    func updateHeight(to newHeight: CGFloat) {
        height = newHeight
        setNeedsDisplay()
    }
    
    // Calculate home plate position
    private func getHomePlatePosition() -> CGPoint {
        // Position home plate at the bottom middle of the view with a 4-point inset
        return CGPoint(x: bounds.midX, y: bounds.maxY - 20)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let ctx = UIGraphicsGetCurrentContext(), let end = hitEndPoint else { return }
        
        // Get home plate position
        let home = getHomePlatePosition()
        
        // Draw hit trajectory
        // Shadow (flat) line - only if trajectory exists (height > 0)
        if height > 0.01 {
            ctx.beginPath()
            ctx.setStrokeColor(UIColor.black.withAlphaComponent(0.2).cgColor)
            ctx.setLineWidth(2)
            ctx.move(to: home)
            ctx.addLine(to: end)
            ctx.strokePath()
        }
        
        // Draw 'X' marker at landing spot
        let xSize: CGFloat = 5
        ctx.beginPath()
        ctx.setStrokeColor(UIColor.black.cgColor)
        ctx.setLineWidth(4)
        // First diagonal
        ctx.move(to: CGPoint(x: end.x - xSize, y: end.y - xSize))
        ctx.addLine(to: CGPoint(x: end.x + xSize, y: end.y + xSize))
        // Second diagonal
        ctx.move(to: CGPoint(x: end.x - xSize, y: end.y + xSize))
        ctx.addLine(to: CGPoint(x: end.x + xSize, y: end.y - xSize))
        ctx.strokePath()
        
        // Arc (height) line
        ctx.beginPath()
        ctx.setLineDash(phase: 0, lengths: [4, 8])
        ctx.setStrokeColor(UIColor.red.withAlphaComponent(0.3).cgColor)
        ctx.setLineWidth(4)
        ctx.setLineCap(.round)
        
        if height > 0.01 { // If height is greater than almost zero, draw a curve
            let control = CGPoint(
                x: (home.x + end.x)/2,
                y: min(home.y, end.y) - 100 * height // higher arc for higher slider
            )
            ctx.move(to: home)
            ctx.addQuadCurve(to: end, control: control)
        } else {
            // For ground balls (height near zero), just draw a straight line
            ctx.move(to: home)
            ctx.addLine(to: end)
        }
        
        ctx.strokePath()
    }
}

