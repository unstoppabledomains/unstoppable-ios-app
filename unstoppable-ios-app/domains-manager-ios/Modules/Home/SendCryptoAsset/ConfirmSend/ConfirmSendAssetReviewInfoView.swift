//
//  ConfirmSendTokenReviewInfoView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.03.2024.
//

import SwiftUI

struct ConfirmSendAssetReviewInfoView: View, ViewAnalyticsLogger {
    
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    @Environment(\.imageLoadingService) var imageLoadingService
    
    private let lineWidth: CGFloat = 1
    @MainActor
    private var sectionHeight: CGFloat { ConnectCurveLine.sectionHeight }

    let asset: Asset
    let sourceWallet: WalletEntity
    
    @State private var fromUserAvatar: UIImage?

    var body: some View {
        ZStack {
            curveLine()
            infoSectionsView()
        }
        .onAppear(perform: onAppear)
    }
}

// MARK: - Private methods
private extension ConfirmSendAssetReviewInfoView {
    func onAppear() {
        Task {
            if let domain = sourceWallet.rrDomain {
                fromUserAvatar = await imageLoadingService.loadImage(from: .domainItemOrInitials(domain,
                                                                                                 size: .default),
                                                                     downsampleDescription: .mid)
            }
        }
    }
}

// MARK: - Private methods
private extension ConfirmSendAssetReviewInfoView {
    @MainActor
    @ViewBuilder
    func infoSectionsView() -> some View {
        VStack(spacing: 0) {
            ForEach(getCurrentSections(), id: \.self) { section in
                ConnectLineSectionView(section: section)
                    .frame(height: sectionHeight)
            }
        }
        .padding(.init(horizontal: 16))
        .offset(y: sectionHeight / 2)
    }
}

// MARK: - Private methods
private extension ConfirmSendAssetReviewInfoView {
    func getBlockchainType() -> BlockchainType? {
        switch asset {
        case .token(let dataModel):
            dataModel.token.blockchainType
        case .domain(let domain):
            domain.blockchain ?? .Matic
        }
    }
    
    func getCurrentSections() -> [ConnectLineSectionView.SectionType] {
        switch asset {
        case .token(let dataModel):
            getSectionsForToken(selectedTxSpeed: dataModel.txSpeed,
                                gasUsd: dataModel.gasFeeUsd, 
                                gasFee: dataModel.gasFee, 
                                token: dataModel.token)
        case .domain:
            getSectionsForDomain()
        }
    }
    
    func getTransactionSpeedActions() -> [ConnectLineSectionView.InfoActionDescription] {
        switch sourceWallet.udWallet.type {
        case .mpc:
            return  []
        default:
            return SendCryptoAsset.TransactionSpeed.allCases.map { txSpeed in
                ConnectLineSectionView.InfoActionDescription(title: txSpeed.title,
                                                             subtitle: txSpeedSubtitleFor(txSpeed: txSpeed),
                                                             iconName: txSpeed.iconName,
                                                             tintColor: tintColorFor(txSpeed: txSpeed),
                                                             analyticName: .selectTransactionSpeed,
                                                             analyticParameters: [.transactionSpeed: txSpeed.rawValue],
                                                             action: { didSelectTransactionSpeed(txSpeed) })
            }
        }
    }
    
    func txSpeedSubtitleFor(txSpeed: SendCryptoAsset.TransactionSpeed) -> String {
        guard case .token(let dataModel) = asset,
              let gwei = dataModel.gasGweiFor(speed: txSpeed) else { return "" }
        
        return "\(gwei) Gwei"
    }
    
    func tintColorFor(txSpeed: SendCryptoAsset.TransactionSpeed) -> UIColor {
        switch txSpeed {
        case .normal:
                .foregroundDefault
        case .fast:
                .foregroundWarning
        case .urgent:
                .foregroundDanger
        }
    }
    
    
    func didSelectTransactionSpeed(_ transactionSpeed: SendCryptoAsset.TransactionSpeed) {
        switch asset {
        case .token(let dataModel):
            dataModel.txSpeed = transactionSpeed
        case .domain:
            Debugger.printFailure("Incorrect state", critical: true)
        }
    }
    
    func getSectionsForToken(selectedTxSpeed: SendCryptoAsset.TransactionSpeed,
                             gasUsd: Double?,
                             gasFee: Double?,
                             token: BalanceTokenUIDescription) -> [ConnectLineSectionView.SectionType] {
        [getFromWalletInfoSection(),
         getChainInfoSection(),
         .infoValue(.init(title: String.Constants.speed.localized(),
                          icon: .chevronGrabberVertical,
                          iconColor: .foregroundSecondary,
                          value: selectedTxSpeed.title,
                          valueColor: Color(uiColor: tintColorFor(txSpeed: selectedTxSpeed)),
                          actions: getTransactionSpeedActions(),
                          analyticName: .transactionSpeedSelection)),
         getGasFeeSection(gasUsd: gasUsd,
                          gasFee: gasFee,
                          token: token),
         .info(String.Constants.sendCryptoReviewPromptMessage.localized())].compactMap({ $0 })
    }
    
    func getGasFeeErrorMessage(gasFee: Double?,
                               token: BalanceTokenUIDescription) -> String? {
        guard let gasFee else { return nil }
        
        if let parent = token.parent,
           parent.balance <= gasFee {
            return String.Constants.insufficientToken.localized(parent.symbol)
        }
        return nil
    }
    
    func getGasFeeSection(gasUsd: Double?,
                          gasFee: Double?,
                          token: BalanceTokenUIDescription) -> ConnectLineSectionView.SectionType {
        .infoValue(.init(title: String.Constants.feeEstimate.localized(),
                         icon: .tildaIcon,
                         value: gasUsdTitleFor(gasUsd: gasUsd),
                         errorMessage: getGasFeeErrorMessage(gasFee: gasFee,
                                                             token: token)))
    }
    
    func getFromWalletInfoSection() -> ConnectLineSectionView.SectionType {
        .infoValue(.init(title: String.Constants.from.localized(),
                         icon: fromUserAvatar ?? sourceWallet.displayInfo.source.displayIcon,
                         value: sourceWallet.domainOrDisplayName))
    }
    
    func getChainInfoSection() -> ConnectLineSectionView.SectionType? {
        if let blockchain = getBlockchainType() {
            return .infoValue(.init(title: String.Constants.chain.localized(),
                                    icon: chainIcon,
                                    value: blockchain.fullName))
        }
        return nil
    }
    
    func gasUsdTitleFor(gasUsd: Double?) -> String {
        if let gasUsd {
            return "$\(gasUsd.formatted(toMaxNumberAfterComa: 4))"
        }
        return ""
    }
    
    func getSectionsForDomain() -> [ConnectLineSectionView.SectionType] {
        [getFromWalletInfoSection(),
         getChainInfoSection(),
         .info(String.Constants.sendCryptoReviewPromptMessage.localized())].compactMap { $0 }
    }
    
    var chainIcon: UIImage {
        switch getBlockchainType() {
        case .Ethereum:
            .ethereumIcon
        default:
            .polygonIcon
        }
    }
}

// MARK: - Private methods
private extension ConfirmSendAssetReviewInfoView {
    var numberOfSections: Int { getCurrentSections().count }

    @MainActor
    @ViewBuilder
    func curveLine() -> some View {
        ConnectDarkCurveLine(numberOfSections: numberOfSections)
    }
}

// MARK: - Open methods
extension ConfirmSendAssetReviewInfoView {
    enum Asset {
        case token(ConfirmSendTokenDataModel)
        case domain(DomainDisplayInfo)
    }
}

#Preview {
    ConfirmSendAssetReviewInfoView(asset: .token(.init(data: .init(receiver: MockEntitiesFabric.SendCrypto.mockReceiver(),
                                                                   token: MockEntitiesFabric.Tokens.mockUIToken(),
                                                                   amount: .usdAmount(3998234.3), 
                                                                   receiverAddress: "0x1234567890"))),
                                   sourceWallet: MockEntitiesFabric.Wallet.mockEntities()[0])
}
