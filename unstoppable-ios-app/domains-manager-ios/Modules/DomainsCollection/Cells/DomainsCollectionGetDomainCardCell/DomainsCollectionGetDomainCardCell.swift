//
//  DomainsCollectionGetDomainCardCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.11.2023.
//

import UIKit

final class DomainsCollectionGetDomainCardCell: BaseDomainsCollectionCardCell {

    @IBOutlet private weak var udLogoImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var titleCollapsedLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var subtitleCollapsedLabel: UILabel!
    
    @IBOutlet private weak var actionContainerView: UIView!
    @IBOutlet private weak var actionLabel: UILabel!
    @IBOutlet private weak var actionImageView: UIImageView!
    
    private let defaultSideOffset: CGFloat = 16
    private let actionContainerHeight: CGFloat = 40

    override func awakeFromNib() {
        super.awakeFromNib()
        
        [titleLabel, titleCollapsedLabel].forEach { label in
            label?.numberOfLines = 0
            label?.setAttributedTextWith(text: String.Constants.getDomainCardTitle.localized().uppercased(),
                                        font: .helveticaNeueCustom(size: 56),
                                        letterSpacing: 0,
                                        textColor: .foregroundOnEmphasis,
                                        lineBreakMode: .byTruncatingTail)
        }
        
        [subtitleLabel, subtitleCollapsedLabel].forEach { label in
            label?.numberOfLines = 0
            label?.setAttributedTextWith(text: String.Constants.getDomainCardSubtitle.localized(),
                                         font: .currentFont(withSize: 16, weight: .medium),
                                         textColor: .foregroundOnEmphasis.withAlphaComponent(0.56),
                                         lineBreakMode: .byTruncatingTail)
        }
        
        let actionTitleText = String.Constants.findANewDomain.localized()
        actionContainerView.backgroundColor = .white
        actionContainerView.layer.cornerRadius = actionContainerHeight / 2
        actionLabel.setAttributedTextWith(text: actionTitleText,
                                          font: .currentFont(withSize: 16, weight: .medium),
                                          textColor: .black)
        actionLabel.frame.size.width = actionTitleText.width(withConstrainedHeight: .greatestFiniteMagnitude,
                                                             font: .currentFont(withSize: 16, weight: .medium))
        actionLabel.frame.size.height = 24
        actionImageView.frame.size = CGSize(width: 20, height: 20)
        actionImageView.tintColor = .black
        titleCollapsedLabel.alpha = 0
        subtitleCollapsedLabel.alpha = 0
    }
    
    override func setFrame(for state: BaseDomainsCollectionCardCell.CardState) {
        super.setFrame(for: state)
        
        setUDLogoViewFrame(for: state)
        setActionContainerFrame(for: state)
        setTitleFrame(for: state)
        setSubtitleFrame(for: state)
    }
    
}

// MARK: - UI Frame related methods
private extension DomainsCollectionGetDomainCardCell {
    func setUDLogoViewFrame(for state: CardState) {
        let udLogoSize: CGFloat = 56
        let udLogoSideOffset: CGFloat = defaultSideOffset
        let alpha: CGFloat
        switch state {
        case .expanded:
            alpha = 1
        case .collapsed:
            alpha = 0
        }
        udLogoImageView.frame = CGRect(origin: CGPoint(x: udLogoSideOffset,
                                                       y: udLogoSideOffset),
                                       size: CGSize(width: udLogoSize,
                                                    height: udLogoSize))
        udLogoImageView.alpha = alpha
    }
    
    func setTitleFrame(for state: CardState) {
        switch state {
        case .expanded:
            titleLabel.frame.origin = CGPoint(x: defaultSideOffset,
                                              y: udLogoImageView.frame.maxY + defaultSideOffset)
            titleLabel.frame.size.height = 138
            
            let maxDomainNameLabelWidth = containerView.frame.width - (defaultSideOffset * 2)
            titleLabel.frame.size.width = maxDomainNameLabelWidth
            titleLabel.alpha = 1
            titleCollapsedLabel.alpha = 0
        case .collapsed:
            let titleScale: CGFloat = 0.5
            titleCollapsedLabel.transform = .init(scaleX: titleScale, y: titleScale)
            titleCollapsedLabel.frame.origin = CGPoint(x: defaultSideOffset,
                                                       y: 14)
            titleCollapsedLabel.frame.size.height = 28
            let distanceToActionView: CGFloat = 8
            let domainNameMaxWidth = containerView.bounds.width - defaultSideOffset - (containerView.bounds.width - actionContainerView.frame.minX) - distanceToActionView
            titleCollapsedLabel.frame.size.width = domainNameMaxWidth
            titleLabel.alpha = 0
            titleCollapsedLabel.alpha = 1
        }
    }
    
    func setSubtitleFrame(for state: CardState) {
        switch state {
        case .expanded:
            subtitleLabel.frame.origin = CGPoint(x: titleLabel.frame.minX,
                                                 y: titleLabel.frame.maxY + defaultSideOffset)
            subtitleLabel.frame.size.height = 48
            
            subtitleLabel.frame.size.width = titleLabel.frame.width
            subtitleLabel.alpha = 1
            subtitleCollapsedLabel.alpha = 0
        case .collapsed:
            let subitleScale: CGFloat = 0.875
            subtitleCollapsedLabel.transform = .init(scaleX: subitleScale, y: subitleScale)
            subtitleCollapsedLabel.frame.origin = CGPoint(x: titleCollapsedLabel.frame.minX,
                                                          y: titleCollapsedLabel.frame.maxY + 4)
            subtitleCollapsedLabel.frame.size.height = 20
            
            subtitleCollapsedLabel.frame.size.width = titleCollapsedLabel.frame.width
            subtitleLabel.alpha = 0
            subtitleCollapsedLabel.alpha = 1
        }
    }
    
    func setActionContainerFrame(for state: CardState) {
        switch state {
        case .expanded:
            actionContainerView.frame = CGRect(x: defaultSideOffset,
                                               y: containerView.bounds.height - actionContainerHeight - defaultSideOffset,
                                               width: containerView.frame.width - (defaultSideOffset * 2),
                                               height: actionContainerHeight)
            
            let elementsSpacing: CGFloat = 8
            let elementsWidth = actionLabel.bounds.width + elementsSpacing + actionImageView.bounds.width
            actionLabel.frame.origin = CGPoint(x: (actionContainerView.bounds.width - elementsWidth) / 2,
                                               y: (actionContainerHeight - actionLabel.frame.height) / 2)
            actionLabel.alpha = 1
            actionImageView.frame.origin = CGPoint(x: actionLabel.frame.maxX + elementsSpacing,
                                                   y: (actionContainerHeight - actionImageView.frame.height) / 2)
        case .collapsed:
            actionContainerView.frame = CGRect(x: containerView.bounds.width - actionContainerHeight - defaultSideOffset,
                                               y: (containerView.bounds.height - actionContainerHeight) / 2,
                                               width: actionContainerHeight,
                                               height: actionContainerHeight)
            actionLabel.frame.origin.x = 0
            actionLabel.alpha = 0
            actionImageView.frame.origin = CGPoint(x: (actionContainerView.frame.width - actionImageView.frame.width) / 2,
                                                   y: (actionContainerHeight - actionImageView.frame.height) / 2)
        }
    }
}
