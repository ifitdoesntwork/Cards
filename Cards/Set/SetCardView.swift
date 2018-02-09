//
//  CardView.swift
//  Set
//
//  Created by Denis Avdeev on 31.01.2018.
//  Copyright © 2018 Denis Avdeev. All rights reserved.
//

import UIKit

@IBDesignable
class SetCardView: UIView {

    private struct Constants {
        static let offsetRatio: CGFloat = 1 / 16
        static let radiusRatio: CGFloat = 1 / 6
        static let lineWidth: CGFloat = 2.0
        static let stripeToLineWidthRatio: CGFloat = 2.5
    }
    
    /// A property of the Set card; random by default.
    var number = SetCard.Number(rawValue: 3.arc4random)! { didSet { setNeedsDisplay() } }
    /// A property of the Set card; random by default.
    var symbol = SetCard.Symbol(rawValue: 3.arc4random)! { didSet { setNeedsDisplay() } }
    /// A property of the Set card; random by default.
    var shading = SetCard.Shading(rawValue: 3.arc4random)! { didSet { setNeedsDisplay() } }
    /// A property of the Set card; random by default.
    var color = SetCard.Color(rawValue: 3.arc4random)! { didSet { setNeedsDisplay() } }
    
    enum State {
        case facedown, deselected, selected, matched, mismatched
        
        /// The card's background color to be applied in the appropriate state.
        var backgroundColor: UIColor {
            switch self {
            case .facedown:
                return #colorLiteral(red: 1, green: 0.5212053061, blue: 1, alpha: 1)
            case .deselected:
                return #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            case .selected:
                return #colorLiteral(red: 0.9995340705, green: 0.988355577, blue: 0.4726552367, alpha: 1)
            case .matched:
                return #colorLiteral(red: 0.8321695924, green: 0.985483706, blue: 0.4733308554, alpha: 1)
            case .mismatched:
                return #colorLiteral(red: 0.9568627477, green: 0.6588235497, blue: 0.5450980663, alpha: 1)
            }
        }
    }
    
    /// The state of the card.
    var state: State = .facedown { didSet { setNeedsDisplay() } }
    /// Optional background color of selected card to use instead of the one defined in `State`.
    var selectionColor: UIColor? { didSet { setNeedsDisplay() } }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        isOpaque = false
        contentMode = .redraw
    }
    
    override func draw(_ rect: CGRect) {
        drawCard()
        if state != .facedown {
            drawSymbols()
        }
    }
    
    private func drawCard() {
        let card = UIBezierPath(roundedRect: bounds, cornerRadius: min(bounds.width, bounds.height) * Constants.radiusRatio)
        card.addClip()
        let background = (state == .selected && selectionColor != nil) ? selectionColor! : state.backgroundColor
        background.setFill()
        card.fill()
    }
    
    private func drawSymbols() {
        let symbolWidth = bounds.width * (1 - 6 * Constants.offsetRatio)
        let symbolHeight = bounds.height * (1 - 8 * Constants.offsetRatio) / 3
        let cgNumber = CGFloat(number.rawValue)
        let symbolsHeight = (cgNumber + 1) * symbolHeight + cgNumber * 2 * Constants.offsetRatio * bounds.height
        let xOffset = bounds.width * Constants.offsetRatio * 3
        let yOffset = (bounds.height - symbolsHeight) / 2
        (0...number.rawValue).forEach { index in
            let frame = CGRect(x: xOffset,
                               y: yOffset + CGFloat(index) * (symbolHeight + 2 * Constants.offsetRatio * bounds.height),
                               width: symbolWidth,
                               height: symbolHeight
            )
            let path = symbol(enclosedIn: frame)
            let color: UIColor
            switch self.color {
            case .red:
                color = #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1)
            case .green:
                color = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 1)
            case .purple:
                color = #colorLiteral(red: 0.5791940689, green: 0.1280144453, blue: 0.5726861358, alpha: 1)
            }
            color.setStroke()
            path.lineWidth = Constants.lineWidth
            path.stroke()
            switch shading {
            case .solid:
                color.setFill()
                path.fill()
            case .striped:
                UIGraphicsGetCurrentContext()?.saveGState()
                path.addClip()
                let stripeStepWidth = path.lineWidth * Constants.stripeToLineWidthRatio
                (0...Int(symbolWidth / stripeStepWidth)).forEach { step in
                    let stepOriginX = frame.origin.x + CGFloat(step) * stripeStepWidth
                    path.move(to: CGPoint(x: stepOriginX, y: bounds.origin.y))
                    path.addLine(to: CGPoint(x: stepOriginX, y: bounds.maxY))
                }
                path.stroke()
                UIGraphicsGetCurrentContext()?.restoreGState()
            case .open:
                break
            }
        }
    }
    
    private func symbol(enclosedIn frame: CGRect) -> UIBezierPath {
        let path: UIBezierPath
        switch symbol {
        case .diamond:
            path = UIBezierPath()
            path.move(to: CGPoint(x: frame.origin.x, y: frame.midY))
            path.addLine(to: CGPoint(x: frame.midX, y: frame.origin.y))
            path.addLine(to: CGPoint(x: frame.maxX, y: frame.midY))
            path.addLine(to: CGPoint(x: frame.midX, y: frame.maxY))
            path.close()
        case .squiggle:
            let axisOffset = frame.height / 2
            path = UIBezierPath()
            path.move(to: CGPoint(x: frame.origin.x, y: frame.midY - axisOffset))
            path.addCurve(to: CGPoint(x: frame.maxX, y: frame.midY - axisOffset),
                          controlPoint1: CGPoint(x: frame.midX, y: frame.origin.y - axisOffset),
                          controlPoint2: CGPoint(x: frame.midX, y: frame.maxY - axisOffset)
            )
            path.addLine(to: CGPoint(x: frame.maxX, y: frame.midY + axisOffset))
            path.addCurve(to: CGPoint(x: frame.origin.x, y: frame.midY + axisOffset),
                          controlPoint1: CGPoint(x: frame.midX, y: frame.maxY + axisOffset),
                          controlPoint2: CGPoint(x: frame.midX, y: frame.origin.y + axisOffset)
            )
            path.close()
        case .oval:
            path = UIBezierPath(ovalIn: frame)
        }
        return path
    }

}
