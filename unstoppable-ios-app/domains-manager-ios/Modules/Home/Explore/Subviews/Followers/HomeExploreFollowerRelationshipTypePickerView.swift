//
//  HomeExploreFollowerRelationshipTypePickerView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.03.2024.
//

import SwiftUI

struct HomeExploreFollowerRelationshipTypePickerView: View {
    
    let profile: DomainProfileDisplayInfo
    @Binding var relationshipType: DomainProfileFollowerRelationshipType
    
    var body: some View {
        UDTabsPickerView(selectedTab: $relationshipType,
                         tabs: orderedRelationshipTypes) { relationshipType in
            let numberOfFollowers = profile.numberOfFollowersFor(relationshipType: relationshipType)
            if numberOfFollowers > 0 {
                return String(numberOfFollowers)
            }
            return nil
        }
    }
}

// MARK: - Private methods
private extension HomeExploreFollowerRelationshipTypePickerView {
    var orderedRelationshipTypes: [DomainProfileFollowerRelationshipType] { [.following, .followers] }
}

extension DomainProfileFollowerRelationshipType: UDTabPickable {
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .followers:
            String.Constants.followers.localized()
        case .following:
            String.Constants.following.localized()
        }
    }
}

#Preview {
    HomeExploreFollowerRelationshipTypePickerView(profile: MockEntitiesFabric.PublicDomainProfile.createPublicDomainProfileDisplayInfo(),
                                                  relationshipType: .constant(.followers))
}
