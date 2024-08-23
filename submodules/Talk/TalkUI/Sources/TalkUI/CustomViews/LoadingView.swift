//
//  LoadingView.swift
//  TalkUI
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI

public struct LoadingView: View {
    @State public var isAnimating: Bool = true
    public var width: CGFloat = 2
    public var color: Color = .orange

    public init(isAnimating: Bool = false, width: CGFloat = 2, color: Color = Color.App.accent) {
        self.isAnimating = isAnimating
        self.width = width
        self.color = color
    }

    public var body: some View {
        GeometryReader { reader in
            Circle()
                .trim(from: 0, to: $isAnimating.wrappedValue ? 1 : 0.1)
                .stroke(style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round, miterLimit: 10))
                .fill(AngularGradient(colors: [color, .random, .random, .teal], center: .top))
                .frame(width: reader.size.width, height: reader.size.height)
                .rotationEffect(Angle(degrees: $isAnimating.wrappedValue ? 360 : 0))
                .onAppear {
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 2).delay(0.05)) {
                            self.isAnimating.toggle()
                        }
                    }
                }
        }
    }
}

public final class UILoadingView: UIView {
    private var shapeLayer = CAShapeLayer()
    private var animation = CABasicAnimation(keyPath: "strokeEnd")
    private var rotateAnimation = CABasicAnimation(keyPath: "transform.rotation.z")

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
        drawProgress()
    }

    func drawProgress() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let path = UIBezierPath(arcCenter: center,
                                radius: bounds.width / 2,
                                startAngle: -CGFloat.pi / 2,
                                endAngle: 2 * CGFloat.pi,
                                clockwise: true)
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = Color.App.accentUIColor?.cgColor
        shapeLayer.lineWidth = 2
        shapeLayer.lineCap = .round
        shapeLayer.path = path.cgPath
        self.layer.addSublayer(shapeLayer)
    }

    public func animate(_ animate: Bool) {
        if animate {
            start()
        } else {
            stop()
        }
    }

    private func start() {
        animation.fromValue = 0.05
        animation.toValue = 0.8
        animation.duration = 1.5
        animation.autoreverses = true
        animation.repeatCount = .greatestFiniteMagnitude
        rotateAnimation.repeatCount = .greatestFiniteMagnitude
        rotateAnimation.isCumulative = true
        rotateAnimation.toValue = 2 * CGFloat.pi
        rotateAnimation.duration = 0.8
        rotateAnimation.fillMode = .forwards

        shapeLayer.add(animation, forKey: "strokeAnimation")
        layer.add(rotateAnimation, forKey: "rotationAnimation")
        isHidden = false
        shapeLayer.isHidden = false
    }

    private func stop() {
        shapeLayer.isHidden = true
        shapeLayer.removeAllAnimations()
        isHidden = true
    }
}

struct LoadingView_Previews: PreviewProvider {
    @State static var isAnimating = true

    static var previews: some View {
        if isAnimating {
            LoadingView(width: 3)
                .frame(width: 36, height: 36)
        } else {
            Color.App.accent
                .ignoresSafeArea()
        }
    }
}
