//
//  AttributedText.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 21.08.2023.
//

import SwiftUI

struct AttributedText: UIViewRepresentable {
    
    let text: String
    var font: UIFont? = nil
    var letterSpacing: CGFloat? = nil
    var underlineStyle: NSUnderlineStyle? = nil
    var strikethroughStyle: NSUnderlineStyle? = nil
    var strikethroughColor: UIColor? = nil
    var textColor: UIColor? = nil
    var alignment: NSTextAlignment? = nil
    var headIndent: CGFloat? = nil
    var firstLineHeadIndent: CGFloat? = nil
    var tailIndent: CGFloat? = nil
    var lineHeight: CGFloat? = nil
    var baselineOffset: CGFloat? = nil
    var paragraphSpacing: CGFloat? = nil
    var lineBreakMode: NSLineBreakMode? = nil
    var link: String? = nil
    var strokeColor: UIColor? = nil
    var strokeWidth: CGFloat? = nil
    
    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        return label
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.setAttributedTextWith(text: text,
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
    }
    
}
