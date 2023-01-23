//
//  WhatIsMintingViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 17.11.2022.
//

import UIKit
import AVKit

@MainActor
protocol WhatIsMintingViewProtocol: BaseViewControllerProtocol {

}

@MainActor
final class WhatIsMintingViewController: BaseViewController {
    
    @IBOutlet private weak var titleLabel: UDTitleLabel!
    @IBOutlet private weak var subtitleLabel: UDSubtitleLabel!
    @IBOutlet private weak var videoContainerView: UIView!
    @IBOutlet private weak var confirmButton: MainButton!
    @IBOutlet private weak var checkboxContainer: UIView!
    @IBOutlet private weak var checkbox: UDCheckBox!
    @IBOutlet private weak var dontShowAgainLabel: UILabel!
    
    override var analyticsName: Analytics.ViewName { .whatIsMinting }

    var presenter: WhatIsMintingViewPresenterProtocol!
    private var player: AVPlayer!
    private var avPlayerController: AVPlayerViewController!
    private var isObservingPlayer = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        presenter.viewDidLoad()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if player?.rate == 0 {
            logButtonPressedAnalyticEvents(button: .videoPlayerStop)
        } else {
            logButtonPressedAnalyticEvents(button: .videoPlayerStart)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        startPlayerObservation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopPlayerObservation()
    }
}

// MARK: - WhatIsMintingViewProtocol
extension WhatIsMintingViewController: WhatIsMintingViewProtocol {
    
}

// MARK: - Private functions
private extension WhatIsMintingViewController {
    @IBAction func confirmButtonPressed() {
        logButtonPressedAnalyticEvents(button: .continue)
        presenter.confirmButtonPressed()
    }
    
    @IBAction func didTapDontShowAgainCheckbox(_ sender: UDCheckBox) {
        presenter.didUpdateDontShowWhatIsMintingPreferences(isEnabled: sender.isOn)
        logButtonPressedAnalyticEvents(button: .dontShowWhatIsMintingCheckbox, parameters: [.isOn : String(checkbox.isOn)])
    }
    
    @objc func didTapCheckboxContainer() {
        UDVibration.buttonTap.vibrate()
        checkbox.isOn.toggle()
        didTapDontShowAgainCheckbox(checkbox)
    }
   
    func startPlayerObservation() {
        guard !isObservingPlayer else { return }
        
        player.addObserver(self, forKeyPath: "rate", context: nil)
        isObservingPlayer = true
    }
    
    func stopPlayerObservation() {
        guard isObservingPlayer else { return }

        player.pause()
        player.removeObserver(self, forKeyPath: "rate")
        isObservingPlayer = false
    }
}

// MARK: - Setup functions
private extension WhatIsMintingViewController {
    func setup() {
        localizeContent()
        setupInfoVideo()
        setupGestureRecognizers()
    }
    
    func localizeContent() {
        titleLabel.setTitle(String.Constants.whatIsMintingTitle.localized())
        subtitleLabel.setSubtitle(String.Constants.whatIsMintingSubtitle.localized())
        dontShowAgainLabel.setAttributedTextWith(text: String.Constants.dontShowItAgain.localized(),
                                                 font: .currentFont(withSize: 14, weight: .medium),
                                                 textColor: .foregroundDefault)
        confirmButton.setTitle(String.Constants.getStarted.localized(), image: nil)
    }
    
    func setupInfoVideo() {
        guard let infoURL = String.Links.mintDomainGuide.url else { return }
        
        setupAudioSession()
        player = AVPlayer(url: infoURL)
        player.automaticallyWaitsToMinimizeStalling = false
        avPlayerController = AVPlayerViewController()
        avPlayerController.player = self.player
        addChildViewController(avPlayerController, andEmbedToView: videoContainerView)
    }
    
    func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: .spokenAudio, options: .defaultToSpeaker)
        try? audioSession.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    func setupGestureRecognizers() {
        [dontShowAgainLabel, checkboxContainer].forEach { view in
            view?.isUserInteractionEnabled = true
            view?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapCheckboxContainer)))
        }
    }
}
