//
//  DiamondGrid.swift
//  BatStat
//
//  Created by Colton Swapp on 5/5/25.
//

import UIKit

// MARK: - Grid System for Accurate Hit Positioning

/// Defines the standardized grid system for the baseball diamond
/// This ensures hits are recorded and displayed consistently across different screen sizes
struct DiamondGrid {
    static let gridSize = 40 // 40x40 grid for higher precision positioning
    static let fieldBounds = CGRect(x: 0, y: 0, width: 1, height: 1) // Normalized 0-1 coordinates
    
    /// Convert a screen point to normalized grid coordinates (0-1)
    static func normalizePoint(_ point: CGPoint, in viewBounds: CGRect) -> CGPoint {
        return CGPoint(
            x: point.x / viewBounds.width,
            y: point.y / viewBounds.height
        )
    }
    
    /// Convert normalized grid coordinates back to screen coordinates
    static func denormalizePoint(_ normalizedPoint: CGPoint, in viewBounds: CGRect) -> CGPoint {
        return CGPoint(
            x: normalizedPoint.x * viewBounds.width,
            y: normalizedPoint.y * viewBounds.height
        )
    }
    
    /// Snap a normalized point to the nearest grid intersection
    static func snapToGrid(_ normalizedPoint: CGPoint) -> CGPoint {
        let gridStepX = 1.0 / Double(gridSize)
        let gridStepY = 1.0 / Double(gridSize)
        
        let snappedX = round(normalizedPoint.x / gridStepX) * gridStepX
        let snappedY = round(normalizedPoint.y / gridStepY) * gridStepY
        
        return CGPoint(x: snappedX, y: snappedY)
    }
    
    /// Get the normalized position of home plate (bottom center with inset)
    static func getHomePlatePosition() -> CGPoint {
        return CGPoint(x: 0.5, y: 0.95) // Bottom center with 5% inset
    }
    
    /// Check if a normalized point is within the valid field bounds
    static func isValidFieldPosition(_ normalizedPoint: CGPoint) -> Bool {
        return normalizedPoint.x >= 0 && normalizedPoint.x <= 1 &&
               normalizedPoint.y >= 0 && normalizedPoint.y <= 1
    }
    
    /// Get grid step size for the current grid
    static func getGridStepSize() -> CGSize {
        return CGSize(
            width: 1.0 / Double(gridSize),
            height: 1.0 / Double(gridSize)
        )
    }
} 