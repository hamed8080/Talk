//
//  TextKitStack.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 12/20/24.
//

import Foundation
import UIKit

public class TextKitStack {
    private var storage: NSTextStorage?
    private static let accent = UIColor(named: "accent") ?? .orange
    private static let textColor = UIColor(named: "text_primary") ?? .white
    
    public init() {}
    
    public func setup(_ text: String) {
        guard let mutableAttributedString = attributedString(text: text) else { return }
        let textStorage = NSTextStorage(attributedString: mutableAttributedString)
        
        // Create the layout manager
        let roundedBackgroundLayoutManager = RoundedBackgroundLayoutManager()
        
        // Create the text container with an explicit size (ensure it's sized)
        let textContainer = NSTextContainer(size: .zero) // Make sure this is sized appropriately for your content
        textContainer.layoutManager = roundedBackgroundLayoutManager // Attach the layout manager
        
        // Now associate the text container with the layout manager
        roundedBackgroundLayoutManager.addTextContainer(textContainer)
        
        // Add the layout manager to the text storage
        textStorage.addLayoutManager(roundedBackgroundLayoutManager)
        
        self.storage = textStorage
    }
    
    @MainActor
    public func layoutManagerOnMain() -> NSLayoutManager? {
        return layoutManager()
    }
    
    @MainActor
    public func textContainerOnMain() -> NSTextContainer? {
        layoutManager()?.textContainers.first
    }
    
    public func layoutManager() -> NSLayoutManager? {
        storage?.layoutManagers.first
    }
    
    public func textContainer() -> NSTextContainer? {
        layoutManager()?.textContainers.first
    }
    
    public func getRect(width: CGFloat) -> CGRect? {
        guard let lm = layoutManager(), let tc = textContainer() else { return nil }
        let size = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        lm.glyphRange(forBoundingRect: CGRect(origin: .zero, size: size), in: tc)
        let rect = lm.usedRect(for: tc)
        return rect
    }
    
    private func attributedString(text: String) -> NSAttributedString? {
        let text = text.replacingOccurrences(of: "```", with: "\n```\n")
        guard let mutableAttr = try? NSMutableAttributedString(string: text) else { return NSAttributedString() }
        let range = (text.startIndex..<text.endIndex)
        mutableAttr.addDefaultTextColor(TextKitStack.textColor)
        mutableAttr.addUserColor(TextKitStack.accent)
        mutableAttr.addLinkColor(UIColor(named: "text_secondary") ?? .gray)
        mutableAttr.addBold()
        mutableAttr.addItalic()
        mutableAttr.addStrikethrough()
        
        text.tripleGlyphRange().forEach { range in
            /// Hide triple ``` by making them clear
            let range = range.range
            mutableAttr.addAttribute(.foregroundColor, value: UIColor.clear, range: range)
            mutableAttr.addAttribute(.font, value: UIFont.systemFont(ofSize: 8), range: range)
        }
        
        return NSAttributedString(attributedString: mutableAttr)
    }
    
    public func updateText(text: String) {
        guard let attr = attributedString(text: text) else { return }
        storage?.setAttributedString(attr)
    }
}

fileprivate class RoundedBackgroundLayoutManager: NSLayoutManager {
    
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
        
        // Ensure the range exists
        guard let ranges = textStorage?.string.rangesOfTripleTicks() else { return }
        
        ranges.forEach { range in
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
        UIColor.lightGray.setFill()
        UIBezierPath(roundedRect: rect, cornerRadius: 4).fill()
        
        let leadingBarRect = CGRect(x: rect.minX, y: rect.minY + 2, width: 3, height: rect.height - 2)
        UIColor.orange.setFill()
        UIBezierPath(roundedRect: leadingBarRect, cornerRadius: 2).fill()
    }
}

fileprivate extension String {
    func rangesOfTripleTicks() -> [Range<String.Index>] {
        let ranges = nsRangesOfTripleTicks()
        return ranges.compactMap({ Range($0.range, in: self) })
    }
    
    func nsRangesOfTripleTicks() -> [NSTextCheckingResult] {
        let pattern = "```\n(.*?)\n```"
        let allRange = NSRange(location: 0, length: self.utf16.count)
        guard
            let regex = try? NSRegularExpression(pattern: pattern)
        else { return [] }
        let matches = regex.matches(in: self, range: allRange)
        return matches
    }
    
    func tripleGlyphRange() -> [NSTextCheckingResult] {
        let pattern = "```"
        let allRange = NSRange(location: 0, length: self.utf16.count)
        guard
            let regex = try? NSRegularExpression(pattern: pattern)
        else { return [] }
        let matches = regex.matches(in: self, range: allRange)
        return matches
    }
}
