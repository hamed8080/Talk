//
//  EditableTextView.swift
//  ImageEditor
//
//  Created by Hamed Hosseini on 4/23/25.
//

import UIKit
import Combine

final class EditableTextView: UITextView {
    var isEditingMode = false
    private var panGesture: UIPanGestureRecognizer!
    private var pinchGesture: UIPinchGestureRecognizer!
    private var rotationGesture: UIRotationGestureRecognizer!
    private var toolbar = UIView()
    private var toolbarContainer = UIView()
    public var fontSize: CGFloat = 24
    private var lineBackgroundColor: UIColor = .black // Default
    private var cancellable = Set<AnyCancellable>()
    private let btnTextColor = UIButton(type: .system)
    private let btnBgColor = UIButton(type: .system)
    
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
    
        let fontDown = UIButton(type: .system)
        fontDown.translatesAutoresizingMaskIntoConstraints = false
        fontDown.setTitle("A-", for: .normal)
        fontDown.addTarget(self, action: #selector(decreaseTextSize), for: .touchUpInside)
        fontDown.titleLabel?.font = UIFont.systemFont(ofSize: 22)
        
        let fontUp = UIButton(type: .system)
        fontUp.translatesAutoresizingMaskIntoConstraints = false
        fontUp.setTitle("A+", for: .normal)
        fontUp.addTarget(self, action: #selector(increaseTextSize), for: .touchUpInside)
        fontUp.titleLabel?.font = UIFont.systemFont(ofSize: 22)
        
        btnTextColor.translatesAutoresizingMaskIntoConstraints = false
        btnTextColor.setTitle("A", for: .normal)
        btnTextColor.addTarget(self, action: #selector(changeTextColor), for: .touchUpInside)
        btnTextColor.titleLabel?.font = UIFont.systemFont(ofSize: 22, weight: .heavy)
        btnTextColor.setTitleColor(.white, for: .normal)
        
        btnBgColor.translatesAutoresizingMaskIntoConstraints = false
        btnBgColor.setTitle("A", for: .normal)
        btnBgColor.addTarget(self, action: #selector(changeBGColor), for: .touchUpInside)
        btnBgColor.titleLabel?.font = UIFont.systemFont(ofSize: 22)
        btnBgColor.backgroundColor = .black
        btnBgColor.layer.cornerRadius = 4
        btnBgColor.clipsToBounds = true
        btnBgColor.setTitleColor(.white, for: .normal)
        
        let btnDone = UIButton(type: .system)
        btnDone.translatesAutoresizingMaskIntoConstraints = false
        btnDone.setTitle("Done", for: .normal)
        btnDone.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        btnDone.titleLabel?.font = UIFont.systemFont(ofSize: 22)
        
        toolbar = UIView(frame: .init(x: 0, y: 0, width: 400, height: 48 + 16))
        
        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.layer.cornerRadius = 8
        blurView.clipsToBounds = true
        blurView.frame = .init(x: 16, y: 0, width: 400 - 32, height: 48)
        
        toolbar.addSubview(blurView)
        toolbar.addSubview(toolbarContainer)
        
        toolbarContainer.addSubview(fontDown)
        toolbarContainer.addSubview(fontUp)
        toolbarContainer.addSubview(btnTextColor)
        toolbarContainer.addSubview(btnBgColor)
        toolbarContainer.addSubview(btnDone)
        inputAccessoryView = toolbar
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
        
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinchGesture)
        
        rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        rotationGesture.delegate = self
        addGestureRecognizer(rotationGesture)
        
        delegate = self
        
        textContainer.lineFragmentPadding = 0
        textContainerInset = .zero
        
        NSLayoutConstraint.activate([
            fontDown.topAnchor.constraint(equalTo: toolbarContainer.topAnchor, constant: 0),
            fontDown.leadingAnchor.constraint(equalTo: toolbarContainer.leadingAnchor, constant: 8),
            fontDown.heightAnchor.constraint(equalTo: toolbarContainer.heightAnchor),
            fontDown.widthAnchor.constraint(equalToConstant: 42),
            
            fontUp.topAnchor.constraint(equalTo: toolbarContainer.topAnchor, constant: 0),
            fontUp.leadingAnchor.constraint(equalTo: fontDown.trailingAnchor, constant: 8),
            fontUp.heightAnchor.constraint(equalTo: toolbarContainer.heightAnchor),
            fontUp.widthAnchor.constraint(equalToConstant: 42),
            
            btnTextColor.topAnchor.constraint(equalTo: toolbarContainer.topAnchor, constant: 0),
            btnTextColor.leadingAnchor.constraint(equalTo: fontUp.trailingAnchor, constant: 8),
            btnTextColor.heightAnchor.constraint(equalTo: toolbarContainer.heightAnchor),
            btnTextColor.widthAnchor.constraint(equalToConstant: 42),
            
            btnBgColor.centerYAnchor.constraint(equalTo: toolbarContainer.centerYAnchor, constant: 0),
            btnBgColor.leadingAnchor.constraint(equalTo: btnTextColor.trailingAnchor, constant: 8),
            btnBgColor.heightAnchor.constraint(equalTo: toolbarContainer.heightAnchor, constant: -16),
            btnBgColor.widthAnchor.constraint(equalToConstant: 42),
            
            btnDone.topAnchor.constraint(equalTo: toolbarContainer.topAnchor, constant: 0),
            btnDone.trailingAnchor.constraint(equalTo: toolbarContainer.trailingAnchor, constant: -8),
            btnDone.heightAnchor.constraint(equalTo: toolbarContainer.heightAnchor),
            btnDone.widthAnchor.constraint(equalToConstant: 72),
        ])
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] notif in
                if let self = self, let rect = notif.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    toolbar.frame.size.width = rect.width
                    blurView.frame.size.width = rect.width - 32
                    toolbarContainer.frame = blurView.frame
                }
            }
            .store(in: &cancellable)
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
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard isEditingMode == false else { return }
        transform = transform.rotated(by: gesture.rotation)
        gesture.rotation = 0
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
                self?.btnTextColor.setTitleColor(color.uiColor, for: .normal)
                self?.btnBgColor.setTitleColor(color.uiColor, for: .normal)
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
                self?.btnBgColor.backgroundColor = color.uiColor
                self?.btnBgColor.layer.borderColor = color == .clear ? UIColor.orange.cgColor : UIColor.clear.cgColor
                self?.btnBgColor.layer.borderWidth = color == .clear ? 1 : 0
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

extension EditableTextView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
