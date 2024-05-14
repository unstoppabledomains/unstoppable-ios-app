//
//  CopyMultichainWalletAddressesPullUpView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.05.2024.
//

import SwiftUI

struct CopyMultichainWalletAddressesPullUpView: View {
    
    let tokens: [BalanceTokenUIDescription]
    let selectionType: SelectionType
    var withDismissIndicator = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerView()
                cryptoListView()
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .background(Color.backgroundDefault)
    }
    
    @MainActor
    static func calculateHeightFor(tokens: [BalanceTokenUIDescription],
                                   selectionType: SelectionType) -> CGFloat {
        var subtitle: ViewPullUpDefaultConfiguration.Subtitle?
        if let sub = selectionType.subtitle {
            subtitle = .label(.text(sub))
        }
        let height = ViewPullUpDefaultConfiguration(title: .text(selectionType.title),
                                                    subtitle: subtitle,
                                                    analyticName: .addWalletSelection).calculateHeight()
        let listItemsHeight = CGFloat(tokens.count) * 64
        return height + listItemsHeight + 64
    }
}

// MARK: - Private methods
private extension CopyMultichainWalletAddressesPullUpView {
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            if withDismissIndicator {
                DismissIndicatorView()
            }
            VStack(spacing: 8) {
                Text(selectionType.title)
                    .font(.currentFont(size: 22, weight: .bold))
                    .foregroundStyle(Color.foregroundDefault)
                if let subtitle = selectionType.subtitle {
                    Text(subtitle)
                        .font(.currentFont(size: 16))
                        .foregroundStyle(Color.foregroundSecondary)
                }
            }
            .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
    }
    
    @ViewBuilder
    func cryptoListView() -> some View {
        UDCollectionSectionBackgroundView {
            VStack(alignment: .center, spacing: 0) {
                ForEach(tokens, id: \.id) { token in
                    listViewFor(token: token)
                }
            }
        }
    }
    
    @ViewBuilder
    func listViewFor(token: BalanceTokenUIDescription) -> some View {
        TokenSelectionRowView(token: token,
                              selectionType: selectionType)
            .udListItemInCollectionButtonPadding()
        .padding(EdgeInsets(4))
    }
}

// MARK: - Private methods
extension CopyMultichainWalletAddressesPullUpView {
    struct TokenSelectionRowView: View {
        
        let token: BalanceTokenUIDescription
        let selectionType: SelectionType
        @State private var icon: UIImage?
        
        var body: some View {
            UDListItemView(title: token.name,
                           subtitle: token.address,
                           subtitleStyle: .default,
                           imageType: .uiImage(icon ?? .init()),
                           imageStyle: .full,
                           rightViewStyle: rightViewStyle())
            .onAppear(perform: onAppear)
        }
        
        func rightViewStyle() -> UDListItemView.RightViewStyle {
            switch selectionType {
            case .copyOnly:
                return .generic(.init(type: .button(.init(icon: selectionType.icon,
                                                          callback: copyAction))))
            case .shareOnly:
                return .generic(.init(type: .button(.init(icon: selectionType.icon,
                                                          callback: shareAction))))
            case .allOptions(let qrCodeCallback):
                return .generic(.init(type: .menu(primary: .init(icon: .copyToClipboardIcon, callback: { }),
                                                  actions: [.init(title: String.Constants.copyWalletAddress.localized(), iconName: String.SystemImage.copy.name,
                                                                  callback: copyAction),
                                                            .init(title: String.Constants.shareAddress.localized(), iconName: "square.and.arrow.up",
                                                                  callback: shareAction),
                                                            .init(title: String.Constants.qrCode.localized(), iconName: "qrcode",
                                                                  callback: qrCodeCallback)])))
            }
        }
        
        func copyAction() {
            CopyWalletAddressPullUpHandler.copyToClipboard(address: token.address,
                                                           ticker: token.symbol)
        }
        @MainActor
        func shareAction() {
            shareItems([token.address], completion: nil)
        }
        private func onAppear() {
            loadTokenIcon()
        }
        
        private func loadTokenIcon() {
            token.loadTokenIcon { image in
                self.icon = image
            }
        }
    }
}

extension CopyMultichainWalletAddressesPullUpView {
    enum SelectionType {
        case copyOnly
        case shareOnly
        case allOptions(qrCodeCallback: MainActorCallback)
        
        var icon: Image {
            switch self {
            case .copyOnly, .allOptions:
                return .copyToClipboardIcon
            case .shareOnly:
                return .shareIcon
            }
        }
        
        var title: String {
            switch self {
            case .copyOnly, .allOptions:
                String.Constants.mpcWalletShareMultiChainDescription.localizedMPCProduct()
            case .shareOnly:
                String.Constants.chooseAddressToShare.localized()
            }
        }
        
        var subtitle: String? {
            switch self {
            case .copyOnly, .allOptions:
                nil
            case .shareOnly:
                String.Constants.mpcWalletShareMultiChainDescription.localizedMPCProduct()
            }
        }
    }
}

#Preview {
    CopyMultichainWalletAddressesPullUpView(tokens: [MockEntitiesFabric.Tokens.mockEthToken(),
                                                     MockEntitiesFabric.Tokens.mockMaticToken()],
                                            selectionType: .copyOnly)
}
