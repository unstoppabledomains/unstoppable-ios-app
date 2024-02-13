//
//  ContentView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 09.08.2023.
//
    
import SwiftUI

typealias UDBTSearchResultCallback = (_ discoveredDomain: BTDomainUIInfo, _ promotingWallet: WalletEntity)->()

struct UDBTSearchView: View, ViewAnalyticsLogger {
    
    @MainActor
    static func instantiate(searchResultCallback: @escaping UDBTSearchResultCallback) -> UIViewController {
        let controller = UBTController()
        let vc = UIHostingController(rootView: UDBTSearchView(controller: controller,
                                                              searchResultCallback: searchResultCallback))
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        vc.view.backgroundColor = .clear
        return vc
    }
    
    @Environment(\.walletsDataService) var walletsDataService
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var controller: UBTController
    private var gridColumns = [GridItem(.flexible()),
                               GridItem(.flexible()),
                               GridItem(.flexible())]
    let searchResultCallback: UDBTSearchResultCallback
    private(set) var btState: UBTControllerState = .notReady
    @State private var promotingWallet: WalletEntity?
    @State private var promotingWalletImage: UIImage?
    @State private var canChangePromotingWallet: Bool = false
    @State private var isProfilesListPresented = false
    var analyticsName: Analytics.ViewName { .shakeToFind }

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.black.opacity(0.72),
                                                       currentColor]),
                           startPoint: .top,
                           endPoint: .bottom)
            
            .opacity(0.8)
            .ignoresSafeArea()
            
            UBTSearchingView(profilesFound: controller.readyDevices.count,
                             state: controller.btState)
            discoveredCardsView()
            
            VStack {
                HStack {
                    closeButton()
                        .offset(x: 20)
                        .squareFrame(24)
                    Spacer()
                    if let promotingWallet {
                        Spacer()
                        Spacer()
                        walletSelectionView(wallet: promotingWallet)
                        Spacer()
                        Spacer()
                        Spacer()
                        HStack { } // Placeholder to center wallet selection
                            .squareFrame(24)
                    }
                }
                Spacer()
            }
        }
        .background(.ultraThinMaterial)
        .onChange(of: controller.btState, perform: { newValue in
            if newValue == .ready {
                controller.startScanning()
            }
        })
        .onReceive(walletsDataService.selectedWalletPublisher.receive(on: DispatchQueue.main)) { selectedWallet in
            if let selectedWallet {
                setPromotingWallet(selectedWallet)
            }
        }
        .onAppear {
            logAnalytic(event: .viewDidAppear)
            setInitialPromotingWallet()
        }
        .modifier(ShowingWalletSelectionModifier(isSelectWalletPresented: $isProfilesListPresented))
    }
    
    init(controller: UBTController,
         searchResultCallback: @escaping UDBTSearchResultCallback) {
        self.controller = controller
        self.searchResultCallback = searchResultCallback
    }
}

// MARK: - Private methods
private extension UDBTSearchView {
    var currentColor: Color {
        switch controller.btState {
        case .notReady, .ready, .unauthorized:
            if controller.readyDevices.isEmpty {
                return .backgroundAccentEmphasis
            } else {
                return .backgroundSuccessEmphasis
            }
        case .setupFailed:
            return .foregroundDanger
        }
    }
    
    func didSelectDeviceToConnect(_ device: BTDomainUIInfo) {
        guard let promotingWallet else { return }
        UDVibration.buttonTap.vibrate()
        logButtonPressedAnalyticEvents(button: .btDomain)
        searchResultCallback(device, promotingWallet)
    }
    
    func scheduleAddMock() {
        #if DEBUG
        Task {
            await Task.sleep(seconds: 2)
            controller.addMock()
            scheduleAddMock()
        }
        #endif
    }
    
    func setInitialPromotingWallet() {
        guard let wallet = walletsDataService.selectedWallet ?? walletsDataService.wallets.first else { return }
        
        setPromotingWallet(wallet)
        canChangePromotingWallet = walletsDataService.wallets.count > 1
    }
    
    func setPromotingWallet(_ wallet: WalletEntity) {
        promotingWallet = wallet
        Task {
            if let domain = wallet.getDomainToViewPublicProfile() {
                promotingWalletImage = await appContext.imageLoadingService.loadImage(from: .domainItemOrInitials(domain, size: .default),
                                                                                      downsampleDescription: .icon)
            } else {
                promotingWalletImage = nil
            }
        }
        controller.setPromotingWalletInfo(wallet)
    }
    
    func showProfilesSelection() {
        isProfilesListPresented = true
    }
    
    func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Private methods
private extension UDBTSearchView {
    @ViewBuilder
    func closeButton() -> some View {
        Button(action: {
            UDVibration.buttonTap.vibrate()
            dismiss()
        }) {
            Image.cancelIcon
                .foregroundColor(.white)
        }
    }
    
    @ViewBuilder
    func walletSelectionView(wallet: WalletEntity) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            showProfilesSelection()
        } label: {
            HStack(spacing: 8) {
                Image(uiImage: promotingWalletImage ?? .domainSharePlaceholder)
                    .resizable()
                    .scaledToFill()
                    .squareFrame(20)
                    .clipShape(Circle())
                
                Text(wallet.domainOrDisplayName)
                    .foregroundColor(.white)
                    .font(.currentFont(size: 16, weight: .semibold))
                    .lineLimit(1)
                
                if canChangePromotingWallet{
                    Image.chevronDown
                        .resizable()
                        .scaledToFill()
                        .squareFrame(20)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
            }
        }.disabled(!canChangePromotingWallet)
    }
    
    @ViewBuilder
    func discoveredCardsView() -> some View {
        GeometryReader { geom in
            let cardWidth: CGFloat = 160
            let cardHeight: CGFloat = 208
            let cardsSpacing: CGFloat = 16
            let cardsRowWidth: CGFloat = CGFloat(controller.readyDevices.count) * cardWidth + CGFloat(controller.readyDevices.count - 1) * cardsSpacing
            let isLargeContent = geom.size.width < cardsRowWidth
            HStack {
                if !isLargeContent {
                    Spacer(minLength: (geom.size.width - cardsRowWidth) / 2 - cardsSpacing)
                }
                ScrollView(isLargeContent ? .horizontal : [], showsIndicators: false) {
                    LazyHStack(alignment: .center, spacing: cardsSpacing) {
                        ForEach(controller.readyDevices, id: \.id) { device in
                            Button {
                                UDVibration.buttonTap.vibrate()
                                dismiss()
                                didSelectDeviceToConnect(device)
                            } label: {
                                UBTDomainCardView(device: device)
                            }
                            .frame(width: cardWidth)
                        }
                    }
                    .padding(EdgeInsets(top: 0, leading: cardsSpacing,
                                        bottom: 0, trailing: cardsSpacing))
                }
                .animation(.easeInOut(duration: 0.5), value: controller.readyDevices)
            }
            .offset(y: geom.size.height
                    - cardHeight
                    - 64) // Bottom offset
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
//        let devices = ["iPhone 14 Pro", "iPhone 14 Pro Max", "iPhone SE (1st generation)", "iPhone SE (3rd generation)", "iPhone 13 mini"]
//
//        ForEach(devices, id: \.self) { device in
//            UDBTSearchView(controller: .init(domainEntity: DomainItem(name: "olegkuhkjdfsjhfdkhflakjhdfi748723642in.coin", blockchain: .Ethereum)), searchResultCallback: { _ in })
//                .previewDevice(PreviewDevice(rawValue: device))
//                .previewDisplayName(device)
//        }
        UDBTSearchView(controller: .init(), searchResultCallback: { _, _ in })
    }
}

