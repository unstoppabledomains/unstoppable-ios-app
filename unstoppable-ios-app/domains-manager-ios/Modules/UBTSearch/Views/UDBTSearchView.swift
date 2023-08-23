//
//  ContentView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 09.08.2023.
//
    
import SwiftUI

typealias UDBTSearchResultCallback = (BTDeviceUI)->()

struct UDBTSearchView: View {
    
    @MainActor
    static func instantiate(domain: any DomainEntity,
                            searchResultCallback: @escaping UDBTSearchResultCallback) -> UIViewController {
        let controller = UBTController(domainEntity: domain)
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
    private(set) var btState: UBTControllerState = .ready
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [.black.opacity(0.72),
                                                       .backgroundAccentEmphasis]),
                           startPoint: .top,
                           endPoint: .bottom)
            .opacity(0.8)
            .ignoresSafeArea()

//                if controller.readyDevices.isEmpty {
//                    switch controller.btState {
//                    case .notReady:
////                        Text("Launching...")
//                        Text("")
//                            .foregroundColor(.white)
//                            .bold()
//                    case .setupFailed:
//                        Text("Setup failed")
//                            .foregroundColor(.white)
//                    case .unauthorized:
//                        VStack(spacing: 20) {
//                            Text("Please give access to Bluetooth functionality to find people nearby")
//                                .foregroundColor(.white)
//                                .multilineTextAlignment(.center)
//                            Button("Give access") {
//                                // TODO: - Ask for BT permissions
//                            }
//                            .padding(EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14))
//                            .font(.headline)
//                            .background(Color.blue)
//                            .foregroundColor(.white)
//                            .clipShape(Capsule())
//                        }
//                        .padding()
//                    case .ready:
//                        UBTSearchingView(profilesFound: controller.readyDevices.count)
//                    }
//                }
            
            UBTSearchingView(profilesFound: controller.readyDevices.count)
            discoveredCardsView()
            
            VStack {
                HStack {
                    closeButton()
                        .offset(x: 20)
                    Spacer()
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
            scheduleAddMock()
        }
    }
    
    init(controller: UBTController,
         searchResultCallback: @escaping UDBTSearchResultCallback) {
        self.controller = controller
        self.searchResultCallback = searchResultCallback
    }
}

// MARK: - Private methods
private extension UDBTSearchView {
    func didSelectDeviceToConnect(_ device: BTDeviceUI) {
        searchResultCallback(device)
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
    
    private func dismiss() {
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
        UDBTSearchView(controller: .init(domainEntity: DomainItem(name: "olegkuhkjdfsjhfdkhflakjhdfi748723642in.coin", blockchain: .Ethereum)), searchResultCallback: { _ in })
    }
}

