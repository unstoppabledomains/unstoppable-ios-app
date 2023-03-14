//
//  NFTDetailsViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2023.
//

import UIKit

@MainActor
protocol NFTDetailsViewProtocol: BaseViewControllerProtocol {
    func setWith(nft: NFTResponse)
    func setLoadingIndicator(hidden: Bool)
    func setActionButtonWith(title: String, icon: UIImage)
}

@MainActor
final class NFTDetailsViewController: BaseViewController {
    
    @IBOutlet private weak var avatarImageView: UIImageView!
    @IBOutlet private weak var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var categoryImageView: UIImageView!
    @IBOutlet private weak var chainImageView: UIImageView!
    @IBOutlet private weak var nftNameLabel: UILabel!
    @IBOutlet private weak var collectionNameLabel: UILabel!
    
    @IBOutlet private weak var priceContainerView: UIView!
    @IBOutlet private weak var containerViewTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var actionButton: PrimaryWhiteButton!
    override var analyticsName: Analytics.ViewName { .nftDetails }
    
    var presenter: NFTDetailsViewPresenterProtocol!
    
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
}

// MARK: - NFTDetailsViewProtocol
extension NFTDetailsViewController: NFTDetailsViewProtocol {
    func setWith(nft: NFTResponse) {
        nftNameLabel.setAttributedTextWith(text: nft.name ?? "N/A",
                                           font: .currentFont(withSize: 22, weight: .bold),
                                           textColor: .foregroundOnEmphasis,
                                           lineBreakMode: .byTruncatingTail)
        collectionNameLabel.setAttributedTextWith(text: nft.collection ?? "N/A",
                                                  font: .currentFont(withSize: 16, weight: .medium),
                                                  textColor: .white.withAlphaComponent(0.56),
                                                  lineBreakMode: .byTruncatingTail)
        chainImageView.image = nft.chainIcon
        setLoadingIndicator(hidden: false)
        Task {
            let image = await appContext.imageLoadingService.loadImage(from: .nft(nft: nft), downsampleDescription: nil)
            avatarImageView.image = image
            setLoadingIndicator(hidden: true)
        }
    }
    
    func setLoadingIndicator(hidden: Bool) {
        if hidden {
            loadingIndicator.stopAnimating()
        } else {
            loadingIndicator.startAnimating()
        }
    }
    
    func setActionButtonWith(title: String, icon: UIImage) {
        actionButton.isHidden = false
        actionButton.setTitle(title, image: icon)
    }
}

// MARK: - Actions
private extension NFTDetailsViewController {
    @IBAction func actionButtonPressed(_ sender: Any) {
        presenter.actionButtonPressed()
    }
}

// MARK: - Private functions
private extension NFTDetailsViewController {
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

// MARK: - Private functions
private extension NFTDetailsViewController {

}

// MARK: - Setup functions
private extension NFTDetailsViewController {
    func setup() {
        setupUI()
        addDismissGesture()
    }
    
    func setupUI() {
        priceContainerView.isHidden = true // Don't have price info right now
        categoryImageView.isHidden = true
        actionButton.isHidden = true // By default
    }
    
    func addDismissGesture() {
        view.isUserInteractionEnabled = true
        let panGesture = UIPanGestureRecognizer (target: self, action: #selector(didPanTopBar))
        view.addGestureRecognizer(panGesture)
    }
}
