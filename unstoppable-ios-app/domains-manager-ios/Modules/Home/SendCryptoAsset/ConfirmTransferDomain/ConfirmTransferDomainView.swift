//
//  ConfirmTransferDomainView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 26.03.2024.
//

import SwiftUI

struct ConfirmTransferDomainView: View {
    
    let data: SendCryptoAsset.TransferDomainData

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    NavigationStack {
        ConfirmTransferDomainView(data: .init(receiver: MockEntitiesFabric.SendCrypto.mockReceiver(),
                                              domain: MockEntitiesFabric.Domains.mockDomainDisplayInfo()))
    }
}
