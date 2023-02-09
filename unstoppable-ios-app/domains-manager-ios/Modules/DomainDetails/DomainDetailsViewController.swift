//
//  DomainDetailsViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.05.2022.
//

import UIKit

@MainActor
protocol DomainDetailsViewProtocol: BaseViewControllerProtocol {
    func setWithDomain(_ domain: DomainDisplayInfo)
    func setDomain(avatarImage: UIImage?)
    func setQRImage(_ qrImage: UIImage?)
    func showQRSaved()
    func setDomainInfo(hidden: Bool)
    func setActionButtonWith(title: String, icon: UIImage)
}

@MainActor
final class DomainDetailsViewController: BaseViewController {
    
    @IBOutlet private weak var dragContainerView: UIView!
    @IBOutlet private weak var qrCodeContainerView: UIView!
    @IBOutlet private weak var qrCodeImageView: UIImageView!
    @IBOutlet private weak var qrCodeLoadingIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var domainAvatarImageView: UIImageView!
    @IBOutlet private weak var domainNameLabel: UILabel!
    @IBOutlet private weak var shareButton: TextWhiteButton!
    @IBOutlet private weak var containerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var domainInfoStackView: UIStackView!
    @IBOutlet private weak var actionButton: PrimaryWhiteButton!
    

    var presenter: DomainDetailsViewPresenterProtocol!
    
    override var isNavBarHidden: Bool { true }
    override var analyticsName: Analytics.ViewName { presenter.analyticsName }
    override var additionalAppearAnalyticParameters: Analytics.EventParameters { [.domainName: presenter.domainName]}
    override var preferredStatusBarStyle: UIStatusBarStyle { isClosed ? .default : .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        setClosedPosition(animated: false)
        presenter.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        presenter.viewWillAppear()
        DispatchQueue.main.async {
            self.setFullyOpenPosition()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
}

// MARK: - DomainDetailsViewProtocol
extension DomainDetailsViewController: DomainDetailsViewProtocol {
    func setWithDomain(_ domain: DomainDisplayInfo) {
        domainNameLabel.setAttributedTextWith(text: domain.name,
                                              font: .currentFont(withSize: 22, weight: .bold),
                                              textColor: .foregroundOnEmphasis,
                                              lineBreakMode: .byTruncatingTail)
    }
    
    func setDomain(avatarImage: UIImage?) {
        domainAvatarImageView.image = avatarImage
        domainAvatarImageView.isHidden = avatarImage == nil
    }
    
    func setQRImage(_ qrImage: UIImage?) {
        qrCodeImageView.image = qrImage
        qrImage == nil ? qrCodeLoadingIndicator.startAnimating() : qrCodeLoadingIndicator.stopAnimating()
    }
    
    func showQRSaved() {
        shareButton.isSuccess = true
        shareButton.setTitle(String.Constants.saved.localized(), image: .checkIcon)
        shareButton.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.shareButton.isSuccess = false
            self?.setupShareButton()
            self?.shareButton.isUserInteractionEnabled = true
        }
    }
    
    func setDomainInfo(hidden: Bool) {
        qrCodeContainerView.backgroundColor = .clear
        domainInfoStackView.isHidden = hidden
    }
    
    func setActionButtonWith(title: String, icon: UIImage) {
        actionButton.isHidden = false
        actionButton.setTitle(title, image: icon)
    }
}

// MARK: - Actions
private extension DomainDetailsViewController {
    @IBAction func shareButtonPressed() {
        logButtonPressedAnalyticEvents(button: .share, parameters: [.domainName: presenter.domainName])
        presenter.shareButtonPressed()
    }
    
    @IBAction func actionButtonPressed(_ sender: Any) {
        presenter.actionButtonPressed()
    }
}

// MARK: - Private functions
private extension DomainDetailsViewController {
    var closedPosition: CGFloat { -UIScreen.main.bounds.height }
    var isClosed: Bool { containerViewTopConstraint.constant == closedPosition }
    
    @objc func didPanTopBar(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began: break
        case .changed:
            let translation = recognizer.translation(in: view)
                       
            setContainerYOffset(-max(0, translation.y), animated: false)
        case .ended, .failed, .cancelled:
            let projectedY = recognizer.projectedYPoint(in: view)
            let finalPoint = abs(containerViewTopConstraint.constant) + projectedY
            if finalPoint > view.bounds.height / 4 {
                closeDown()
            } else {
                setFullyOpenPosition()
            }
        default: break
        }
    }
    
    func setClosedPosition(animated: Bool, completion: EmptyCallback? = nil) {
        setContainerYOffset(closedPosition, animated: animated, completion: completion)
    }
    
    func closeDown() {
        logButtonPressedAnalyticEvents(button: .close)
        setClosedPosition(animated: true, completion: { [weak self] in
            self?.dismiss(animated: true)
            self?.cNavigationController?.updateStatusBar()
        })
    }
    
    func setFullyOpenPosition() {
        setContainerYOffset(0, animated: true)
    }
    
    func setContainerYOffset(_ yOffset: CGFloat, animated: Bool, completion: EmptyCallback? = nil) {
        let animationDuration: TimeInterval = animated ? 0.25 : 0.0
        containerViewTopConstraint.constant = yOffset
        UIView.animate(withDuration: animationDuration) { [weak self] in
            self?.view.layoutIfNeeded()
        } completion: { _ in
            completion?()
        }
    }
}

// MARK: - Setup functions
private extension DomainDetailsViewController {
    func setup() {
        setupUI()
        addDismissGesture()
    }
    
    func setupUI() {
        view.backgroundColor = .clear
        setupQRCodeView()
        setupDomainAvatarView()
        setupShareButton()
    }
    
    func setupQRCodeView() {
        qrCodeContainerView.clipsToBounds = true
        qrCodeContainerView.layer.cornerRadius = 12
    }
    
    func setupDomainAvatarView() {
        domainAvatarImageView.clipsToBounds = true
        domainAvatarImageView.layer.cornerRadius = 14
    }
    
    func setupShareButton() {
        shareButton.setTitle(String.Constants.share.localized(), image: .shareIconSmall)
    }

    func addDismissGesture() {
        view.isUserInteractionEnabled = true
        let panGesture = UIPanGestureRecognizer (target: self, action: #selector(didPanTopBar))
        view.addGestureRecognizer(panGesture)
    }
}
