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
            DismissIndicatorView()
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
                return .generic(.button(.init(icon: selectionType.icon,
                                              callback: {
                    CopyWalletAddressPullUpHandler.copyToClipboard(address: token.address,
                                                                   ticker: token.symbol)
                })))
            case .shareOnly:
                return .generic(.button(.init(icon: selectionType.icon,
                                              callback: {
                    shareItems([token.address], completion: nil)
                })))
            }
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
        
        var icon: Image {
            switch self {
            case .copyOnly:
                return .copyToClipboardIcon
            case .shareOnly:
                return .shareIcon
            }
        }
        
        var title: String {
            switch self {
            case .copyOnly:
                "MPC Wallet has addresses across multiple blockchains"
            case .shareOnly:
                "Choose address to share"
            }
        }
        
        var subtitle: String? {
            switch self {
            case .copyOnly:
                nil
            case .shareOnly:
                "MPC Wallet has addresses across multiple blockchains"
            }
        }
    }
}

#Preview {
    CopyMultichainWalletAddressesPullUpView(tokens: [MockEntitiesFabric.Tokens.mockEthToken(),
                                                     MockEntitiesFabric.Tokens.mockMaticToken()],
                                            selectionType: .copyOnly)
}
