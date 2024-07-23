//
//  FullMaintenanceModeView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.07.2024.
//

import SwiftUI

struct FullMaintenanceModeView: View {
    
    static func instance() -> UIViewController {
        UIHostingController(rootView: FullMaintenanceModeView())
    }
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    FullMaintenanceModeView()
}
