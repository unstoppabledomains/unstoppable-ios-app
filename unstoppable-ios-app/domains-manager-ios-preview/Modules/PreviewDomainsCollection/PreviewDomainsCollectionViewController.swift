//
//  PreviewDomainsCollectionViewController.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 04.12.2023.
//

import SwiftUI

@available(iOS 17, *)
#Preview {
    let domainsCollectionVC = DomainsCollectionViewController.nibInstance()
    let presenter = PreviewDomainsCollectionViewPresenter(view: domainsCollectionVC)
    domainsCollectionVC.presenter = presenter
    let nav = CNavigationController(rootViewController: domainsCollectionVC)
    
    return nav
}
