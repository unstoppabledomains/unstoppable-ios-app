//
//  SaveDomainImageTypePullUpView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.06.2022.
//

import Foundation
import UIKit

protocol SaveDomainImagePreviewProvider: UIView {
    var title: String { get }
    var time: String { get }
    func setPreview(with saveDomainImageDescription: SaveDomainImageDescription)
    func finalImage() -> UIImage?
}

extension SaveDomainImagePreviewProvider {
    var time: String { "9:41" }
}

typealias SaveDomainSelectionResult = SaveDomainImageTypePullUpView.SelectionResult
typealias SaveDomainSelectionCallback = (SaveDomainSelectionResult)->()

final class SaveDomainImageTypePullUpView: UIView, SelfNameable, NibInstantiateable {
 
    @IBOutlet weak var containerView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    
    @IBOutlet private weak var wallpaperPreview: WallpaperDomainImagePreviewView!
    @IBOutlet private weak var socialsPreview: SocialsDomainImagePreviewView!
    @IBOutlet private weak var watchfacePreview: WatchFaceDomainImagePreviewView!
    @IBOutlet private weak var contentStack: UIStackView!
    @IBOutlet private var previewTitleButtons: [TertiaryButton]!
    
    private var previewProviders: [SaveDomainImagePreviewProvider] { [wallpaperPreview, socialsPreview, watchfacePreview] }
    
    var selectionCallback: SaveDomainSelectionCallback?
    private var saveDomainImageDescription: SaveDomainImageDescription?

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setPreview(with saveDomainImageDescription: SaveDomainImageDescription) {
        assert(previewProviders.count == previewTitleButtons.count)
        self.saveDomainImageDescription = saveDomainImageDescription
        
        for i in 0..<previewProviders.count {
            let provider = previewProviders[i] 
            
            provider.setNeedsLayout()
            provider.layoutIfNeeded()
            provider.setPreview(with: saveDomainImageDescription)
                
            let button = previewTitleButtons[i]
            button.tag = i
            button.customFontWeight = .medium
            button.setTitle(provider.title, image: nil)
            button.addTarget(self, action: #selector(selectPreviewButtonPressed), for: .touchUpInside)
        }
    }
    
}

// MARK: - Actions
private extension SaveDomainImageTypePullUpView {
    @objc func selectPreviewButtonPressed(_ sender: TertiaryButton) {
        let tag = sender.tag
        let provider = previewProviders[tag]
        let style = ExportStyle(rawValue: tag) ?? .card
        appContext.analyticsService.log(event: .didSelectExportDomainPFPStyle,
                                        withParameters: [.exportDomainImageStyle : style.analyticsName])
        
        guard let image = provider.finalImage() else {
            Debugger.printFailure("Failed to generate image for sharing", critical: true)
            return
        }
        
        selectionCallback?(.init(image: image, style: style))
    }
}

// MARK: - Setup methods
private extension SaveDomainImageTypePullUpView {
    func setup() {
        commonViewInit()
        backgroundColor = .clear
        clipsToBounds = false
        titleLabel.setAttributedTextWith(text: String.Constants.saveAsImage.localized(),
                                         font: .currentFont(withSize: 22, weight: .bold),
                                         textColor: .foregroundDefault)
        if deviceSize == .i4Inch {
            contentStack.spacing = -6
        }
    }
}

// MARK: - Private methods
extension SaveDomainImageTypePullUpView {
    struct SelectionResult {
        let image: UIImage
        let style: ExportStyle
    }

    enum ExportStyle: Int {
        case wallpaper, card, watch
        
        var analyticsName: String {
            switch self {
            case .card:
                return "card"
            case .wallpaper:
                return "wallpaper"
            case .watch:
                return "watch"
            }
        }
        
        var name: String {
            switch self {
            case .card:
                return String.Constants.card.localized()
            case .wallpaper:
                return String.Constants.wallpaper.localized()
            case .watch:
                return String.Constants.watchface.localized()
            }
        }
    }
}
