//
//  ObjectWithAttributedString.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.04.2022.
//

import UIKit

protocol ObjectWithAttributedString: AnyObject {
    var attributedString: NSAttributedString! { get set }
    var stringColor: UIColor? { get }
    var textFont: UIFont? { get }
    var textAlignment: NSTextAlignment { get }
    
    func setAttributedTextWith(text: String,
                               font: UIFont?,
                               letterSpacing: CGFloat?,
                               underlineStyle: NSUnderlineStyle?,
                               strikethroughStyle: NSUnderlineStyle?,
                               strikethroughColor: UIColor?,
                               textColor: UIColor?,
                               alignment: NSTextAlignment?,
                               headIndent: CGFloat?,
                               firstLineHeadIndent: CGFloat?,
                               tailIndent: CGFloat?,
                               lineHeight: CGFloat?,
                               baselineOffset: CGFloat?,
                               paragraphSpacing: CGFloat?,
                               lineBreakMode: NSLineBreakMode?,
                               link: String?,
                               strokeColor: UIColor?,
                               strokeWidth: CGFloat?)
    
    func updateAttributesOf(text: String,
                            withFont font: UIFont?,
                            letterSpacing: CGFloat?,
                            underlineStyle: NSUnderlineStyle?,
                            strikethroughStyle: NSUnderlineStyle?,
                            strikethroughColor: UIColor?,
                            textColor: UIColor?,
                            baselineOffset: CGFloat?,
                            headIndent: CGFloat?,
                            firstLineHeadIndent: CGFloat?,
                            tailIndent: CGFloat?,
                            lineHeight: CGFloat?,
                            originalText: String?,
                            paragraphSpacing: CGFloat?,
                            lineBreakMode: NSLineBreakMode?,
                            link: String?,
                            strokeColor: UIColor?,
                            strokeWidth: CGFloat?,
                            numberOfRepeatanceToUpdate: Int?)
}

extension ObjectWithAttributedString {
    func setAttributedTextWith(text: String,
                               font: UIFont? = nil,
                               letterSpacing: CGFloat? = nil,
                               underlineStyle: NSUnderlineStyle? = nil,
                               strikethroughStyle: NSUnderlineStyle? = nil,
                               strikethroughColor: UIColor? = nil,
                               textColor: UIColor? = nil,
                               alignment: NSTextAlignment? = nil,
                               headIndent: CGFloat? = nil,
                               firstLineHeadIndent: CGFloat? = nil,
                               tailIndent: CGFloat? = nil,
                               lineHeight: CGFloat? = nil,
                               baselineOffset: CGFloat? = nil,
                               paragraphSpacing: CGFloat? = nil,
                               lineBreakMode: NSLineBreakMode? = .byWordWrapping,
                               link: String? = nil,
                               strokeColor: UIColor? = nil,
                               strokeWidth: CGFloat? = nil) {
        let attributes = attributesFor(text: text,
                                       font: font,
                                       letterSpacing: letterSpacing,
                                       underlineStyle: underlineStyle,
                                       strikethroughStyle: strikethroughStyle,
                                       strikethroughColor: strikethroughColor,
                                       textColor: textColor,
                                       alignment: alignment,
                                       headIndent: headIndent,
                                       firstLineHeadIndent: firstLineHeadIndent,
                                       tailIndent: tailIndent,
                                       lineHeight: lineHeight,
                                       baselineOffset: baselineOffset,
                                       paragraphSpacing: paragraphSpacing,
                                       lineBreakMode: lineBreakMode,
                                       link: link,
                                       strokeColor: strokeColor,
                                       strokeWidth: strokeWidth)
        
        let attributedString = NSMutableAttributedString(string: text, attributes: attributes)
        
        self.attributedString = attributedString
    }
    
    func updateAttributesOf(text: String,
                            withFont font: UIFont? = nil,
                            letterSpacing: CGFloat? = nil,
                            underlineStyle: NSUnderlineStyle? = nil,
                            strikethroughStyle: NSUnderlineStyle? = nil,
                            strikethroughColor: UIColor? = nil,
                            textColor: UIColor? = nil,
                            baselineOffset: CGFloat? = nil,
                            headIndent: CGFloat? = nil,
                            firstLineHeadIndent: CGFloat? = nil,
                            tailIndent: CGFloat? = nil,
                            lineHeight: CGFloat? = nil,
                            originalText: String? = nil,
                            paragraphSpacing: CGFloat? = nil,
                            lineBreakMode: NSLineBreakMode? = nil,
                            link: String? = nil,
                            strokeColor: UIColor? = nil,
                            strokeWidth: CGFloat? = nil,
                            numberOfRepeatanceToUpdate: Int? = nil) {
        
        var originalTextRanges = [NSRange]()
        
        if let originalText = originalText {
            var dummyUpdatedText = ""
            for _ in 0..<text.count {
                dummyUpdatedText += "^"
            }
            let dummyText = originalText.replacingOccurrences(of: "%@", with: dummyUpdatedText)
            originalTextRanges = dummyText.ranges(of: text)
        }
        
        let originalTextRangesSet = Set(originalTextRanges)
        var ranges = (self.attributedString?.string.ranges(of: text) ?? []).filter({ !originalTextRangesSet.contains($0) })
        
        if let numberOfRepeatanceToUpdate {
            ranges = Array(ranges.prefix(numberOfRepeatanceToUpdate))
        }
        
        for range in ranges {
            if range.location == NSNotFound { continue }
            
            if let currentAttributedText = self.attributedString {
                let newAttributedText = NSMutableAttributedString(attributedString: currentAttributedText)
                let paragraphStyle: NSParagraphStyle? = currentAttributedText.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle
                let lineSpacing = lineHeight ?? paragraphStyle?.minimumLineHeight ?? 20.0
                let alignment = paragraphStyle?.alignment ?? textAlignment
                let lineBreakMode = paragraphStyle?.lineBreakMode ?? .byWordWrapping
                let newTextAttributes = attributesFor(text: currentAttributedText.string,
                                                      font: font,
                                                      letterSpacing: letterSpacing,
                                                      underlineStyle: underlineStyle,
                                                      strikethroughStyle: strikethroughStyle,
                                                      strikethroughColor: strikethroughColor,
                                                      textColor: textColor,
                                                      alignment: alignment,
                                                      headIndent: headIndent,
                                                      firstLineHeadIndent: firstLineHeadIndent,
                                                      tailIndent: tailIndent,
                                                      lineHeight: lineSpacing,
                                                      baselineOffset: baselineOffset,
                                                      paragraphSpacing: paragraphSpacing,
                                                      lineBreakMode: lineBreakMode,
                                                      link: link,
                                                      strokeColor: strokeColor,
                                                      strokeWidth: strokeWidth)
                
                newAttributedText.setAttributes(newTextAttributes, range: range)
                
                self.attributedString = newAttributedText
            }
        }
    }
}

private extension ObjectWithAttributedString {
    func attributesFor(text: String,
                       font: UIFont?,
                       letterSpacing: CGFloat?,
                       underlineStyle: NSUnderlineStyle?,
                       strikethroughStyle: NSUnderlineStyle?,
                       strikethroughColor: UIColor?,
                       textColor: UIColor?,
                       alignment: NSTextAlignment?,
                       headIndent: CGFloat?,
                       firstLineHeadIndent: CGFloat?,
                       tailIndent: CGFloat?,
                       lineHeight: CGFloat?,
                       baselineOffset: CGFloat?,
                       paragraphSpacing: CGFloat?,
                       lineBreakMode: NSLineBreakMode?,
                       link: String?,
                       strokeColor: UIColor?,
                       strokeWidth: CGFloat?) -> [NSAttributedString.Key: Any] {
        
        let textColorToUse: UIColor = textColor ?? (self.stringColor ?? .black)
        var attributes: [NSAttributedString.Key: Any] = [.foregroundColor: textColorToUse]
        if let font = font {
            attributes[.font] = font
        } else {
            attributes[.font] = self.textFont
        }
        if let letterSpacing = letterSpacing {
            attributes[.kern] = letterSpacing
        }
        if let underlineStyle = underlineStyle {
            attributes[.underlineStyle] = underlineStyle.rawValue
        }
        if let strikethroughStyle = strikethroughStyle {
            attributes[.strikethroughStyle] = strikethroughStyle.rawValue
        }
        if let strikethroughColor = strikethroughColor {
            attributes[.strikethroughColor] = strikethroughColor
        }
        let paragraphStyle = NSMutableParagraphStyle()
        if let alignment = alignment {
            paragraphStyle.alignment = alignment
        } else {
            paragraphStyle.alignment = self.textAlignment
        }
        
        if let lineBreakMode = lineBreakMode {
            paragraphStyle.lineBreakMode = lineBreakMode
        }
        
        if let lineHeight = lineHeight,
           lineHeight > 0 {
            paragraphStyle.minimumLineHeight = lineHeight
            paragraphStyle.maximumLineHeight = lineHeight
        }
        if let headIndent = headIndent {
            paragraphStyle.headIndent = headIndent
        }
        if let firstLineHeadIndent = firstLineHeadIndent {
            paragraphStyle.firstLineHeadIndent = firstLineHeadIndent
        }
        if let tailIndent = tailIndent {
            paragraphStyle.tailIndent = tailIndent
        }
        
        if let paragraphSpacing = paragraphSpacing {
            paragraphStyle.paragraphSpacing = paragraphSpacing
        }
        
        attributes[.paragraphStyle] = paragraphStyle
        
        if let link = link {
            attributes[.link] = link
        }
        
        if let baselineOffset = baselineOffset {
            attributes[.baselineOffset] = baselineOffset
        }
     
        if let strokeColor = strokeColor {
            attributes[.strokeColor] = strokeColor
        }
        if let strokeWidth = strokeWidth {
            attributes[.strokeWidth] = strokeWidth
        }
        
        return attributes
    }
}
