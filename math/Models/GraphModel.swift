import Foundation
import CoreGraphics

/// Represents a point on a graph with position and metadata
struct GraphPoint: Identifiable, Equatable {
    let id: UUID
    let x: Double
    let y: Double
    let label: String?
    let pointType: PointType
    
    enum PointType {
        case intercept
        case intersection
        case vertex
        case sample
    }
    
    init(x: Double, y: Double, label: String? = nil, pointType: PointType = .sample) {
        self.id = UUID()
        self.x = x
        self.y = y
        self.label = label
        self.pointType = pointType
    }
}

/// Represents a complete graph with functions and key points
struct Graph: Identifiable {
    let id: UUID
    let functions: [GraphFunction]
    let xRange: ClosedRange<Double>
    let yRange: ClosedRange<Double>
    let keyPoints: [GraphPoint]
    var animationProgress: Double = 0.0
    
    init(
        functions: [GraphFunction],
        xRange: ClosedRange<Double> = -10...10,
        yRange: ClosedRange<Double> = -10...10,
        keyPoints: [GraphPoint] = []
    ) {
        self.id = UUID()
        self.functions = functions
        self.xRange = xRange
        self.yRange = yRange
        self.keyPoints = keyPoints
    }
}

/// Represents a function to be graphed
struct GraphFunction: Identifiable, Equatable {
    let id: UUID
    let expression: Expression
    let color: String // SwiftUI color name
    let label: String?
    
    init(expression: Expression, color: String = "blue", label: String? = nil) {
        self.id = UUID()
        self.expression = expression
        self.color = color
        self.label = label
    }
    
    static func == (lhs: GraphFunction, rhs: GraphFunction) -> Bool {
        lhs.id == rhs.id
    }
}

/// Represents zoom and pan state for graph viewing
struct GraphViewState: Equatable {
    var xRange: ClosedRange<Double> = -10...10
    var yRange: ClosedRange<Double> = -10...10
    var zoomLevel: Double = 1.0
    var panOffset: CGPoint = .zero
    
    mutating func zoom(by factor: Double) {
        zoomLevel *= factor
        // Clamp zoom to reasonable values
        zoomLevel = max(0.5, min(zoomLevel, 5.0))
        
        let xWidth = xRange.upperBound - xRange.lowerBound
        let yHeight = yRange.upperBound - yRange.lowerBound
        
        let newXWidth = xWidth / factor
        let newYHeight = yHeight / factor
        
        let xCenter = (xRange.lowerBound + xRange.upperBound) / 2
        let yCenter = (yRange.lowerBound + yRange.upperBound) / 2
        
        xRange = (xCenter - newXWidth / 2)...(xCenter + newXWidth / 2)
        yRange = (yCenter - newYHeight / 2)...(yCenter + newYHeight / 2)
    }
    
    mutating func pan(by offset: CGPoint, viewSize: CGSize) {
        let xRange_ = xRange
        let yRange_ = yRange
        
        let xShift = -(offset.x / viewSize.width) * (xRange_.upperBound - xRange_.lowerBound)
        let yShift = (offset.y / viewSize.height) * (yRange_.upperBound - yRange_.lowerBound)
        
        xRange = (xRange_.lowerBound + xShift)...(xRange_.upperBound + xShift)
        yRange = (yRange_.lowerBound + yShift)...(yRange_.upperBound + yShift)
    }
}
