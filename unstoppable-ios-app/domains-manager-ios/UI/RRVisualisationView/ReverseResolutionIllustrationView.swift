//
//  RRVisualisationView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.09.2022.
//

import UIKit

final class ReverseResolutionIllustrationView: UIView {
    
    private lazy var walletContainerView = UIView()
    private lazy var walletImageView = UIImageView()
    private lazy var walletAddressLabel = UILabel()
    
    private lazy var domainContainerView = UIView()
    private lazy var domainImageView = UIImageView()
    private lazy var domainNameLabel = UILabel()
    
    private lazy var rrSignImageView = UIImageView()
    private let domainPlaceholderName = "YOURNAME.X"


    private(set) var style: Style = .large
    
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
        
        let x = bounds.width / 2 - walletContainerView.bounds.width / 2
        let containerWidth = bounds.width * (CGFloat(272)/CGFloat(358))
        walletContainerView.frame.origin = CGPoint(x: x, y: 0)
        domainContainerView.frame.origin = CGPoint(x: x, y: walletContainerView.bounds.height + style.containersSpacing)
        
        let walletLabelWidth = containerWidth - walletAddressLabel.frame.minX - walletImageView.frame.minX
        walletAddressLabel.frame.size.width = walletLabelWidth
        
        let domainNameWidth = containerWidth - domainNameLabel.frame.minX - domainImageView.frame.minX
        domainNameLabel.frame.size.width = domainNameWidth
        
        let signY = walletContainerView.bounds.height + style.containersSpacing - rrSignImageView.bounds.height / 2
        rrSignImageView.frame.origin = CGPoint(x: bounds.width / 2 - rrSignImageView.bounds.width / 2,
                                               y: signY)
    }
}

// MARK: - Open methods
extension ReverseResolutionIllustrationView {
    func setWith(walletInfo: WalletDisplayInfo, domain: DomainItem?) {
        let walletAddress = walletInfo.address.walletAddressTruncated
        let domainName = domain?.name ?? domainPlaceholderName
        set(walletAddress: walletAddress,
            domainName: domainName)
        Task {
            var image: UIImage?
            if let domain = domain {
                image = await appContext.imageLoadingService.loadImage(from: .domain(domain),
                                                                       downsampleDescription: nil)
            }
            domainImageView.image = image ?? .domainSharePlaceholder
        }
    }
    
    func setInfoData() {
        domainImageView.image = .domainSharePlaceholder
        set(walletAddress: "0x1D43...528b",
            domainName: domainPlaceholderName)
    }
    
    func set(style: Style) {
        if deviceSize == .i4Inch { // Always use small for iPhone SE
            self.style = .small
        } else {
            self.style = style
        }
        setNeedsLayout()
        layoutIfNeeded()
        setupForCurrentStyle()
    }
}

// MARK: - Private methods
private extension ReverseResolutionIllustrationView {
    func set(walletAddress: String, domainName: String) {
        let fontSize = style.fontSize
        walletAddressLabel.setAttributedTextWith(text: walletAddress,
                                                 font: .helveticaNeueCustom(size: fontSize),
                                                 textColor: .foregroundMuted)
        domainNameLabel.setAttributedTextWith(text: domainName.uppercased(),
                                              font: .helveticaNeueCustom(size: fontSize),
                                              textColor: .foregroundDefault,
                                              lineBreakMode: .byTruncatingTail)
    }
}

// MARK: - Setup methods
private extension ReverseResolutionIllustrationView {
    func setup() {
        backgroundColor = .clear
        clipsToBounds = false
        setupWalletView()
        setupDomainView()
        setupRRSign()
        set(style: self.style)
    }
    
    func setupWalletView() {
        walletContainerView.layer.cornerRadius = 12
        walletContainerView.backgroundColor = .backgroundOverlay
        walletContainerView.addSubview(walletImageView)
        walletContainerView.addSubview(walletAddressLabel)
        addSubview(walletContainerView)
        
        walletImageView.tintColor = .foregroundMuted
        walletImageView.image = .walletOpen
      
    }
    
    func setupDomainView() {
        domainContainerView.layer.cornerRadius = 12
        domainContainerView.backgroundColor = .backgroundOverlay
        domainContainerView.addSubview(domainImageView)
        domainContainerView.addSubview(domainNameLabel)
        addSubview(domainContainerView)

        domainImageView.clipsToBounds = true
        domainNameLabel.adjustsFontSizeToFitWidth = true
    }
    
    func setupRRSign() {
        rrSignImageView.image = .reverseResolutionCircleSign
        addSubview(rrSignImageView)
    }
    
    func setupForCurrentStyle() {
        domainNameLabel.minimumScaleFactor = style.domainNameMinScaleFactor
        [walletContainerView, domainContainerView].forEach { view in
            view.layer.borderColor = UIColor.borderMuted.cgColor
            view.layer.borderWidth = 1
        }
        switch style {
        case .large:
            walletImageView.frame = CGRect(x: 20, y: 20, width: 32, height: 32)
            walletAddressLabel.frame = CGRect(x: 72, y: 16, width: bounds.width, height: 40)
            
            domainImageView.frame = CGRect(x: 16, y: 16, width: 40, height: 40)
            domainNameLabel.frame = CGRect(x: 72, y: 16, width: bounds.width, height: 40)

            rrSignImageView.frame.size = CGSize(width: 40, height: 40)
            
            [walletContainerView, domainContainerView].forEach { view in
                view.frame.size = CGSize(width: 272, height: 72)
            }
        case .small:
            walletImageView.frame = CGRect(x: 16, y: 16, width: 24, height: 24)
            walletAddressLabel.frame = CGRect(x: 56, y: 16, width: bounds.width, height: 24)
            
            domainImageView.frame = CGRect(x: 12, y: 12, width: 32, height: 32)
            domainNameLabel.frame = CGRect(x: 56, y: 16, width: bounds.width, height: 24)
            
            rrSignImageView.frame.size = CGSize(width: 32, height: 32)
            
            [walletContainerView, domainContainerView].forEach { view in
                view.frame.size = CGSize(width: 228, height: 56)
            }
        }
        
        domainImageView.layer.cornerRadius = domainImageView.bounds.width / 2
    }
}

extension ReverseResolutionIllustrationView {
    enum Style {
        case large, small
      
        var fontSize: CGFloat {
            switch self {
            case .large: return 28
            case .small: return 24
            }
        }
        
        var containersSpacing: CGFloat {
            switch self {
            case .large: return 20
            case .small: return 12
            }
        }
        
        var domainNameMinScaleFactor: CGFloat {
            0.8
        }
    }
}
