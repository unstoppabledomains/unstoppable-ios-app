//
//  ConnectedAppImageView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.12.2022.
//

import UIKit

final class ConnectedAppImageView: UIView {
    
    private var appImageBackgroundView: UIView!
    private var appImageView: UIImageView!
    private var networkIndicatorImageView: UIImageView!
    private let networkIndicatorSize: CGFloat = 20
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    override func layoutSubviews() {
        let networkIndicatorEdgeShift: CGFloat = 4
        let currentShift = bounds.width - networkIndicatorSize + networkIndicatorEdgeShift
        networkIndicatorImageView.frame.origin = .init(x: currentShift,
                                                       y: currentShift)
    }
    
}

// MARK: - Open methods
extension ConnectedAppImageView {
    func setWith(app: any UnifiedConnectAppInfoProtocol) {
        appImageView.layer.borderColor = UIColor.borderSubtle.cgColor
        appImageView.layer.borderWidth = 1
        Task {
            let icon = await appContext.imageLoadingService.loadImage(from: .connectedApp(app, size: .default), downsampleDescription: nil)
            
            let color = await ConnectedAppsImageCache.shared.colorForApp(app)
            appImageBackgroundView.isHidden = color == nil
            appImageBackgroundView.backgroundColor = color
            appImageView.image = icon
        }
    }
}

// MARK: - Setup methods
private extension ConnectedAppImageView {
    func setup() {
        backgroundColor = .clear
        clipsToBounds = false
        addImageBackgroundView()
        addImageView()
        addNetworkIndicatorImageView()
    }
    
    func addImageBackgroundView() {
        appImageBackgroundView = UIView(frame: bounds)
        appImageBackgroundView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        appImageBackgroundView.clipsToBounds = true
        appImageBackgroundView.layer.cornerRadius = 12
        addSubview(appImageBackgroundView)
    }
    
    func addImageView() {
        appImageView = UIImageView(frame: bounds)
        appImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        appImageView.clipsToBounds = true
        appImageView.layer.cornerRadius = 12
        addSubview(appImageView)
    }
    
    func addNetworkIndicatorImageView() {
        networkIndicatorImageView = UIImageView(frame: .init(origin: .zero,
                                                             size: .init(width: networkIndicatorSize,
                                                                         height: networkIndicatorSize)))
        networkIndicatorImageView.clipsToBounds = true
        networkIndicatorImageView.layer.cornerRadius = networkIndicatorSize / 2
        addSubview(networkIndicatorImageView)
    }
}
