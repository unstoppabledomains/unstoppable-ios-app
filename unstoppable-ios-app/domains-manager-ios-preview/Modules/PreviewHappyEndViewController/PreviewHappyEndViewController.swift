//
//  PreviewHappyEndViewController.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 20.12.2023.
//

import SwiftUI

@available(iOS 17.0, *)
#Preview {
    let vc = HappyEndViewController.instance()
    let presenter = PurchaseDomainsHappyEndViewPresenter(view: vc)
    vc.presenter = presenter
    return vc
}
