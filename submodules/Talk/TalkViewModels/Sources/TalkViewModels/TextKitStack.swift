//
//  TextKitStack.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 12/20/24.
//

import Foundation
#if canImport(UIKit)
import UIKit

public class TextKitStack {
    private var storage: NSTextStorage?
    public let roundedBackgroundLayoutManager = RoundedBackgroundLayoutManager()
    
    public init(attributedString: NSAttributedString) {
        let textStorage = NSTextStorage(attributedString: attributedString)
        
        // Create the text container with an explicit size (ensure it's sized)
        let textContainer = NSTextContainer(size: .zero) // Make sure this is sized appropriately for your content
        textContainer.layoutManager = roundedBackgroundLayoutManager // Attach the layout manager
        
        // Now associate the text container with the layout manager
        roundedBackgroundLayoutManager.addTextContainer(textContainer)
        
        // Add the layout manager to the text storage
        textStorage.addLayoutManager(roundedBackgroundLayoutManager)
        
        self.storage = textStorage
    }
    
    public var textContainer: NSTextContainer? {
        storage?.layoutManagers.first?.textContainers.first
    }
}

public class RoundedBackgroundLayoutManager: NSLayoutManager {
    public var ranges: [Range<String.Index>]?
    private let barColor = UIColor(named: "accent") ?? .orange
    private let bgColor = UIColor(named: "bg_chat_me_dark") ?? .white
    
    public override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
        ranges?.forEach { range in
            let range = NSRange(range, in: textStorage?.string ?? "")
            drawCodeBackground(range, origin)
        }
    }
    
    private func drawCodeBackground(_ range: NSRange, _ origin: CGPoint) {
        // Get the glyph range and bounding rect
        let glyphsRange = glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        guard let textContainer = textContainers.first else { return }
        
        // Calculate the bounding rectangle for the glyph range
        let boundingRect = boundingRect(forGlyphRange: glyphsRange, in: textContainer)
        
        // Offset the rect by the origin to align it properly
        let rect = boundingRect.offsetBy(dx: origin.x, dy: origin.y).insetBy(dx: -4, dy: -1)
        
        // Customize and draw the background rectangle
        bgColor.setFill()
        let bgPath = UIBezierPath(roundedRect: rect, cornerRadius: 4)
        bgPath.fill()

        barColor.setFill()
        let leadingBarRect = CGRect(x: rect.minX, y: rect.minY, width: 4, height: rect.height)
        let path = UIBezierPath(roundedRect: leadingBarRect, byRoundingCorners: [.topLeft, .bottomLeft], cornerRadii: .init(width: 4, height: 4))
        path.fill()
    }
}
#endif
