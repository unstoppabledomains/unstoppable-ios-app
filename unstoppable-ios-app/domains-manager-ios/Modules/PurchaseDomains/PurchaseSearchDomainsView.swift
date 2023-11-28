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
    @State private var loadingError: Error?
    @State private var searchingText = ""
    @State private var cart: PurchaseDomainsCart = .empty
    @State private var scrollOffset: CGPoint = .zero
    
    var domainSelectedCallback: ((DomainToPurchase)->())
    var scrollOffsetCallback: ((CGPoint)->())? = nil
    
    var body: some View {
        OffsetObservingScrollView(offset: $scrollOffset) {
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
        .onChange(of: scrollOffset) { newValue in
            scrollOffsetCallback?(newValue)
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
        .padding(EdgeInsets(top: 56, leading: 0, bottom: 0, trailing: 0))
    }
    
    @ViewBuilder
    func searchView() -> some View {
        UDTextFieldView(text: $debounceObject.text,
                        placeholder: "domain.x",
                        hint: nil,
                        rightViewType: .clear,
                        rightViewMode: .whileEditing,
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
        } else if loadingError != nil {
            errorView()
        } else if !searchingText.isEmpty {
            noResultsView()
        } else if !suggestions.isEmpty {
            trendingListView()
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
                        domainSelectedCallback(domainInfo)
                    })
                }
            }
            .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
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
    func noResultsView() -> some View {
        UDCollectionSectionBackgroundView {
            VStack(alignment: .center, spacing: 16) {
                Image.grimaseIcon
                    .resizable()
                    .squareFrame(32)
                    .foregroundColor(.foregroundSecondary)
                VStack(spacing: 8) {
                    Text("No available domains")
                        .font(.currentFont(size: 20, weight: .bold))
                    Text("Try entering a different name.")
                        .font(.currentFont(size: 14))
                }
                .multilineTextAlignment(.center)
                .foregroundColor(.foregroundSecondary)
            }
            .padding(EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24))
        }
    }
    
    @ViewBuilder
    func errorView() -> some View {
        UDCollectionSectionBackgroundView {
            VStack(alignment: .center, spacing: 16) {
                Image.grimaseIcon
                    .resizable()
                    .squareFrame(32)
                    .foregroundColor(.foregroundSecondary)
                VStack(spacing: 8) {
                    Text("Something went wrong")
                        .font(.currentFont(size: 20, weight: .bold))
                    Text("Check your internet connection or try again later.")
                        .font(.currentFont(size: 14))
                }
                .multilineTextAlignment(.center)
                .foregroundColor(.foregroundSecondary)
            }
            .padding(EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24))
        }
    }
}

// MARK: - Private methods
private extension PurchaseSearchDomainsView {
    func onAppear() {
        loadSuggestions()
    }
    
    func loadSuggestions() {
        guard suggestions.isEmpty else { return }
        
        Task {
            self.suggestions = try await purchaseDomainsService.getDomainsSuggestions(hint: nil)
        }
    }
    
    func search(text: String) {
        let text = text.trimmedSpaces
        guard searchingText != text else { return }
        searchingText = text
        searchResult = []
        loadingError = nil
        
        Task {
            isLoading = true
            do {
                let searchResult = try await purchaseDomainsService.searchForDomains(key: text)
                guard text == self.searchingText else { return } // Result is irrelevant, search query has changed
                
                self.searchResult = searchResult
            } catch {
                loadingError = error
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
    PurchaseSearchDomainsView(domainSelectedCallback: { _ in })
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
