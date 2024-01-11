//
//  HomeWalletView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.01.2024.
//

import SwiftUI

struct HomeWalletView: View {
    
    @State private var tokens: [TokenDescription] = TokenDescription.mock()
    @State private var domains: [DomainDisplayInfo] = createMockDomains()
    @State private var selectedContentType: ContentType = .tokens
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            List {
                walletHeaderView()
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                walletActionsView()
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                contentTypeSelector()
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .padding(.vertical)
                contentForSelectedType()
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .clearListBackground()
            .background(.clear)
            .animation(.default, value: UUID())
        }
        .background(Color.backgroundDefault)
        .navigationTitle("Vault 1")
        .navigationBarTitleDisplayMode(.inline)

    }
}

// MARK: - Private methods
private extension HomeWalletView {
    @ViewBuilder
    func walletHeaderView() -> some View {
        VStack(alignment: .center, spacing: 20) {
            Image(uiImage: UIImage.Preview.previewPortrait!)
                .resizable()
                .squareFrame(80)
                .clipShape(Circle())
                .background(Color.clear)
            
            Button {
                
            } label: {
                HStack {
                    Text("dans.crypto")
                        .font(.currentFont(size: 16, weight: .medium))
                    
                    Image(systemName: "chevron.compact.down")
                        .squareFrame(20)
                }
                .foregroundStyle(Color.foregroundSecondary)
            }
            .buttonStyle(.plain)
            
            Text("200$")
                .titleText()
        }
        .frame(maxWidth: .infinity)
//        .background(Color.black)
    }
    
    @ViewBuilder
    func walletActionsView() -> some View {
        HStack {
            ForEach(WalletAction.allCases, id: \.self) { action in
                walletActionView(for: action)
            }
        }
    }
    
    @ViewBuilder
    func walletActionView(for action: WalletAction) -> some View {
        Button {
            
        } label: {
            VStack(spacing: 4) {
                action.icon
                    .resizable()
                    .renderingMode(.template)
                    .squareFrame(20)
                Text(action.title)
                    .font(.currentFont(size: 13, weight: .medium))
                    .frame(height: 20)
            }
            .foregroundColor(.foregroundAccent)
            .frame(height: 72)
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(Color.backgroundOverlay)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(lineWidth: 1)
                    .foregroundStyle(Color.borderMuted)
            }
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    func contentTypeSelector() -> some View {
        Picker("", selection: $selectedContentType) {
            ForEach(ContentType.allCases, id: \.self) { contentType in
                Text(contentType.title)
            }
        }
        .pickerStyle(.segmented)
    }
    
    @ViewBuilder
    func contentForSelectedType() -> some View {
        switch selectedContentType {
        case .tokens:
            tokensContentView()
        case .collectibles:
            collectiblesContentView()
        case .domains:
            domainsContentView()
        }
    }
    
    @ViewBuilder
    func tokensContentView() -> some View {
        VStack(spacing: 0) {
            ForEach(tokens) { token in
                Button {
                    
                } label: {
                    HStack(spacing: 16) {
                        Image(uiImage: .ethBGLarge)
                            .resizable()
                            .squareFrame(40)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(token.fullName)
                                .font(.currentFont(size: 16, weight: .medium))
                                .foregroundStyle(Color.foregroundDefault)
                            Text("\(Int(token.value)) \(token.ticker)")
                                .font(.currentFont(size: 14, weight: .regular))
                                .foregroundStyle(Color.foregroundSecondary)
                        }
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("$\(Int(token.fiatValue))")
                                .font(.currentFont(size: 16, weight: .medium))
                                .foregroundStyle(Color.foregroundDefault)
                        }
                    }
                    .frame(height: 64)
                }
            }
        }
    }

    @ViewBuilder
    func collectiblesContentView() -> some View {
        
    }

    @ViewBuilder
    func domainsContentView() -> some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(domains, id: \.name) { domain in
                Image(uiImage: UIImage.Preview.previewLandscape!)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    enum WalletAction: String, CaseIterable {
        case receive, profile, copy, more
        
        var title: String { rawValue }
        var icon: Image { .systemGlobe }
    }
    
    enum ContentType: String, CaseIterable {
        case tokens, collectibles, domains
        
        var title: String { rawValue }
    }
}

#Preview {
    NavigationView {
        HomeWalletView()
    }
}

struct TokenDescription: Hashable, Identifiable {
    var id: String { ticker }
    
    let ticker: String
    let fullName: String
    let value: Double
    let fiatValue: Double
    
    
    static func mock() -> [TokenDescription] {
        var tickers = ["ETH", "MATIC", "USDC", "1INCH",
                       "SOL", "USDT", "DOGE", "DAI"]
        tickers += ["AAVE", "ADA", "AKT", "APT", "ARK", "CETH"]
        var tokens = [TokenDescription]()
        for ticker in tickers {
            let value = Double(arc4random_uniform(10000)) + 20
            let token = TokenDescription(ticker: ticker,
                                         fullName: ticker,
                                         value: value,
                                         fiatValue: value)
            tokens.append(token)
            
        }
        
        return tokens
    }
}

func createMockDomains() -> [DomainDisplayInfo] {
    var domains = [DomainDisplayInfo]()
    
    for i in 0..<100 {
        let domain = DomainDisplayInfo(name: "oleg_\(i).x", 
                                       ownerWallet: "",
                                       isSetForRR: false)
        domains.append(domain)
    }
    
    return domains
}
