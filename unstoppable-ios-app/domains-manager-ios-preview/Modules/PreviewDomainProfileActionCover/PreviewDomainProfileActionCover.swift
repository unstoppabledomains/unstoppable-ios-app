//
//  PreviewDomainProfileActionCover.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 20.12.2023.
//

import SwiftUI

@available(iOS 17, *)
#Preview {
    let vc = DomainProfileActionCoverViewController.nibInstance()
    let presenter = DomainProfileParkedActionCoverViewPresenter(view: vc,
                                                                domain: .init(name: "oleg.x",
                                                                              ownerWallet: "",
                                                                              state: .parking(status: .parked(expiresDate: Date())),
                                                                              isSetForRR: false),
                                                                imagesInfo: .init(),
                                                                refreshActionCallback: { _ in })
    vc.presenter = presenter
    
    return vc
}
