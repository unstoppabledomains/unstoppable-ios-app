//
//  HomeExploreSuggestedSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.03.2024.
//

import SwiftUI

struct HomeExploreSuggestedProfilesSectionView: View {
    
    @EnvironmentObject var viewModel: HomeExploreViewModel

    @State private var profilesSections: [[DomainProfileSuggestion]] = []
    private let horizontalContentPadding: CGFloat = 16
    private let horizontalSectionsSpacing: CGFloat = 30
    @State private var currentPage: Int = 0
    @State private var scrollOffset: CGPoint = .zero
    
    private var horizontalRowSizeReducer: CGFloat { horizontalSectionsSpacing + horizontalContentPadding + 15 }
    
    var body: some View {
        Section {
            contentScrollView()
                .frame(height: 172)
                .onAppear(perform: onAppear)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        } header: {
            sectionHeaderView()
        }
        .onChange(of: viewModel.suggestedProfiles) { _ in
            setSuggestedProfiles()
        }
        .onChange(of: scrollOffset) { _ in
            updateCurrentPageForScrollOffset()
        }
    }
}

// MARK: - Private methods
private extension HomeExploreSuggestedProfilesSectionView {
    func onAppear() {
        setSuggestedProfiles()
    }
    
    func setSuggestedProfiles() {
        let profiles = viewModel.suggestedProfiles
        let maker = HomeExplore.DomainProfileSuggestionSectionsBuilder(profiles: profiles)
        self.profilesSections = maker.getProfilesMatrix()
    }
    
    @MainActor
    func updateCurrentPageForScrollOffset() {
        let pageWidth: CGFloat = screenSize.width - horizontalRowSizeReducer
        let page = scrollOffset.x / pageWidth
        currentPage = Int(page)
    }
}

// MARK: - Views
private extension HomeExploreSuggestedProfilesSectionView {
    @MainActor @ViewBuilder
    func contentScrollView() -> some View {
        if #available(iOS 17.0, *) {
            nativePaginatedScrollView()
        } else {
            fallbackPaginatedScrollView()
        }
    }
    
    @available(iOS 17.0, *)
    @ViewBuilder
    func nativePaginatedScrollView() -> some View {
        OffsetObservingScrollView(axes: .horizontal,
                                  offset: $scrollOffset) {
            scrollableSectionsView()
                .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
    }
    
    @MainActor @ViewBuilder
    func fallbackPaginatedScrollView() -> some View {
        OffsetObservingScrollView(axes: .horizontal,
                                  offset: $scrollOffset) {
            scrollableSectionsView()
        }
    }
    
    @ViewBuilder
    func scrollableSectionsView() -> some View {
        LazyHStack(alignment: .top, spacing: horizontalSectionsSpacing) {
            ForEach(profilesSections, id: \.self) { profilesSection in
                LazyVStack(spacing: 20) {
                    ForEach(profilesSection, id: \.self) { profile in
                        rowForProfile(profile)
                    }
                }
                .modifier(SectionRowWidthModifier(horizontalRowSizeReducer: horizontalRowSizeReducer))
            }
        }
        .padding(.init(horizontal: horizontalContentPadding))
    }
    
    @ViewBuilder
    func rowForProfile(_ profileSuggestion: DomainProfileSuggestion) -> some View {
        HomeExploreSuggestedProfileRowView(profileSuggestion: profileSuggestion)
    }
    
    @ViewBuilder
    func sectionHeaderView() -> some View {
        HStack {
            Text(String.Constants.suggestedForYou.localized())
                .font(.currentFont(size: 16, weight: .medium))
                .foregroundStyle(Color.foregroundDefault)
                .padding(.init(vertical: 8))
            
            Spacer()
            UDPageControlView(numberOfPages: profilesSections.count,
                        currentPage: $currentPage)
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Private methods
private extension HomeExploreSuggestedProfilesSectionView {
    struct SectionRowWidthModifier: ViewModifier {
        
        let horizontalRowSizeReducer: CGFloat
        
        func body(content: Content) -> some View {
            if #available(iOS 17.0, *) {
                content
                    .containerRelativeFrame(.horizontal) { length, axis in
                        length - horizontalRowSizeReducer
                    }
            } else {
                content
                    .frame(width: screenSize.width - horizontalRowSizeReducer)
            }
        }
    }
}

#Preview {
    HomeExploreSuggestedProfilesSectionView()
}
