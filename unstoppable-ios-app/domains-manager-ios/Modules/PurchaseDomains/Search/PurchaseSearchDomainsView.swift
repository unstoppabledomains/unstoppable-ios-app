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
    @State private var scrollOffset: CGPoint = .zero
    @State private var skeletonItemsWidth: [CGFloat] = []
    
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
        .onChange(of: scrollOffset) { newValue in
            scrollOffsetCallback?(newValue)
        }
        .onAppear(perform: onAppear)
    }
}

// MARK: - Views
private extension PurchaseSearchDomainsView {
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 16) {
            Text(String.Constants.findYourDomain.localized())
                .titleText()
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
            loadingView()
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
    func loadingView() -> some View {
        UDCollectionSectionBackgroundView {
            VStack {
                ForEach(skeletonItemsWidth, id: \.self) { itemWidth in
                    domainSearchSkeletonRow(itemWidth: itemWidth)
                }
                .setSkeleton(.constant(true),
                             animationType: .solid(.backgroundSubtle))
            }
            .padding(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        }
        .padding()
    }
    
    @ViewBuilder
    func resultListView() -> some View {
        UDCollectionSectionBackgroundView {
            LazyVStack {
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
        .padding()
    }
    
    @ViewBuilder
    func trendingListView() -> some View {
        UDCollectionSectionBackgroundView(withShadow: true) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image.statsIcon
                        .resizable()
                        .squareFrame(16)
                    Text(String.Constants.trending.localized())
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
        .padding()
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
                    Text(String.Constants.noAvailableDomains.localized())
                        .font(.currentFont(size: 20, weight: .bold))
                    Text(String.Constants.tryEnterDifferentName.localized())
                        .font(.currentFont(size: 14))
                }
                .multilineTextAlignment(.center)
                .foregroundColor(.foregroundSecondary)
            }
            .padding(EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24))
        }
        .padding()
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
                    Text(String.Constants.somethingWentWrong.localized())
                        .font(.currentFont(size: 20, weight: .bold))
                    Text(String.Constants.pleaseCheckInternetConnection.localized())
                        .font(.currentFont(size: 14))
                }
                .multilineTextAlignment(.center)
                .foregroundColor(.foregroundSecondary)
            }
            .padding(EdgeInsets(top: 24, leading: 24, bottom: 24, trailing: 24))
        }
        .padding()
    }
}

// MARK: - Private methods
private extension PurchaseSearchDomainsView {
    func onAppear() {
        setupSekeletonItemsWidth()
        loadSuggestions()
        
    }
    
    func setupSekeletonItemsWidth() {
        guard skeletonItemsWidth.isEmpty else { return }
        
        for _ in 0..<10 {
            let width: CGFloat = 60 + CGFloat(arc4random_uniform(100))
            skeletonItemsWidth.append(width)
        }
    }
    
    func loadSuggestions() {
        guard suggestions.isEmpty else { return }
        
        Task {
            let suggestions = try await purchaseDomainsService.getDomainsSuggestions(hint: nil)
            self.suggestions = Array(suggestions.prefix(20))
        }
    }
    
    func search(text: String) {
        let text = text.trimmedSpaces
        guard searchingText != text else { return }
        searchingText = text
        searchResult = []
        loadingError = nil
        
        guard !searchingText.isEmpty else { return }
        
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
                    .clipShape(Circle())
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
        .frame(minHeight: UDListItemView.height)
    }
    
    @ViewBuilder
    func domainSearchSkeletonRow(itemWidth: CGFloat) -> some View {
        HStack(spacing: 8) {
            HStack(spacing: 16) {
                Image.check
                    .squareFrame(40)
                    .skeletonable()
                    .clipShape(Circle())
                Text("")
                    .frame(height: 12)
                    .frame(minWidth: itemWidth)
                    .skeletonable()
                    .skeletonCornerRadius(6)
            }
            Spacer()
            Text("")
                .frame(width: 40,
                       height: 12)
                .skeletonable()
                .skeletonCornerRadius(6)
        }
        .frame(height: UDListItemView.height)
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
