//
//  SignTransactionDomainSelectionHeaderView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.01.2023.
//

import UIKit

final class SignTransactionDomainSelectionHeaderView: UIView {
    
    private let titleHeight: CGFloat = 24
    private let subheadHeight: CGFloat = 16
    private let subheadButtonsSpace: CGFloat = 4
    
    private var titleLabel: UILabel!
    private var subheadWhatIsButton: UDConfigurableButton!
    private var subheadMeanButton: UDConfigurableButton!
    var subheadPressedCallback: EmptyCallback?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let titleWidth = titleLabel.bounds.width
        let subheadWidth = subheadWhatIsButton.bounds.width + subheadMeanButton.bounds.width + subheadButtonsSpace
        
        let maxWidth = max(titleWidth, subheadWidth)
        bounds.size = CGSize(width: maxWidth,
                             height: titleHeight + subheadHeight)
        
        titleLabel.frame.origin = CGPoint(x: (maxWidth - titleWidth) / 2,
                                          y: 0)
        
        subheadWhatIsButton.frame.origin = CGPoint(x: (maxWidth - subheadWidth) / 2,
                                                   y: titleLabel.frame.maxY)
        subheadMeanButton.frame.origin = CGPoint(x: subheadWhatIsButton.frame.maxX + subheadButtonsSpace,
                                                 y: subheadWhatIsButton.frame.origin.y)
    }
    
}

// MARK: - Actions
private extension SignTransactionDomainSelectionHeaderView {
    @objc func subheadButtonPressed() {
        subheadPressedCallback?()
    }
}

// MARK: - Setup methods
private extension SignTransactionDomainSelectionHeaderView {
    func setup() {
        setupTitle()
        setupSubheadButtons()
        addContent()
    }
    
    func setupTitle() {
        titleLabel = UILabel()
        let title = String.Constants.selectNFTDomainTitle.localized()
        let font: UIFont = .currentFont(withSize: 16, weight: .semibold)
        titleLabel.setAttributedTextWith(text: title,
                                         font: font,
                                         textColor: .foregroundDefault)
        titleLabel.bounds.size = CGSize(width: title.width(withConstrainedHeight: titleHeight,
                                                           font: font),
                                        height: titleHeight)
        addSubview(titleLabel)
    }
    
    func setupSubheadButtons() {
        subheadWhatIsButton = buildSubheadButton()
        let font = subheadWhatIsButton.udConfiguration.font
        let whatIsTitle = String.Constants.whatDoesResolutionMeanWhat.localized()
        let height = whatIsTitle.height(withConstrainedWidth: .infinity, font: font)
        subheadWhatIsButton.setTitle(whatIsTitle, image: nil)
        subheadWhatIsButton.frame.size = CGSize(width: whatIsTitle.width(withConstrainedHeight: .infinity, font: font) ,
                                                height: height)

        subheadMeanButton = buildSubheadButton()
        let meanTitle = String.Constants.whatDoesResolutionMeanMean.localized()
        subheadMeanButton.setTitle(meanTitle, image: .reverseResolutionArrows12)
        subheadMeanButton.frame.size = CGSize(width: meanTitle.width(withConstrainedHeight: .infinity, font: font) + 20,
                                                height: height)
    }
    
    func buildSubheadButton() -> UDConfigurableButton {
        let button = UDConfigurableButton()
        button.setConfiguration(.verySmallGhostTertiaryButtonConfiguration)
        button.customImageEdgePadding = 0
        button.customTitleEdgePadding = 0
        button.titleLeftPadding = 0
        button.titleRightPadding = 0
        button.addTarget(self, action: #selector(subheadButtonPressed), for: .touchUpInside)
        addSubview(button)
        
        return button
    }
    
    func addContent() {
        
    }
}
