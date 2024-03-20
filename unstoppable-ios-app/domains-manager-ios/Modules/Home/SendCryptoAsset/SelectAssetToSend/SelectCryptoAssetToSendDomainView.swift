//
//  SelectCryptoAssetToSendDomainView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

struct SelectCryptoAssetToSendDomainView: View {
    
    let domain: DomainDisplayInfo
    
    var body: some View {
        Text(domain.name)
    }
}

#Preview {
    SelectCryptoAssetToSendDomainView(domain: MockEntitiesFabric.Domains.mockDomainDisplayInfo())
}
