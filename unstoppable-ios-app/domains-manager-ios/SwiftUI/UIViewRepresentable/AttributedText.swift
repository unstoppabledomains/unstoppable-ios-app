//
//  AttributedText.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 21.08.2023.
//

import SwiftUI

struct AttributedText: UIViewRepresentable {
    
    let attributesList: AttributesList
    var updatedAttributesList: [AttributesList]? = nil
    var flexibleWidth: Bool = true
    var flexibleHeight: Bool = true
    var width: CGFloat = UIScreen.main.bounds.width
    
    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        if flexibleWidth {
            label.setContentHuggingPriority(.defaultLow, for: .horizontal)
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }
        if flexibleHeight {
            label.setContentHuggingPriority(.defaultLow, for: .vertical)
            label.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        } else {
            label.setContentHuggingPriority(.required, for: .vertical)
        }
        label.preferredMaxLayoutWidth = width

        label.numberOfLines = 0
        
        return label
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.setAttributedTextWith(text: attributesList.text,
                                     font: attributesList.font,
                                     letterSpacing: attributesList.letterSpacing,
                                     underlineStyle: attributesList.underlineStyle,
                                     strikethroughStyle: attributesList.strikethroughStyle,
                                     strikethroughColor: attributesList.strikethroughColor,
                                     textColor: attributesList.textColor,
                                     alignment: attributesList.alignment,
                                     headIndent: attributesList.headIndent,
                                     firstLineHeadIndent: attributesList.firstLineHeadIndent,
                                     tailIndent: attributesList.tailIndent,
                                     lineHeight: attributesList.lineHeight,
                                     baselineOffset: attributesList.baselineOffset,
                                     paragraphSpacing: attributesList.paragraphSpacing,
                                     lineBreakMode: attributesList.lineBreakMode,
                                     link: attributesList.link,
                                     strokeColor: attributesList.strokeColor,
                                     strokeWidth: attributesList.strokeWidth)
        for attributesList in (updatedAttributesList ?? []) {
            uiView.updateAttributesOf(text: attributesList.text,
                                      withFont: attributesList.font,
                                      letterSpacing: attributesList.letterSpacing,
                                      underlineStyle: attributesList.underlineStyle,
                                      strikethroughStyle: attributesList.strikethroughStyle,
                                      strikethroughColor: attributesList.strikethroughColor,
                                      textColor: attributesList.textColor,
                                      alignment: attributesList.alignment,
                                      baselineOffset: attributesList.baselineOffset,
                                      headIndent: attributesList.headIndent,
                                      firstLineHeadIndent: attributesList.firstLineHeadIndent,
                                      tailIndent: attributesList.tailIndent,
                                      lineHeight: attributesList.lineHeight,
                                      paragraphSpacing: attributesList.paragraphSpacing,
                                      lineBreakMode: attributesList.lineBreakMode,
                                      link: attributesList.link,
                                      strokeColor: attributesList.strokeColor,
                                      strokeWidth: attributesList.strokeWidth)
        }
    }
    
    struct AttributesList {
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
    }
}
