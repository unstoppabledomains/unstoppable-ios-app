//
//  DomainsCollectionCarouselCardCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.12.2022.
//

import UIKit

final class DomainsCollectionCarouselCardCell: UICollectionViewCell {

    typealias Action = DomainsCollectionCarouselItemViewController.DomainCardConfiguration.Action

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var shadowView: UIView!
    @IBOutlet private weak var domainAvatarBackgroundImageView: UIImageView!
    @IBOutlet private weak var domainAvatarBackgroundBlurView: UIVisualEffectView!
    @IBOutlet private weak var domainAvatarImageView: UIImageView!
    @IBOutlet private weak var domainAvatarCoverView: UIView!
    @IBOutlet private weak var udLogoImageView: UIImageView!
    @IBOutlet private weak var domainNameLabel: UILabel!
    @IBOutlet private weak var domainNameCollapsedLabel: UILabel!
    @IBOutlet private weak var domainTLDLabel: UILabel!
    @IBOutlet private weak var domainTLDCollapsedLabel: UILabel!
    @IBOutlet private weak var actionButton: UIButtonWithExtendedTappableArea!
    @IBOutlet private weak var actionButtonUIView: UIButtonWithExtendedTappableArea!
    @IBOutlet private weak var carouselView: CarouselView!
    @IBOutlet private weak var statusMessage: StatusMessage!
    
    /// On the iPhone 14 Pro Max UIMenu doesn't get opened when action button's frame origin is set manually.
    /// It works fine with auto-layout. The workaround is to have two buttons, one is visible on the UI and animated manually.
    /// Second is not visible and use auto-layout. Second button is on the top in views hierarchy and will handle menu action correctly
    @IBOutlet private weak var actionButtonLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var actionButtonTopConstraint: NSLayoutConstraint!
    
    static let minHeight: CGFloat = 80
    
    private var yOffset: CGFloat = 0
    private var visibilityLevel: CarouselCellVisibilityLevel = .init(isVisible: true, isBehind: false)
    private var animator: UIViewPropertyAnimator!
    private var actionButtonPressedCallback: EmptyCallback?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let imageViewCornerRadius: CGFloat = 8
        actionButton.setTitle("", for: .normal)
        actionButtonUIView.setTitle("", for: .normal)
        containerView.layer.cornerRadius = 12
        domainAvatarBackgroundImageView.layer.cornerRadius = 12
        domainAvatarBackgroundBlurView.layer.cornerRadius = 12
        domainAvatarImageView.layer.cornerRadius = imageViewCornerRadius
        domainAvatarCoverView.layer.cornerRadius = imageViewCornerRadius
        carouselView.elementSideOffset = 0
        carouselView.style = .small
        carouselView.setSideGradient(hidden: true)
        carouselView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        carouselView.layer.cornerRadius = imageViewCornerRadius
    }
    
    override func layoutSubviews() {
        setFrame()
    }
    
    deinit {
        releaseAnimator()
    }

}

// MARK: - ScrollViewOffsetListener
extension DomainsCollectionCarouselCardCell: ScrollViewOffsetListener {
    func didScrollTo(offset: CGPoint) {
        if offset.y < 1 {
            /// Due to ScrollView nature, it is sometimes 'stuck' with offset in range 0...0.9 (usually 0.33 or 0.66)
            /// This leads to incorrect animation progress calculation and ugly UI bug.
            /// Solution: round offset to 0 if it is < 1
            self.yOffset = 0
        } else {
            self.yOffset = round(offset.y)
        }
        setFrame()
    }
}

// MARK: - Open methods
extension DomainsCollectionCarouselCardCell {
    func updateVisibility(level: CarouselCellVisibilityLevel) {
        self.visibilityLevel = level
        setFrame()
    }
     
    func setWith(configuration: DomainsCollectionCarouselItemViewController.DomainCardConfiguration) {
        self.actionButtonPressedCallback = configuration.actionButtonPressedCallback

        let domain = configuration.domain
        let domainName = domain.name.getBelowTld() ?? ""
        let domainTLD = domain.name.getTldName() ?? ""
        
        [domainNameLabel, domainNameCollapsedLabel].forEach { label in
            setDomainNameString(domainName, toLabel: label!)
        }
       
        [domainTLDLabel, domainTLDCollapsedLabel].forEach { label in
            label?.setAttributedTextWith(text: String.dotSeparator + domainTLD.uppercased(),
                                         font: .helveticaNeueCustom(size: 28),
                                         letterSpacing: 0,
                                         textColor: .clear,
                                         lineBreakMode: .byTruncatingTail,
                                         strokeColor: .foregroundOnEmphasis,
                                         strokeWidth: 3)
        }
    
        setAvatarWith(domainItem: domain)
        resolveIndicatorStyle(for: domain)
        
        if !carouselView.isHidden {
            /// Show full domain name with TLD if there's indicator at the bottom
            setDomainNameString(domain.name, toLabel: domainNameCollapsedLabel)
        }
        
        // Actions
        let bannerMenuElements = configuration.availableActions.compactMap({ createMenuElement(for: $0) })
        let bannerMenu = UIMenu(title: "", children: bannerMenuElements)
        actionButton.menu = bannerMenu
        actionButton.showsMenuAsPrimaryAction = true
        actionButton.addAction(UIAction(handler: { [weak self] _ in
            self?.actionButtonPressedCallback?()
            UDVibration.buttonTap.vibrate()
        }), for: .menuActionTriggered)
    }
}

// MARK: - Actions
private extension DomainsCollectionCarouselCardCell {
    func createMenuElement(for action: Action) -> UIMenuElement {
        
        switch action {
        case .copyDomain(let callback), .viewVault(_, _, let callback):
            let action = createMenuAction(title: action.title,
                                    subtitle: action.subtitle,
                                    icon: action.icon,
                                    callback: callback)
            return action
        case .setUpRR(let isEnabled, let callback):
            let action = createMenuAction(title: action.title,
                                    subtitle: action.subtitle,
                                    icon: action.icon,
                                    isEnabled: isEnabled,
                                    callback: callback)
            return action
        case .rearrange(let callback):
            let rearrangeAction = createMenuAction(title: action.title,
                                    subtitle: action.subtitle,
                                    icon: action.icon,
                                    callback: callback)
            return UIMenu(title: "", options: .displayInline, children: [rearrangeAction])
        }
    }
    
    func createMenuAction(title: String, subtitle: String?, icon: UIImage, isEnabled: Bool = true, callback: @escaping EmptyCallback) -> UIAction{
        if #available(iOS 15.0, *) {
            return UIAction(title: title,
                            subtitle: subtitle,
                            image: icon,
                            identifier: .init(UUID().uuidString), attributes: isEnabled ? [] : [.disabled],
                            handler: { _ in
                UDVibration.buttonTap.vibrate()
                callback()
            })
        } else {
            return UIAction(title: title,
                            image: icon,
                            identifier: .init(UUID().uuidString),
                            handler: { _ in
                UDVibration.buttonTap.vibrate()
                callback()
            })
        }
    }
}

// MARK: - Private methods
private extension DomainsCollectionCarouselCardCell {
    func setAvatarWith(domainItem: DomainDisplayInfo) {
        if domainItem.pfpSource != .none,
           let image = appContext.imageLoadingService.cachedImage(for: .domain(domainItem)) {
            set(avatarImage: image)
        } else {
            set(avatarImage: nil)
            Task {
                let image = await appContext.imageLoadingService.loadImage(from: .domain(domainItem),
                                                                           downsampleDescription: nil)
                set(avatarImage: image)
            }
        }
    }
    
    func set(avatarImage: UIImage?) {
        containerView.backgroundColor = avatarImage == nil ? .backgroundAccentEmphasis : .clear
        domainAvatarCoverView.isHidden = avatarImage == nil
        UIView.performWithoutAnimation {
            domainAvatarImageView.image = avatarImage ?? .domainSharePlaceholder
            domainAvatarBackgroundImageView.image = avatarImage
        }
    }
    
    func setDomainNameString(_ domainName: String, toLabel label: UILabel) {
        label.setAttributedTextWith(text: domainName.uppercased(),
                                    font: .helveticaNeueCustom(size: 36),
                                    letterSpacing: 0,
                                    textColor: .foregroundOnEmphasis,
                                    lineBreakMode: .byTruncatingTail)
    }
    
    func resolveIndicatorStyle(for domain: DomainDisplayInfo) {
        switch domain.state {
        case .default:
            switch domain.usageType {
            case .normal:
                setIndicatorStyle(nil)
                setStatusMessageComponent(nil)
            case .deprecated(let tld):
                setIndicatorStyle(.deprecated(tld: tld))
                setStatusMessageComponent(.orangeDeprecated(tld: tld))
            case .zil:
                setIndicatorStyle(.deprecated(tld: "zil"))
                setStatusMessageComponent(.orangeDeprecated(tld: "zil"))
            case .parked:
                Debugger.printFailure("Parked domain should not have default state", critical: true)
            }
        case .updatingRecords:
            setIndicatorStyle(.updatingRecords)
            setStatusMessageComponent(.electricUpdatingRecords)
        case .minting:
            setIndicatorStyle(.minting)
            setStatusMessageComponent(.electricMinting)
        case .parking(let status):
            setIndicatorStyle(.parked)
            setStatusMessageComponent(.updatingRecords) // TODO: - Parking
        }
    }
    
    func setIndicatorStyle(_ style: DomainIndicatorStyle?) {
        carouselView.isHidden = style == nil
        if let style {
            carouselView.set(data: [style])
            carouselView.backgroundColor = style.containerBackgroundColor
        } else {
            carouselView.set(data: [])
        }
    }
    
    func setStatusMessageComponent(_ component: StatusMessage.Component?) {
        statusMessage.isHidden = component == nil
        if let component {
            statusMessage.setComponent(component)
        }
    }
    
    func setFrame() {
        let collapsedProgress = calculateCollapsedProgress()
        if collapsedProgress == 0  {
            releaseAnimator()
            setFrameForExpandedState()
        } else if collapsedProgress == 1 {
            releaseAnimator()
            setFrameForCollapsedState()
        } else {
            setupAnimatorIfNeeded()
            animator?.fractionComplete = collapsedProgress
        }
    }
    
    func calculateCollapsedProgress() -> CGFloat {
        guard yOffset > 0 else { return 0 }
        
        let collapsableHeight = bounds.height - Self.minHeight
        
        if yOffset > collapsableHeight {
            return 1
        }
        
        let progress = yOffset / collapsableHeight
        
        return min(progress, 1)
    }
    
    func setFrame(for state: CardState) {
        setContainerViewFrame(for: state)
        setFrameForBackgroundViews()
        setAvatarImageViewFrame(for: state)
        setUDLogoViewFrame(for: state)
        setActionButtonFrame(for: state)
        setDomainNameLabelFrame(for: state)
        setDomainTLDLabelFrame(for: state)
        setIndicatorsFrame(for: state)
        setSideVisibilityFrame(for: state)
    }
    
    func setFrameForExpandedState() {
        setFrame(for: .expanded)
    }
    
    func setFrameForCollapsedState() {
        setFrame(for: .collapsed)
    }
    
    func setupAnimatorIfNeeded() {
        if animator == nil {
            setupCollapseAnimator()
        }
    }
    
    func releaseAnimator() {
        animator?.stopAnimation(true)
        animator = nil
    }
    
    func setupCollapseAnimator() {
        releaseAnimator()
        setFrameForExpandedState()
        animator = UIViewPropertyAnimator(duration: 10, curve: .linear)
        animator.addAnimations {
            self.setFrameForCollapsedState()
        }
    }
}

// MARK: - UI Frame related methods
private extension DomainsCollectionCarouselCardCell {
    func setContainerViewFrame(for state: CardState) {
        containerView.bounds.origin = .zero
        let visibilityLevelValue = abs(visibilityLevel.value)
        switch state {
        case .expanded:
            let size = bounds.size
            let containerSize = CGSize(width: size.width * visibilityLevelValue,
                                       height: size.height * visibilityLevelValue)
            containerView.frame.size = containerSize
            containerView.frame.origin = CGPoint(x: (size.width - containerSize.width) / 2,
                                                 y: (size.height - containerSize.height) / 2)
        case .collapsed:
            let containerHeight = Self.minHeight
            
            containerView.frame.size = CGSize(width: bounds.width,
                                              height: containerHeight)
            containerView.frame.origin = CGPoint(x: 0,
                                                 y: bounds.height - containerHeight)
        }
    }
    
    func setFrameForBackgroundViews() {
        domainAvatarBackgroundBlurView.frame = containerView.bounds
        domainAvatarBackgroundImageView.frame = containerView.bounds
        domainAvatarBackgroundImageView.frame.size.width -= 1
        domainAvatarBackgroundImageView.frame.size.height -= 1
        shadowView.frame = containerView.frame
        shadowView.applyFigmaShadow(style: .large)
    }
    
    func setAvatarImageViewFrame(for state: CardState) {
        let avatarSideOffset: CGFloat
        switch state {
        case .expanded:
            avatarSideOffset = 16
            domainAvatarImageView.frame.size.width = containerView.frame.width - (avatarSideOffset * 2)
            domainAvatarImageView.frame.size.height = domainAvatarImageView.frame.size.width
        case .collapsed:
            avatarSideOffset = 4
            domainAvatarImageView.frame.size.height = containerView.frame.height - (avatarSideOffset * 2)
            domainAvatarImageView.frame.size.width = domainAvatarImageView.frame.size.height
        }
        domainAvatarImageView.bounds.origin = .zero
        domainAvatarImageView.frame.origin = CGPoint(x: avatarSideOffset,
                                                     y: avatarSideOffset)
        domainAvatarCoverView.frame = domainAvatarImageView.frame
    }
    
    func setIndicatorsFrame(for state: CardState) {
        let height: CGFloat = 20
        switch state {
        case .expanded:
            carouselView.alpha = 1
            statusMessage.alpha = 0
            carouselView.frame.size = CGSize(width: domainAvatarImageView.bounds.width, height: height)
            carouselView.frame.origin = CGPoint(x: domainAvatarImageView.frame.minX,
                                                y: domainAvatarImageView.frame.maxY - height)
            
            statusMessage.frame = carouselView.frame
        case .collapsed:
            carouselView.alpha = 0
            statusMessage.alpha = 1
            statusMessage.frame = domainTLDLabel.frame
            statusMessage.frame.origin.x = domainNameLabel.frame.minX
            statusMessage.frame.size.height = 20
            carouselView.frame = statusMessage.frame
        }
    }
    
    func setUDLogoViewFrame(for state: CardState) {
        let udLogoSize: CGFloat
        let udLogoSideOffset: CGFloat
        let alpha: CGFloat
        switch state {
        case .expanded:
            udLogoSize = 56
            udLogoSideOffset = 24
            alpha = 1
        case .collapsed:
            udLogoSize = 14
            udLogoSideOffset = 6
            alpha = 0
        }
        udLogoImageView.frame = CGRect(origin: CGPoint(x: udLogoSideOffset,
                                                       y: udLogoSideOffset),
                                       size: CGSize(width: udLogoSize,
                                                    height: udLogoSize))
        udLogoImageView.alpha = alpha
    }
    
    func setActionButtonFrame(for state: CardState) {
        let actionButtonSize: CGFloat = 24
        let size = CGSize(width: actionButtonSize,
                          height: actionButtonSize)
        switch state {
        case .expanded:
            actionButtonUIView.frame = CGRect(origin: CGPoint(x: domainAvatarImageView.frame.maxX - actionButtonSize,
                                                        y: domainAvatarImageView.frame.maxY + 33),
                                        size: size)
        case .collapsed:
            actionButtonUIView.frame = CGRect(origin: CGPoint(x: containerView.bounds.width - actionButtonSize - 16,
                                                        y: (containerView.bounds.height / 2) - (actionButtonSize / 2)),
                                        size: size)
        }
        let actionButtonRequiredFrame = actionButtonUIView.convert(actionButtonUIView.bounds, to: self)
        actionButtonLeadingConstraint.constant = actionButtonRequiredFrame.minX
        actionButtonTopConstraint.constant = actionButtonRequiredFrame.minY
    }
    
    func setDomainNameLabelFrame(for state: CardState) {
        switch state {
        case .expanded:
            [domainNameLabel, domainNameCollapsedLabel].forEach { label in
                label?.transform = .identity
                label?.frame.origin = CGPoint(x: domainAvatarImageView.frame.minX,
                                              y: domainAvatarImageView.frame.maxY + 13)
                label?.frame.size.height = 36
            }
            
            let maxDomainNameLabelWidth = (domainAvatarImageView.bounds.width / abs(visibilityLevel.value)) - actionButtonUIView.bounds.width - 16
            domainNameLabel.frame.size.width = maxDomainNameLabelWidth
            domainNameLabel.alpha = 1
            domainNameCollapsedLabel.alpha = 0
        case .collapsed:
            let domainNameScale: CGFloat = 0.7777
            [domainNameLabel, domainNameCollapsedLabel].forEach { label in
                label?.transform = .init(scaleX: domainNameScale, y: domainNameScale)
                label?.frame.origin = CGPoint(x: domainAvatarImageView.frame.maxX + 16,
                                              y: 14)
            }
            
            let domainNameMaxWidth = containerView.bounds.width - domainNameLabel.frame.minX - (containerView.bounds.width - actionButtonUIView.frame.minX)
            domainNameCollapsedLabel.frame.size.width = domainNameMaxWidth
            domainNameLabel.alpha = 0
            domainNameCollapsedLabel.alpha = 1
        }
        setScaleForLabel(domainNameLabel)
        setScaleForLabel(domainNameCollapsedLabel)
    }
  
    func setDomainTLDLabelFrame(for state: CardState) {
        let tldLabels = [domainTLDLabel, domainTLDCollapsedLabel]
        let tldOffset: CGFloat = 6
        
        switch state {
        case .expanded:
            tldLabels.forEach { label in
                label?.transform = .identity
            }
            domainTLDLabel.alpha = 1
            domainTLDCollapsedLabel.alpha = 0
        case .collapsed:
            let domainNameScale: CGFloat = 0.7777
            tldLabels.forEach { label in
                label?.transform = .init(scaleX: domainNameScale, y: domainNameScale)
            }
            domainTLDLabel.alpha = 0
            domainTLDCollapsedLabel.alpha = carouselView.isHidden ? 1 : 0
        }
        
        tldLabels.forEach { label in
            label?.frame.size = CGSize(width: domainNameLabel.bounds.width + tldOffset,
                                       height: 28)
            label?.frame.origin = CGPoint(x: domainNameLabel.frame.minX - tldOffset,
                                          y: domainNameLabel.frame.maxY)
        }
        
        setScaleForLabel(domainTLDLabel)
        setScaleForLabel(domainTLDCollapsedLabel)
    }
    
    func setScaleForLabel(_ label: UILabel) {
        let width = label.bounds.width
        let font = label.font!
        let text = label.attributedText?.string ?? label.text ?? ""
        let requiredWidth = text.width(withConstrainedHeight: label.bounds.height, font: font)
        if requiredWidth > width {
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = max(Constants.domainNameMinimumScaleFactor, (width / requiredWidth))
        } else {
            label.adjustsFontSizeToFitWidth = false
        }
    }
    
    func setSideVisibilityFrame(for state: CardState) {
        let visibilityLevelValue = abs(visibilityLevel.value)
        var visibilitySideOffset = (1 - visibilityLevelValue) * DomainsCollectionUICache.nominalCardWidth
        if visibilityLevel.isBehind {
            switch state {
            case .expanded:
                visibilitySideOffset *= -2
            case .collapsed:
                visibilitySideOffset *= -1
            }
        }
        containerView.frame.origin.x = -visibilitySideOffset
    }
}

// MARK: - Private methods
private extension DomainsCollectionCarouselCardCell {
    enum CardState {
        case expanded, collapsed
    }
}

// MARK: - Private methods
private extension DomainsCollectionCarouselCardCell {
    enum DomainIndicatorStyle: CarouselViewItem {
        case updatingRecords, minting, deprecated(tld: String), parked
      
        var containerBackgroundColor: UIColor {
            switch self {
            case .updatingRecords:
                return .brandElectricYellow
            case .minting:
                return .brandElectricGreen
            case .deprecated, .parked:
                return .brandOrange
            }
        }
        
        /// CarouselViewItem properties
        var icon: UIImage {
            switch self {
            case .updatingRecords, .minting:
                return .refreshIcon
            case .deprecated:
                return .warningIconLarge
            case .parked:
                return .parkingIcon24
            }
        }
        
        var text: String {
            switch self {
            case .updatingRecords:
                return String.Constants.updatingRecords.localized()
            case .minting:
                return String.Constants.mintingInProgressTitle.localized()
            case .deprecated(let tld):
                return String.Constants.tldHasBeenDeprecated.localized(tld)
            case .parked:
                return String.Constants.parkedDomain.localized()
            }
        }
        
        var tintColor: UIColor {
            switch self {
            case .updatingRecords, .minting, .deprecated, .parked:
                return .black
            }
        }
        
        var backgroundColor: UIColor {
            switch self {
            case .updatingRecords, .minting, .deprecated, .parked:
                return .clear
            }
        }
    }
}
