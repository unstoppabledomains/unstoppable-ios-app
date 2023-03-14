//
//  NFTDetailsViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.03.2023.
//

import Foundation

protocol NFTDetailsViewPresenterProtocol: BasePresenterProtocol {
    func actionButtonPressed()
}

final class NFTDetailsViewPresenter {
    private weak var view: NFTDetailsViewProtocol?
    private let nft: NFTModel
    
    init(view: NFTDetailsViewProtocol,
         nft: NFTModel) {
        self.view = view
        self.nft = nft
    }
}

// MARK: - NFTDetailsViewPresenterProtocol
extension NFTDetailsViewPresenter: NFTDetailsViewPresenterProtocol {
    @MainActor
    func viewDidLoad() {
        view?.setWith(nft: nft)
        if let link = nft.link,
           let host = URL(string: link)?.host {
            
            if let platform = SupportedNFTPlatform.allCases.first(where: { host.contains($0.rawValue) }) {
                setActionButtonWith(platformName: platform.title)
            } else {
                let host = host.replacingOccurrences(of: "www.", with: "")
                setActionButtonWith(platformName: host)
            }
        }
    }
    
    @MainActor
    func actionButtonPressed() {
        guard let view,
              let link = nft.link,
              let url = URL(string: link) else { return }
        
        WebViewController.show(in: view, withURL: url)
    }
}

// MARK: - Private functions
private extension NFTDetailsViewPresenter {
    @MainActor
    func setActionButtonWith(platformName: String) {
        view?.setActionButtonWith(title: String.Constants.profileViewOnN.localized(platformName), icon: .arrowTopRight)
    }
    
    enum SupportedNFTPlatform: String, CaseIterable {
        case openSea = "opensea"
        case magicEden = "magiceden"
        
        var title: String {
            switch self {
            case .openSea:
                return "OpenSea"
            case .magicEden:
                return "MagicEden"
            }
        }
    }
}
