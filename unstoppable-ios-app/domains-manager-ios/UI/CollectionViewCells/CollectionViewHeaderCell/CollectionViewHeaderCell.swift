//
//  CollectionViewHeaderCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.06.2022.
//

import UIKit

final class CollectionViewHeaderCell: UICollectionViewCell {

    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subtitleLabel: UDSubtitleLabel!
    @IBOutlet private weak var iconView: KeepingAnimationImageView!
    @IBOutlet private weak var labelsStack: UIStackView!
    private var actionButton: UIButton?
    private var actionButtonCallback: EmptyCallback?
    
    func setTitle(_ title: String?, subtitleDescription: SubtitleDescription?, icon: UIImage?, buttonConfiguration: ActionButtonConfiguration? = nil) {
        titleLabel.setTitle(title ?? "")
        titleLabel.isHidden = title == nil
        subtitleLabel.isHidden = subtitleDescription == nil
        if let subtitle = subtitleDescription {
            subtitleLabel.setSubtitle(subtitle.subtitle)
            subtitleDescription?.attributes.forEach({ attribute in
                var font: UIFont?
                if let fontWeight = attribute.fontWeight {
                    font = .currentFont(withSize: subtitleLabel.font.pointSize,
                                        weight: fontWeight)
                }
                subtitleLabel.updateAttributesOf(text: attribute.text,
                                                 withFont: font,
                                                 textColor: attribute.textColor,
                                                 alignment: attribute.alignment)
            })
        }
        iconView.image = icon
        iconView.isHidden = icon == nil
        
        if let buttonConfiguration = buttonConfiguration {
            addActionButtonWithConfiguration(buttonConfiguration)
        }
    }

    func setRunningProgressAnimation() {
        iconView.runUpdatingRecordsAnimation()
    }
}

// MARK: - Private methods
private extension CollectionViewHeaderCell {
    func addActionButtonWithConfiguration(_ configuration: ActionButtonConfiguration) {
        removeActionButton()
        
        let actionButton = actionButtonForType(configuration.type)
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
        actionButton.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)
        actionButton.setTitle(configuration.title, image: configuration.image)
        actionButton.isUserInteractionEnabled = configuration.isEnabled
        self.actionButton = actionButton
        self.actionButtonCallback = configuration.action
        labelsStack.addArrangedSubview(actionButton)
    }
    
    func removeActionButton() {
        actionButton?.removeFromSuperview()
        actionButton = nil
        actionButtonCallback = nil
    }
    
    func actionButtonForType(_ type: ActionButtonType) -> BaseButton {
        let frame = CGRect(origin: .zero, size: CGSize(width: 100, height: 24))
        switch type {
        case .text(let isSuccess):
            let button = TextButton(frame: frame)
            button.isSuccess = isSuccess
            return button
        case .warning:
            let button = TextWarningButton(frame: frame)
            return button
        }
    }
    
    @objc func didTapActionButton() {
        actionButtonCallback?()
    }
}

extension CollectionViewHeaderCell {
    enum ActionButtonType {
        case text(isSuccess: Bool)
        case warning
    }
    
    struct ActionButtonConfiguration {
        let title: String?
        let image: UIImage?
        let type: ActionButtonType
        var action: EmptyCallback?
        var isEnabled: Bool
    }
    
    struct SubtitleDescription: Hashable {
        let subtitle: String
        var attributes: [Attributes] = []
        
        struct Attributes: Hashable {
            let text: String
            var fontWeight: UIFont.Weight? = nil
            var textColor: UIColor? = nil
            var alignment: NSTextAlignment = .left
        }
    }
}
