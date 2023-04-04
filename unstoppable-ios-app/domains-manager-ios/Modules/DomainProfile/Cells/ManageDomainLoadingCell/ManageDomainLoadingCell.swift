//
//  ManageDomainLoadingCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2022.
//

import UIKit

final class ManageDomainLoadingCell: BaseListCollectionViewCell {

    @IBOutlet private weak var defaultContentStackView: UIStackView!
    @IBOutlet private weak var hideShowContentStackView: UIStackView!
    
    @IBOutlet private var loadingIndicatorViews: [LoadingIndicatorView]!
    
    override var containerColor: UIColor { uiConfiguration.containerColor }
    override var backgroundContainerColor: UIColor { uiConfiguration.backgroundContainerColor }
    
    private var uiConfiguration: UIConfiguration = .default
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        isUserInteractionEnabled = false
        set(style: .default)
    }
    
    func set(style: Style) {
        switch style {
        case .default:
            leaveVisibleOnly(stackView: defaultContentStackView)
        case .hideShow:
            leaveVisibleOnly(stackView: hideShowContentStackView)
        }
    }
    
    func set(uiConfiguration: UIConfiguration) {
        self.uiConfiguration = uiConfiguration
        containerView.layer.cornerRadius = uiConfiguration.customCornerRadius ?? 12
        updateAppearance()
    }
    
    func setBlinkingColor(_ color: UIColor) {
        loadingIndicatorViews.forEach { view in
            view.backgroundColor = color
        }
    }
}

// MARK: - Private methods
private extension ManageDomainLoadingCell {
    func leaveVisibleOnly(stackView: UIStackView) {
        let contentStackViews: [UIStackView] = [defaultContentStackView, hideShowContentStackView]
        
        for contentStackView in contentStackViews {
            contentStackView.isHidden = contentStackView != stackView
        }
    }
}

extension ManageDomainLoadingCell {
    enum Style: Hashable {
        case `default`
        case hideShow
    }
    
    struct UIConfiguration: Hashable {
        let containerColor: UIColor
        let backgroundContainerColor: UIColor
        var customCornerRadius: CGFloat?
        
        static let `default` = UIConfiguration(containerColor: .clear,
                                               backgroundContainerColor: .clear)
        static let profileBadges = UIConfiguration(containerColor: .white.withAlphaComponent(0.16),
                                                   backgroundContainerColor: .clear,
                                                   customCornerRadius: 32)
    }
}
