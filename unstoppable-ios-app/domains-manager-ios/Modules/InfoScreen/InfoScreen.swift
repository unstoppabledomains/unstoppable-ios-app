//
//  InfoScreen.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.05.2022.
//

import UIKit
import AVKit

final class InfoScreen: BaseViewController {

    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var videoContainerView: UIView!
    @IBOutlet private weak var scrollView: UIScrollView!
    
    override var prefersLargeTitles: Bool { true }
    private var preset: Preset = .createBackupPassword
    private var player: AVPlayer!
    private var avPlayerController: AVPlayerViewController!
    override var analyticsName: Analytics.ViewName { .infoScreen }
    override var additionalAppearAnalyticParameters: Analytics.EventParameters { [.infoTopic : preset.rawValue] }
    
    static func instantiate(preset: Preset,
                            dismissCallback: EmptyCallback?) -> UIViewController {
        let vc = InfoScreen.nibInstance()
        vc.preset = preset
        let nav = EmptyRootCNavigationController(rootViewController: vc)
        nav.dismissCallback = dismissCallback
        
        return nav
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setup()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if player?.rate == 0 {
            logButtonPressedAnalyticEvents(button: .videoPlayerStop)
        } else {
            logButtonPressedAnalyticEvents(button: .videoPlayerStart)
        }
    }
    
}

// MARK: - UIScrollViewDelegate
extension InfoScreen: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        cNavigationController?.underlyingScrollViewDidScroll(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            cNavigationController?.underlyingScrollViewDidFinishScroll(scrollView)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        cNavigationController?.underlyingScrollViewDidFinishScroll(scrollView)
    }
}

// MARK: - Private methods
private extension InfoScreen {
    func setup() {
        title = preset.title
        setupTextView()
        setupScrollView()
        setupInfoVideo()
    }
    
    func setupTextView() {
        let indent: CGFloat = 0
        textView.setAttributedTextWith(text: preset.text,
                                       font: .currentFont(withSize: 16, weight: .regular),
                                       headIndent: indent,
                                       firstLineHeadIndent: indent,
                                       tailIndent: -indent,
                                       lineHeight: 24)
        if let highlightedText = preset.highlightedText {
            textView.updateAttributesOf(text: highlightedText,
                                        withFont: .currentFont(withSize: 16, weight: .medium),
                                        headIndent: indent,
                                        firstLineHeadIndent: indent,
                                        tailIndent: -indent)
        }
        if let bullets = preset.bullets {
            textView.updateAttributesOf(text: bullets,
                                        headIndent: indent + 20,
                                        firstLineHeadIndent: indent)
        }
    }
    
    func setupScrollView() {
        switch deviceSize {
        case .i4Inch, .i4_7Inch, .i5_5Inch:
            scrollView.contentInset.top = 125
        default:
            scrollView.contentInset.top = 145
        }
        scrollView.delegate = self
    }
    
    func setupInfoVideo() {
        if let infoURL = preset.infoURL {
            setupAudioSession()
            player = AVPlayer(url: infoURL)
            player.automaticallyWaitsToMinimizeStalling = false
            avPlayerController = AVPlayerViewController()
            avPlayerController.player = self.player
            addChildViewController(avPlayerController, andEmbedToView: videoContainerView)
            player.addObserver(self, forKeyPath: "rate", context: nil)
        } else {
            videoContainerView.isHidden = true
        }
    }
    
    func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: .spokenAudio, options: .defaultToSpeaker)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
}

// MARK: - Open methods
extension InfoScreen {
    enum Preset: String {
        
        case createBackupPassword
        case whatIsRecoveryPhrase
        case restoreFromICloudBackup
        case mintingNFTDomain
        
        var title: String {
            switch self {
            case .createBackupPassword: return String.Constants.createPasswordHelpTitle.localized()
            case .whatIsRecoveryPhrase: return String.Constants.recoveryPhraseHelpTitle.localized()
            case .restoreFromICloudBackup: return String.Constants.restoreFromICloudHelpTitle.localized()
            case .mintingNFTDomain: return String.Constants.mintNFTDomainHelpTitle.localized()
            }
        }
        
        var text: String {
            switch self {
            case .createBackupPassword: return String.Constants.createPasswordHelpText.localized()
            case .whatIsRecoveryPhrase: return String.Constants.recoveryPhraseHelpText.localized()
            case .restoreFromICloudBackup: return String.Constants.restoreFromICloudHelpText.localized()
            case .mintingNFTDomain: return String.Constants.mintNFTDomainHelpText.localized()
            }
        }
        
        var highlightedText: String? {
            switch self {
            case .createBackupPassword: return String.Constants.createPasswordHelpTextHighlighted.localized()
            case .whatIsRecoveryPhrase: return String.Constants.recoveryPhraseHelpTextHighlighted.localized()
            case .restoreFromICloudBackup: return String.Constants.restoreFromICloudHelpTextHighlighted.localized()
            case .mintingNFTDomain: return nil
            }
        }
        
        var bullets: String? {
            switch self {
            case .createBackupPassword: return nil
            case .whatIsRecoveryPhrase: return String.Constants.recoveryPhraseHelpTextBullets.localized()
            case .restoreFromICloudBackup, .mintingNFTDomain:
                return nil
            }
        }
        
        var infoURL: URL? {
            switch self {
            case .mintingNFTDomain:
                return String.Links.mintDomainGuide.url
            case .createBackupPassword, .whatIsRecoveryPhrase, .restoreFromICloudBackup:
                return nil
            }
        }
    }
}
