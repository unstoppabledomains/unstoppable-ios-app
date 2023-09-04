//
//  PublicProfileSocialsListView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 30.08.2023.
//

import SwiftUI

struct PublicProfileSocialsListView: View {
    
    let domainName: DomainName
    let accounts: [SocialDescription]
    @Binding var isPresenting: Bool
    @State private var selectedSocial: SocialDescription?

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            PublicProfilePullUpHeaderView(domainName: domainName,
                                          closeCallback: dismiss)
            List(accounts, id: \.type, selection: $selectedSocial) { social in
                viewForSocialRow(social)
                    .tag(social)
                    .listRowSeparator(.hidden)
                    .unstoppableListRowInset()
            }
            .id(UUID())
            .offset(y: -8)
            .background(.clear)
            .clearListBackground()
            .ignoresSafeArea()
        }
        .background(Color.backgroundDefault)
        .onAppear {
            UITableView.appearance().backgroundColor = .clear
        }
        .onDisappear(perform: dismiss)
        .onChange(of: selectedSocial, perform: didSelectSocial)
    }
    
    init(domainName: DomainName, socialAccounts: SocialAccounts, isPresenting: Binding<Bool>) {
        self.domainName = domainName
        self.accounts = SocialDescription.typesFrom(accounts: socialAccounts)
        self._isPresenting = isPresenting
    }
    
}

// MARK: - Private methods
private extension PublicProfileSocialsListView {
    func dismiss() {
        guard isPresenting else { return }

        isPresenting = false
    }
    
    func didSelectSocial(_ social: SocialDescription?) {
        selectedSocial = nil

        guard let social else { return }
        social.openSocialAccount()
    }
    
    @ViewBuilder
    func viewForSocialRow(_ social: SocialDescription) -> some View {
        HStack(spacing: 16) {
            Image(uiImage: social.type.originalIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 40,
                       height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.borderSubtle, lineWidth: 1)
                )
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 0) {
                Text(social.type.title)
                    .font(.currentFont(size: 16, weight: .medium))
                    .foregroundColor(.foregroundDefault)
                    .frame(height: 24)
                Text(social.type.displayStringForValue(social.value))
                    .font(.currentFont(size: 14, weight: .regular))
                    .foregroundColor(.foregroundSecondary)
                    .frame(height: 20)
            }
            Spacer()
            Image.arrowTopRight
                .resizable()
                .frame(width: 20,
                       height: 20)
                .foregroundColor(.foregroundMuted)
        }
    }
}

struct PublicProfileSocialsListView_Previews: PreviewProvider {
    static var previews: some View {
        PublicProfileSocialsListView(domainName: "dans.crypto",
                                     socialAccounts: .mock(),
                                     isPresenting: .constant(true))
    }
}
