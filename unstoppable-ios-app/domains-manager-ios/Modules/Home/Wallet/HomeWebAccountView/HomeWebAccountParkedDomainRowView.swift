//
//  HomeWebParkedDomainRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 31.01.2024.
//

import SwiftUI

struct HomeWebAccountParkedDomainRowView: View {
    
    let firebaseDomain: FirebaseDomainDisplayInfo
    
    var body: some View {
        ZStack(alignment: .leading) {
            Image.domainSharePlaceholder
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading) {
                cartLogoView()
                    .offset(x: -2, y: -2)
                Spacer()
                VStack(alignment: .leading, spacing: 0) {
                    Text(firebaseDomain.name.getBelowTld() ?? "")
                        .font(.currentFont(size: 20, weight: .medium))
                        .lineLimit(1)
                    Text("." + tldName)
                        .offset(x: -4)
                        .font(.currentFont(size: 20, weight: .medium))
                    Text(firebaseDomain.parkingStatus.title ?? "")
                        .font(.currentFont(size: 12))
                        .opacity(0.7)
                }
            }
            .foregroundStyle(Color.white)
            .padding(EdgeInsets(top: 8, leading: 8,
                                bottom: 8, trailing: 8))
        }
    }
    
  
}

// MARK: - Private methods
private extension HomeWebAccountParkedDomainRowView {
    var tldName: String { firebaseDomain.name.getTldName() ?? "" }

    @ViewBuilder
    func cartLogoView() -> some View {
        Image.udCartLogo
            .resizable()
            .renderingMode(.template)
            .squareFrame(32)
    }
}

#Preview {
    HomeWebAccountParkedDomainRowView(firebaseDomain: .init(firebaseDomain: MockEntitiesFabric.Domains.mockFirebaseDomains()[0]))
        .aspectRatio(1, contentMode: .fit)
        .squareFrame(150)
}
