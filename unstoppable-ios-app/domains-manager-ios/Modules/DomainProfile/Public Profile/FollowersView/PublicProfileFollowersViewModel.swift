//
//  PublicProfileFollowersViewModel.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 29.08.2023.
//

import SwiftUI

extension PublicProfileFollowersView {
    
    @MainActor
    final class PublicProfileFollowersViewModel: ObservableObject, ProfileImageLoader {
       
        let domainName: DomainName
        let socialInfo: DomainProfileSocialInfo
        
        @Published var isLoadingPage = false
        @Published var selectedType: DomainProfileFollowerRelationshipType = .followers {
            didSet {
                didChangeRelationshipType()
            }
        }
        private let numberOfFollowersToTake = 40
        @Published private(set) var followersList: [DomainProfileFollowerDisplayInfo]?
        private var followersPaginationInfo: FollowersPaginationInfo = .init()
        @Published private(set)  var followingList: [DomainProfileFollowerDisplayInfo]?
        private var followingPaginationInfo: FollowersPaginationInfo = .init()
        
        var currentFollowersList: [DomainProfileFollowerDisplayInfo]? {
            getFollowersListFor(type: selectedType)
        }
        
        init(domainName: DomainName, socialInfo: DomainProfileSocialInfo) {
            self.domainName = domainName
            self.socialInfo = socialInfo
        }
        
        func loadIconIfNeededFor(follower: DomainProfileFollowerDisplayInfo) {
            guard follower.icon == nil else { return }
            let type = selectedType
            
            Task {
                let icon = await loadIconOrInitialsFor(follower: follower)
                
                if case .followers = type,
                   let i = followersList?.firstIndex(where: { $0.domain == follower.domain }) {
                    followersList?[i].icon = icon
                } else if case .following = type,
                          let i = followingList?.firstIndex(where: { $0.domain == follower.domain }) {
                    followingList?[i].icon = icon
                }
            }
        }
        
        func onAppear() {
            loadFollowersList()
        }
        
        func loadMoreContentIfNeeded(currentFollower: DomainProfileFollowerDisplayInfo) {
            if let currentFollowersList,
               let i = currentFollowersList.firstIndex(where: { $0.domain == currentFollower.domain }),
               i >= (currentFollowersList.count - 6),
               !isLoadingPage {
                loadFollowersList()
            }
        }
        
        private func didChangeRelationshipType() {
            if currentFollowersList == nil {
                loadFollowersList()
            }
        }
        
        private func loadFollowersList() {
            guard !isLoadingPage else { return }
            
            let type = self.selectedType
            let paginationInfo = getPaginationInfoFor(type: type)
            guard paginationInfo.canLoadMore else { return }
            
            isLoadingPage = true
            Task {
                do {
                    let response = try await NetworkService().fetchListOfFollowers(for: domainName,
                                                                                    relationshipType: type,
                                                                                    count: numberOfFollowersToTake,
                                                                                    cursor: paginationInfo.cursor)
                    var currentList = getFollowersListFor(type: type) ?? []
                    currentList.append(contentsOf: response.data.map({ DomainProfileFollowerDisplayInfo(domain: $0.domain) }))
                    let canLoadMore = currentList.count < response.meta.totalCount
                    
                    switch type {
                    case .followers:
                        followersPaginationInfo.cursor = response.meta.pagination.cursor
                        followersPaginationInfo.canLoadMore = canLoadMore
                        followersList = currentList
                    case .following:
                        followingPaginationInfo.cursor = response.meta.pagination.cursor
                        followingPaginationInfo.canLoadMore = canLoadMore
                        followingList = currentList
                    }
                } catch {
                    // TODO: - Handle error
                }
                isLoadingPage = false
            }
        }
     
        private func getFollowersListFor(type: DomainProfileFollowerRelationshipType) -> [DomainProfileFollowerDisplayInfo]? {
            switch selectedType {
            case .followers:
                return followersList
            case .following:
                return followingList
            }
        }
        
        private func getPaginationInfoFor(type: DomainProfileFollowerRelationshipType) -> FollowersPaginationInfo {
            switch selectedType {
            case .followers:
                return followersPaginationInfo
            case .following:
                return followingPaginationInfo
            }
        }
        
        private struct FollowersPaginationInfo {
            var cursor: Int?
            var canLoadMore: Bool = true
        }
    }
    
}
