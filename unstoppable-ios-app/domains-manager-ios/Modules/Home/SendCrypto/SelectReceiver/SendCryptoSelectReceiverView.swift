//
//  SendCryptoSelectReceiverView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 20.03.2024.
//

import SwiftUI

struct SendCryptoSelectReceiverView: View {
    
    let sourceWallet: WalletEntity
    
    @State private var inputText: String = ""
    
    var body: some View {
        NavigationStack {
            List {
                inputFieldView()
                    .listRowSeparator(.hidden)
                scanQRView()
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
                .navigationTitle(String.Constants.send.localized())
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Private methods
private extension SendCryptoSelectReceiverView {
    @ViewBuilder
    func inputFieldView() -> some View {
        UDTextFieldView(text: $inputText,
                        placeholder: String.Constants.domainOrAddress.localized(),
                        hint: String.Constants.to.localized(),
                        rightViewType: .paste,
                        rightViewMode: .always,
                        autocapitalization: .never,
                        autocorrectionDisabled: true)
    }
    
    @ViewBuilder
    func scanQRView() -> some View {
        selectableRowView {
            UDListItemView(title: String.Constants.scanQRCodeTitle.localized(),
                           titleColor: .foregroundDefault,
                           subtitle: nil,
                           subtitleStyle: .default,
                           value: nil,
                           imageType: .image(.qrBarCodeIcon),
                           imageStyle: .centred(offset: .init(8),
                                                foreground: .foregroundDefault,
                                                background: .backgroundMuted2,
                                                bordered: true),
                           rightViewStyle: nil)
        } callback: {
            
        }
    }
    
    @ViewBuilder
    func selectableRowView(@ViewBuilder _ content: @escaping ()->(some View),
                           callback: @escaping EmptyCallback) -> some View {
        UDCollectionListRowButton {
            content()
            .padding(.init(horizontal: 8))
        } callback: {
            callback()
        }
        .padding(.init(horizontal: -8))
    }
}

#Preview {
    SendCryptoSelectReceiverView(sourceWallet: MockEntitiesFabric.Wallet.mockEntities()[0])
}
