//
//  EditableTextView.swift
//  ImageEditor
//
//  Created by Hamed Hosseini on 4/23/25.
//

import UIKit

final class EditableTextView: UITextView {
    var isEditingMode = false
    private var panGesture: UIPanGestureRecognizer!
    private var pinchGesture: UIPinchGestureRecognizer!
    private let toolbar = UIToolbar()
    public var fontSize: CGFloat = 24
    private var lineBackgroundColor: UIColor = .black // Default
    
    init() {
        super.init(frame: .zero, textContainer: nil)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        isScrollEnabled = false
        isUserInteractionEnabled = true
        backgroundColor = .clear
        textColor = .white
        font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        textAlignment = .center
 
        let fontDown = UIBarButtonItem(title: "A−", style: .plain, target: self, action: #selector(decreaseTextSize))
        let fontUp = UIBarButtonItem(title: "A+", style: .plain, target: self, action: #selector(increaseTextSize))
        let textColor = UIBarButtonItem(title: "Text Color", style: .plain, target: self, action: #selector(changeTextColor))
        let bgColor = UIBarButtonItem(title: "BG", style: .plain, target: self, action: #selector(changeBGColor))
        let done = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneTapped))
        let flexible = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [fontDown, fontUp, bgColor, textColor, flexible, done]
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        toolbar.sizeToFit()
        inputAccessoryView = toolbar
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
        
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinchGesture)
        
        delegate = self
        
        textContainer.lineFragmentPadding = 0
        textContainerInset = .zero
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard isEditingMode == false else { return } // Don't drag while typing
        let translation = gesture.translation(in: superview)
        center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
        gesture.setTranslation(.zero, in: superview)
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard isEditingMode == false else { return }
        transform = transform.scaledBy(x: gesture.scale, y: gesture.scale)
        gesture.scale = 1
    }
    
    @objc private func decreaseTextSize() {
        fontSize -= 1
        font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        adjustSizeToFitText()
        /// Force to update draw method to draw text background
        setNeedsDisplay()
    }
    
    @objc private func increaseTextSize() {
        fontSize += 1
        font = UIFont.systemFont(ofSize: fontSize, weight: .bold)
        adjustSizeToFitText()
        /// Force to update draw method to draw text background
        setNeedsDisplay()
    }
    
    @objc private func changeTextColor() {
        let alert = UIAlertController(title: "Pick Text Color", message: nil, preferredStyle: .actionSheet)
        Colors.allCases.filter{ $0.uiColor != .clear }.forEach { color in
            alert.addAction(UIAlertAction(title: color.name, style: .default) { [weak self] _ in
                self?.textColor = color.uiColor
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let topVC = topViewController(window?.rootViewController) {
            topVC.present(alert, animated: true)
        }
    }
    
    @objc private func changeBGColor() {
        let alert = UIAlertController(title: "Pick Background Color", message: nil, preferredStyle: .actionSheet)
        Colors.allCases.forEach { color in
            alert.addAction(UIAlertAction(title: color.name, style: .default) { [weak self] _ in
                self?.lineBackgroundColor = color.uiColor
                self?.setNeedsDisplay() // Force redraw
            })
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let topVC = topViewController(window?.rootViewController) {
            topVC.present(alert, animated: true)
        }
    }
    
    @objc private func doneTapped() {
        resignFirstResponder()
    }
    
    /// We should get the right view controller,
    /// unless we will get an error when we want to show any alerts.
    private func topViewController(_ rootViewController: UIViewController?) -> UIViewController? {
        if let presented = rootViewController?.presentedViewController {
            return topViewController(presented)
        }
        if let nav = rootViewController as? UINavigationController {
            return topViewController(nav.visibleViewController)
        }
        if let tab = rootViewController as? UITabBarController {
            return topViewController(tab.selectedViewController)
        }
        return rootViewController
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext(), let font = self.font else { return }
        context.saveGState()
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]
        
        let lines = text.components(separatedBy: .newlines)
        let lineHeight = font.lineHeight
        let paddingX: CGFloat = 12  // Horizontal padding around text
        let paddingY: CGFloat = 2   // Vertical padding around text
        
        var yOffset: CGFloat = paddingY / 2 // Start with half padding at top
        
        for line in lines {
            let lineSize = line.size(withAttributes: attributes)
            
            let xPosition: CGFloat
            switch textAlignment {
            case .center:
                xPosition = (bounds.width - lineSize.width) / 2 - paddingX / 2
            case .right:
                xPosition = bounds.width - lineSize.width - paddingX
            default: // .left and natural
                xPosition = paddingX / 2
            }
            
            let backgroundRect = CGRect(x: xPosition,
                                         y: yOffset,
                                         width: lineSize.width + paddingX,
                                         height: lineHeight + paddingY)
            
            let path = UIBezierPath(roundedRect: backgroundRect, cornerRadius: 4)
            lineBackgroundColor.setFill()
            path.fill()
            
            yOffset += lineHeight
        }
        
        context.restoreGState()
    }
}

extension EditableTextView: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        isEditingMode = true
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        isEditingMode = false
    }
    
    func textViewDidChange(_ textView: UITextView) {
        adjustSizeToFitText()
        /// Force to update draw method to draw text background
        setNeedsDisplay()
    }
    
    private func adjustSizeToFitText() {
        guard let font = font else { return }

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]

        let lines = text.components(separatedBy: .newlines)
        var maxWidth: CGFloat = 0
        let lineHeight = font.lineHeight
        let paddingX: CGFloat = 8  // little more horizontal breathing
        let paddingY: CGFloat = 8   // vertical padding

        for line in lines {
            let rect = (line as NSString).boundingRect(
                with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: lineHeight),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attributes,
                context: nil
            )
            maxWidth = max(maxWidth, rect.width)
        }

        if maxWidth == 0 {
            maxWidth = font.pointSize * 2
        }

        let totalHeight = CGFloat(max(lines.count, 1)) * (lineHeight + paddingY) // notice (+ paddingY) per line

        textContainer.size = CGSize(width: maxWidth + paddingX, height: totalHeight)
        bounds.size = CGSize(width: maxWidth + paddingX, height: totalHeight)
    }
}
