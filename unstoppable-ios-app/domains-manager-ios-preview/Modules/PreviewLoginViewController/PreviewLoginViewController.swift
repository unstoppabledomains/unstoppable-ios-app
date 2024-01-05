//
//  PreviewLoginViewController.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 05.01.2024.
//

import SwiftUI

@available(iOS 17.0, *)
#Preview {
    let vc = LoginViewController.nibInstance()
    let presenter = PreviewLoginViewPresenter(view: vc)
    vc.presenter = presenter
    
    return vc
}

private final class PreviewLoginViewPresenter: LoginViewPresenter {
  
}
