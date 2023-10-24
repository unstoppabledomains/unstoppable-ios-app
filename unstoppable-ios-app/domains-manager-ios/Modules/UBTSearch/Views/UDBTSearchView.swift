//
//  ContentView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 09.08.2023.
//
    
import SwiftUI

typealias UDBTSearchResultCallback = (_ discoveredDomain: BTDomainUIInfo, _ promotingDomain: DomainDisplayInfo)->()

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
    
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var controller: UBTController
    private var gridColumns = [GridItem(.flexible()),
                               GridItem(.flexible()),
                               GridItem(.flexible())]
    let searchResultCallback: UDBTSearchResultCallback
    private(set) var btState: UBTControllerState = .notReady
    @State private var promotingDomain: DomainDisplayInfo?
    @State private var promotingDomainImage: UIImage?
    @State private var canChangePromotingDomain: Bool = false
    @State private var isDomainsListPresented = false
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
                    if let promotingDomain {
                        Spacer()
                        Spacer()
                        domainSelectionView(domain: promotingDomain)
                        Spacer()
                        Spacer()
                        Spacer()
                        HStack { } // Placeholder to center domain selection
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
        .onAppear {
            logAnalytic(event: .viewDidAppear)
            setInitialPromotingDomain()
        }
        .modifier(ShowingPromotingDomainsList(isDomainsListPresented: $isDomainsListPresented,
                                              domainSelectionCallback: setPromotingDomain,
                                              currentDomainName: promotingDomain?.name))
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
        guard let promotingDomain else { return }
        UDVibration.buttonTap.vibrate()
        logButtonPressedAnalyticEvents(button: .btDomain)
        searchResultCallback(device, promotingDomain)
    }
    
    func scheduleAddMock() {
        #if DEBUG
        Task {
            try? await Task.sleep(seconds: 2)
            controller.addMock()
            scheduleAddMock()
        }
        #endif
    }
    
    func setInitialPromotingDomain() {
        Task {
            let domains = await appContext.dataAggregatorService.getDomainsDisplayInfo().availableForMessagingItems()
            guard !domains.isEmpty else { return }
            
            setPromotingDomain(domains[0])
            canChangePromotingDomain = domains.count > 1
        }
    }
    
    func setPromotingDomain(_ domain: DomainDisplayInfo) {
        promotingDomain = domain
        Task {
            promotingDomainImage = await appContext.imageLoadingService.loadImage(from: .domainItemOrInitials(domain, size: .default),
                                                                                  downsampleDescription: .icon)
        }
        controller.setPromotingDomainInfo(domain)
    }
    
    func showDomainsSelection() {
        isDomainsListPresented = true
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
    func domainSelectionView(domain: DomainDisplayInfo) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            showDomainsSelection()
        } label: {
            HStack(spacing: 8) {
                Image(uiImage: promotingDomainImage ?? .domainSharePlaceholder)
                    .resizable()
                    .scaledToFill()
                    .squareFrame(20)
                    .clipShape(Circle())
                
                Text(domain.name)
                    .foregroundColor(.white)
                    .font(.currentFont(size: 16, weight: .semibold))
                    .lineLimit(1)
                
                if canChangePromotingDomain{
                    Image.chevronDown
                        .resizable()
                        .scaledToFill()
                        .squareFrame(20)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
            }
        }.disabled(!canChangePromotingDomain)
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
    
    struct ShowingPromotingDomainsList: ViewModifier {
        @Binding var isDomainsListPresented: Bool
        let domainSelectionCallback: UBTPromotingDomainSelectionCallback
        let currentDomainName: DomainName?
        
        func body(content: Content) -> some View {
            content
                .sheet(isPresented: $isDomainsListPresented, content: {
                    UBTPromotingDomainSelectionView(domainSelectionCallback: domainSelectionCallback,
                                                    currentDomainName: currentDomainName)
                    .adaptiveSheet()
                })
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

