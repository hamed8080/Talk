//
//  DrawingView.swift
//  ImageEditor
//
//  Created by Hamed Hosseini on 4/27/25.
//

import UIKit

class DrawingView: UIView {
    private var path = UIBezierPath()
    private var paths: [(path: UIBezierPath, color: UIColor)] = []
    private var currentColor = UIColor.red
    private var lineWidth: CGFloat = 3.0
    public var finished = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        isMultipleTouchEnabled = false
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !finished, let touch = touches.first else { return }
        let point = touch.location(in: self)
        path = UIBezierPath()
        path.lineWidth = lineWidth
        path.move(to: point)
        paths.append((path, currentColor))
        setNeedsDisplay()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !finished, let touch = touches.first else { return }
        let point = touch.location(in: self)
        path.addLine(to: point)
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        for (p, color) in paths {
            color.setStroke()
            p.stroke()
        }
    }
    
    public func setDrawingColor(color: UIColor) {
        currentColor = color
    }
    
    public func undo() {
        if paths.isEmpty { return }
        paths.removeLast()
        setNeedsDisplay()
    }
    
    public func reset() {
        paths.removeAll()
        path = UIBezierPath()
        setNeedsDisplay()
    }
}
