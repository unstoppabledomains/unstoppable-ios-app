//
//  HomeExploreSuggestedSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.03.2024.
//

import SwiftUI

typealias ProfileSuggestion = String

struct HomeExploreSuggestedProfilesSectionView: View {
    
    @State private var profilesSections: [[ProfileSuggestion]] = []
    private let horizontalSectionsSpacing: CGFloat = 30
    private var horizontalRowSizeReducer: CGFloat { horizontalSectionsSpacing + 15 }
    
    var body: some View {
        contentScrollView()
            .frame(height: 172)
            .onAppear(perform: onAppear)
    }
    
  
}

// MARK: - Private methods
private extension HomeExploreSuggestedProfilesSectionView {
    func onAppear() {
        let items = ["oleg.x",
                     "test.x",
                     "preview.x",
                     "preview2.x",
                     "preview3.x",
                     "preview4.x",
                     "preview5.x"]
        let maker = DomainProfileSuggestionSectionsMaker(profiles: items)
        self.profilesSections = maker.getProfilesMatrix()
    }
}

// MARK: - Views
private extension HomeExploreSuggestedProfilesSectionView {
    @MainActor @ViewBuilder
    func contentScrollView() -> some View {
        if #available(iOS 17.0, *) {
            fallbackPaginatedScrollView()
        } else {
            fallbackPaginatedScrollView()
        }
    }
    
    @available(iOS 17.0, *)
    @ViewBuilder
    func nativePaginatedScrollView() -> some View {
        ScrollView(.horizontal) {
            scrollableSectionsView()
                .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned)
    }
    
    @MainActor @ViewBuilder
    func fallbackPaginatedScrollView() -> some View {
        ScrollView(.horizontal) {
            scrollableSectionsView()
        }
    }
    
    @ViewBuilder
    func scrollableSectionsView() -> some View {
        LazyHStack(alignment: .top, spacing: horizontalSectionsSpacing) {
            ForEach(profilesSections, id: \.self) { profilesSection in
                LazyVStack {
                    ForEach(profilesSection, id: \.self) { profile in
                        rowForProfile(profile)
                    }
                }
                .modifier(SectionRowWidthModifier(horizontalRowSizeReducer: horizontalRowSizeReducer))
            }
        }
    }
    
    @ViewBuilder
    func rowForProfile(_ profile: String) -> some View {
        HStack {
            Text(profile)
            Spacer()
            Text(profile)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(Color.red)
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

struct DomainProfileSuggestion: Hashable, Codable, Identifiable {
    var id: String { domain }
    
    let address: String
    let reasons: [String]
    let score: Int
    let domain: String
    let imageUrl: String
    let imageType: String
}

struct DomainProfileSuggestionSectionsMaker {
    
    let sections: [Section]
    
    init(profiles: [ProfileSuggestion]) {
        let numOfProfilesInSection = 3
        let maxNumOfSections = 3
        let maxNumOfProfiles = numOfProfilesInSection * maxNumOfSections
        
        var profilesToTake = Array(profiles.prefix(maxNumOfProfiles))
        var sections: [Section] = []
        
        let numOfSections = Double(profilesToTake.count) / Double(numOfProfilesInSection)
        let numOfSectionsRounded = Int(ceil(numOfSections))
        for _ in 0..<numOfSectionsRounded {
            let sectionProfiles = Array(profilesToTake.prefix(numOfProfilesInSection))
            let section = Section(profiles: sectionProfiles)
            sections.append(section)
            profilesToTake = Array(profilesToTake.dropFirst(numOfProfilesInSection))
        }
        
        self.sections = sections
    }
    
    func getProfilesMatrix() -> [[ProfileSuggestion]] {
        sections.map { $0.profiles }
    }
    
    struct Section {
        let profiles: [ProfileSuggestion]
    }
    
}
