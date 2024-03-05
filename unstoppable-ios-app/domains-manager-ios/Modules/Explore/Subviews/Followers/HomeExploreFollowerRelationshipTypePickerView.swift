//
//  HomeExploreFollowerRelationshipTypePickerView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.03.2024.
//

import SwiftUI

struct HomeExploreFollowerRelationshipTypePickerView: View {
    
    let profile: PublicDomainProfileDisplayInfo
    @Binding var relationshipType: DomainProfileFollowerRelationshipType
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(orderedRelationshipTypes, id: \.self) { relationshipType in
                viewFor(relationshipType: relationshipType)
            }
        }
    }
}

// MARK: - Private methods
private extension HomeExploreFollowerRelationshipTypePickerView {
    var orderedRelationshipTypes: [DomainProfileFollowerRelationshipType] { [.following, .followers] }
    
    @ViewBuilder
    func viewFor(relationshipType: DomainProfileFollowerRelationshipType) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            self.relationshipType = relationshipType
        } label: {
            HStack(alignment: .top, spacing: 4) {
                Text(titleFor(relationshipType: relationshipType))
                    .font(.currentFont(size: 16, weight: .medium))
                Text(String(profile.numberOfFollowersFor(relationshipType: relationshipType)))
                    .font(.currentFont(size: 11, weight: .medium))
            }
            .foregroundStyle(foregroundStyleFor(relationshipType: relationshipType))
        }
        .buttonStyle(.plain)
    }
    
    func foregroundStyleFor(relationshipType: DomainProfileFollowerRelationshipType) -> Color {
        relationshipType == self.relationshipType ? Color.foregroundDefault : Color.foregroundSecondary
    }
    
    func titleFor(relationshipType: DomainProfileFollowerRelationshipType) -> String {
        switch relationshipType {
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
