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
    private let nft: NFTResponse
    
    init(view: NFTDetailsViewProtocol,
         nft: NFTResponse) {
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
           let host = URL(string: link)?.host,
           host.contains("opensea") {
            view?.setActionButtonWith(title: String.Constants.profileViewOnOpenSea.localized(), icon: .arrowTopRight)
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

}
