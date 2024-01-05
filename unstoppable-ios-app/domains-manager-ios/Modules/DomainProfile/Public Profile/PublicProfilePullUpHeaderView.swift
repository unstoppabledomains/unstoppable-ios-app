//
//  PublicProfilePullUpHeaderView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 29.08.2023.
//

import SwiftUI

struct PublicProfilePullUpHeaderView: View, ProfileImageLoader {
    
    let domainName: DomainName
    let closeCallback: MainActorAsyncCallback
    
    @State private var domainIcon: UIImage? = nil
    
    var body: some View {
        ZStack {
            HStack(spacing: 8) {
                Image(uiImage: domainIcon ?? .domainSharePlaceholder)
                    .resizable()
                    .frame(width: 20,
                           height: 20)
                    .clipShape(Circle())
                Text(domainName)
                    .font(.currentFont(size: 16, weight: .semibold))
                    .foregroundColor(.foregroundDefault)
                    .lineLimit(1)
            }
            .padding(EdgeInsets(top: 0, leading: 28,
                                bottom: 0, trailing: 28))
            HStack {
                Button {
                    UDVibration.buttonTap.vibrate()
                    closeCallback()
                } label: {
                    Image.cancelIcon
                        .resizable()
                        .squareFrame(24)
                        .foregroundColor(.foregroundDefault)
                }
                Spacer()
            }
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 0, trailing: 16))
        .frame(height: 44)
        .onAppear(perform: loadDomainIcon)
    }
}

// MARK: - Private methods
private extension PublicProfilePullUpHeaderView {
    func loadDomainIcon() {
        Task {
            domainIcon = await loadInitialsFor(domainName: domainName)
            if let icon = await loadIconFor(domainName: domainName) {
                domainIcon = icon
            }
        }
    }
}

struct PublicProfilePullUpHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        PublicProfilePullUpHeaderView(domainName: "danshdsdfjhsakdjhakjdhaksdjhaksdjhaskdjhsadjkh.crypto",
                                      closeCallback: { })
    }
}
