//
//  SearchDomainsView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 27.10.2023.
//

import SwiftUI
import Combine

struct PurchaseSearchDomainsView: View {
    
    @Environment(\.purchaseDomainsService) private var purchaseDomainsService
    @StateObject private var debounceObject = DebounceObject()
    @State private var suggestions: [DomainToPurchaseSuggestion] = []
    @State private var searchResult: [DomainToPurchase] = []
    @State private var isLoading = false
    @State private var searchingText = ""
    @State private var cart: PurchaseDomainsCart = .empty

    var body: some View {
        ScrollView {
            VStack {
                headerView()
                searchView()
                searchResultView()
            }
        }
        .animation(.default, value: UUID())
        .background(Color.backgroundDefault)
        .onReceive(purchaseDomainsService.cartPublisher.receive(on: DispatchQueue.main)) { cart in
            self.cart = cart
        }
        .navigationTitle("Search ")
        .onAppear(perform: onAppear)
    }
}

// MARK: - Views
private extension PurchaseSearchDomainsView {
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text("Find your domain")
                .titleText()
            Text("Search available domains")
                .subtitleText()
        }
    }
    
    @ViewBuilder
    func searchView() -> some View {
        UDTextFieldView(text: $debounceObject.text,
                        placeholder: "domain.x",
                        hint: nil,
                        rightViewType: .inspire({ }),
                        rightViewMode: .always,
                        leftViewType: .search)
        .onChange(of: debounceObject.debouncedText) { text in
            search(text: text)
        }
        .padding()
    }
    
    @ViewBuilder
    func searchResultView() -> some View {
        if isLoading {
            ProgressView()
        } else if !searchResult.isEmpty {
            resultListView()
        } else if !suggestions.isEmpty {
            trendingListView()
        }
    }
    
    @ViewBuilder
    func trendingListView() -> some View {
        UDCollectionSectionBackgroundView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image.statsIcon
                        .resizable()
                        .squareFrame(16)
                    Text("Trending")
                        .font(.currentFont(size: 14, weight: .semibold))
                }
                .foregroundColor(.foregroundDefault)
                
                FlowLayoutView(suggestions) { suggestion in
                    Button(action: {
                        search(text: suggestion.name)
                        debounceObject.text = suggestion.name
                    }, label: {
                        Text(suggestion.name)
                            .font(.currentFont(size: 14, weight: .medium))
                            .foregroundColor(.foregroundDefault)
                            .padding(EdgeInsets(top: 8, leading: 12,
                                                bottom: 8, trailing: 12))
                            .background(Color.backgroundMuted2)
                            .cornerRadius(16)
                    })
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    func resultListView() -> some View {
        UDCollectionSectionBackgroundView {
            VStack {
                ForEach(searchResult, id: \.name) { domainInfo in
                    UDCollectionListRowButton(content: {
                        domainSearchResultRow(domainInfo)
                    }, callback: {
                        
                    })
                }
            }
            .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
        }
    }
}

// MARK: - Private methods
private extension PurchaseSearchDomainsView {
    func onAppear() {
//        loadSuggestions()
        search(text: "asd")
    }
    
    func loadSuggestions() {
        guard suggestions.isEmpty else { return }
        
        Task {
            self.suggestions = try await purchaseDomainsService.getDomainsSuggestions(hint: nil)
        }
    }

    func search(text: String) {
        guard searchingText != text else { return }
        searchingText = text
        Task {
            isLoading = true
            do {
                let searchResult = try await purchaseDomainsService.searchForDomains(key: text)
                guard text == self.searchingText else { return } // Result is irrelevant, search query has changed
                
                self.searchResult = searchResult
            } catch {
                
            }
            isLoading = false
        }
    }
}

// MARK: - Views
private extension PurchaseSearchDomainsView {
    @ViewBuilder
    func domainSearchResultRow(_ domain: DomainToPurchase) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 16) {
                Image.check
                    .resizable()
                    .squareFrame(20)
                    .foregroundStyle(Color.foregroundSuccess)
                    .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                    .background(Color.backgroundSuccess)
                    .cornerRadius(30)
                Text(domain.name)
                    .font(.currentFont(size: 16, weight: .medium))
                    .foregroundStyle(Color.foregroundDefault)
            }
            Spacer()
            Text(formatCartPrice(domain.price))
                .font(.currentFont(size: 16))
                .foregroundStyle(Color.foregroundSecondary)
            Image.chevronRight
                .resizable()
                .squareFrame(20)
                .foregroundStyle(Color.foregroundMuted)
        }
        .frame(minHeight: 64)
    }
}

#Preview {
    PurchaseSearchDomainsView()
        .environment(\.purchaseDomainsService, MockFirebaseInteractionsService())
}

public final class DebounceObject: ObservableObject {
    @Published var text: String = ""
    @Published var debouncedText: String = ""
    private var bag = Set<AnyCancellable>()
    
    public init(dueTime: TimeInterval = 0.5) {
        $text
            .removeDuplicates()
            .debounce(for: .seconds(dueTime), scheduler: DispatchQueue.main)
            .sink(receiveValue: { [weak self] value in
                self?.debouncedText = value
            })
            .store(in: &bag)
    }
}
