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
    private var sectionHeight: CGFloat { isIPSE ? 40 : 48 }

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
                viewForSection(section)
                    .frame(height: sectionHeight)
            }
        }
        .padding(.init(horizontal: 16))
        .offset(y: sectionHeight / 2)
    }
    
    @ViewBuilder
    func viewForSection(_ section: SectionType) -> some View {
        switch section {
        case .infoValue(let info):
            actionableViewForInfoValueSection(info)
        case .info(let info):
            viewForInfoSection(info)
        }
    }
    
    @ViewBuilder
    func actionableViewForInfoValueSection(_ info: InfoWithValueDescription) -> some View {
        if info.actions.isEmpty {
            viewForInfoValueSection(info)
        } else {
            Menu {
                ForEach(info.actions, id: \.self) { action in
                    Button {
                        UDVibration.buttonTap.vibrate()
                        logButtonPressedAnalyticEvents(button: action.analyticName, 
                                                       parameters: action.analyticParameters)
                        action.action()
                    } label: {
                        Label(
                            title: { Text(action.title) },
                            icon: { Image(systemName: action.iconName) }
                        )
                        Text(action.subtitle)
                    }
                }
            } label: {
                viewForInfoValueSection(info)
            }
            .onButtonTap {
                if let analyticName = info.analyticName {
                    logButtonPressedAnalyticEvents(button: analyticName)
                }
            }
        }
    }
    
    @ViewBuilder
    func viewForInfoValueSection(_ info: InfoWithValueDescription) -> some View {
        GeometryReader { geom in
            HStack(spacing: 16) {
                HStack {
                    Text(info.title)
                        .font(.currentFont(size: 16))
                        .foregroundStyle(Color.foregroundSecondary)
                    Spacer()
                }
                .frame(width: geom.size.width * 0.38)
                HStack(spacing: 8) {
                    UIImageBridgeView(image: info.icon,
                                      tintColor: info.iconColor)
                    .squareFrame(24)
                    .clipShape(Circle())
                    VStack(alignment: .leading,
                           spacing: -4) {
                        HStack(spacing: 8) {
                            Text(info.value)
                                .font(.currentFont(size: 16, weight: .medium))
                                .frame(height: 24)
                                .foregroundStyle(info.valueColor)
                            if let subValue = info.subValue {
                                Text(subValue)
                                    .font(.currentFont(size: 16, weight: .medium))
                                    .foregroundStyle(Color.foregroundSecondary)
                            }
                        }
                        if let errorMessage = info.errorMessage {
                            Text(errorMessage)
                                .font(.currentFont(size: 15, weight: .medium))
                                .foregroundStyle(Color.foregroundDanger)
                                .frame(height: 24)
                        }
                    }
                }
                Spacer()
            }
            .lineLimit(1)
            .frame(height: geom.size.height)
        }
    }
    
    @ViewBuilder
    func viewForInfoSection(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.currentFont(size: 13))
                .foregroundStyle(Color.foregroundMuted)
            Spacer()
        }
    }
}

// MARK: - Private methods
private extension ConfirmSendAssetReviewInfoView {
    enum SectionType: Hashable {
        case infoValue(InfoWithValueDescription)
        case info(String)
    }
    
    struct InfoWithValueDescription: Hashable {
        let title: String
        let icon: UIImage
        var iconColor: UIColor = .foregroundDefault
        let value: String
        var valueColor: Color = .foregroundDefault
        var subValue: String? = nil
        var errorMessage: String? = nil
        var actions: [InfoActionDescription] = []
        var analyticName: Analytics.Button? = nil
    }
    
    struct InfoActionDescription: Hashable {
        
        let title: String
        let subtitle: String
        let iconName: String
        let tintColor: UIColor
        var analyticName: Analytics.Button
        var analyticParameters: Analytics.EventParameters
        let action: EmptyCallback
        
        static func == (lhs: ConfirmSendAssetReviewInfoView.InfoActionDescription, rhs: ConfirmSendAssetReviewInfoView.InfoActionDescription) -> Bool {
            lhs.title == rhs.title &&
            lhs.subtitle == rhs.subtitle &&
            lhs.iconName == rhs.iconName
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(title)
            hasher.combine(subtitle)
            hasher.combine(iconName)
        }
        
    }
    
    func getBlockchainType() -> BlockchainType? {
        switch asset {
        case .token(let dataModel):
            dataModel.token.blockchainType
        case .domain(let domain):
            domain.blockchain ?? .Matic
        }
    }
    
    func getCurrentSections() -> [SectionType] {
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
    
    func getTransactionSpeedActions() -> [InfoActionDescription] {
        switch sourceWallet.udWallet.type {
        case .mpc:
            return  []
        default:
            return SendCryptoAsset.TransactionSpeed.allCases.map { txSpeed in
                InfoActionDescription(title: txSpeed.title,
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
                             token: BalanceTokenUIDescription) -> [SectionType] {
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
                          token: BalanceTokenUIDescription) -> SectionType {
        .infoValue(.init(title: String.Constants.feeEstimate.localized(),
                         icon: .tildaIcon,
                         value: gasUsdTitleFor(gasUsd: gasUsd),
                         errorMessage: getGasFeeErrorMessage(gasFee: gasFee,
                                                             token: token)))
    }
    
    func getFromWalletInfoSection() -> SectionType {
        .infoValue(.init(title: String.Constants.from.localized(),
                         icon: fromUserAvatar ?? sourceWallet.displayInfo.source.displayIcon,
                         value: sourceWallet.domainOrDisplayName))
    }
    
    func getChainInfoSection() -> SectionType? {
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
    
    func getSectionsForDomain() -> [SectionType] {
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
        ConnectCurve(radius: 24,
                     lineWidth: lineWidth,
                     sectionHeight: sectionHeight,
                     numberOfSections: numberOfSections)
        .stroke(lineWidth: lineWidth)
        .foregroundStyle(Color.white.opacity(0.08))
        .shadow(color: Color.foregroundOnEmphasis2,
                radius: 0, x: 0, y: -1)
        .frame(height: CGFloat(numberOfSections) * sectionHeight)
    }
}

// MARK: - Private methods
private extension ConfirmSendAssetReviewInfoView {
    struct ConnectCurve: Shape {
        let radius: CGFloat
        let lineWidth: CGFloat
        let padding: CGFloat = 16
        let sectionHeight: CGFloat
        let numberOfSections: Int
        
        func path(in rect: CGRect) -> Path {
            var path = Path()
            
            for section in 0..<numberOfSections {
                let sectionRect = getRectForSection(section, in: rect)
                if section % 2 == 0 {
                    let padding = section == 0 ? self.padding : 0.0
                    addCurveFromTopRightToBottomLeft(in: &path,
                                                     rect: sectionRect,
                                                     padding: padding)
                } else {
                    addCurveFromTopLeftToBottomRight(in: &path,
                                                     rect: sectionRect,
                                                     padding: 0)
                }
            }
            
            addFinalDot(in: &path, rect: rect)
            
            return path
        }
        
        func addFinalDot(in path: inout Path,
                         rect: CGRect) {
            let rect = getRectForSection(numberOfSections - 1, in: rect)
            let minX = rect.minX + lineWidth

            let center = CGPoint(x: minX,
                    y: rect.maxY)
            
            var circlePath = Path()
            circlePath.move(to: center)
            
            for i in 1...2 {
                circlePath.addArc(center: center,
                                  radius: CGFloat(i),
                                  startAngle: .degrees(0),
                                  endAngle: .degrees(360),
                                  clockwise: true)
            }
            
            path.addPath(circlePath)
        }
        
        func getRectForSection(_ section: Int,
                               in rect: CGRect) -> CGRect {
            var rect = rect
            rect.size.height = sectionHeight
            rect.origin.y = CGFloat(section) * sectionHeight
            return rect
        }
        
        func addCurveFromTopLeftToBottomRight(in path: inout Path,
                                              rect: CGRect,
                                              padding: CGFloat) {
            let startPoint = CGPoint(x: rect.minX + padding + lineWidth,
                                     y: rect.minY)
            path.move(to: startPoint)
            
            path.addArc(tangent1End: CGPoint(x: startPoint.x,
                                             y: rect.midY),
                        tangent2End: CGPoint(x: rect.minX + radius + padding,
                                             y: rect.midY),
                        radius: radius,
                        transform: .identity)
            
            path.addLine(to: CGPoint(x: rect.maxX - radius - padding,
                                     y: rect.midY))
            
            let maxX = rect.maxX - lineWidth - padding
            path.addArc(tangent1End: CGPoint(x: maxX,
                                             y: rect.midY),
                        tangent2End: CGPoint(x: maxX,
                                             y: rect.maxY),
                        radius: radius,
                        transform: .identity)
        }
        
        func addCurveFromTopRightToBottomLeft(in path: inout Path,
                                              rect: CGRect,
                                              padding: CGFloat) {
            let startPoint = CGPoint(x: rect.maxX - padding - lineWidth,
                                     y: rect.minY)
            path.move(to: startPoint)
            
            path.addArc(tangent1End: CGPoint(x: startPoint.x,
                                             y: rect.midY),
                        tangent2End: CGPoint(x: rect.maxX - radius - padding,
                                             y: rect.midY),
                        radius: radius,
                        transform: .identity)
            
            path.addLine(to: CGPoint(x: rect.minX + radius + padding,
                                     y: rect.midY))
            
            let minX = rect.minX + lineWidth
            path.addArc(tangent1End: CGPoint(x: minX,
                                             y: rect.midY),
                        tangent2End: CGPoint(x: minX,
                                             y: rect.maxY),
                        radius: radius,
                        transform: .identity)
        }
        
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
