//
//  ActivityViewModel.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.03.2024.
//

import SwiftUI
import Combine

@MainActor
final class ActivityViewModel: ObservableObject, ViewAnalyticsLogger {
    
    var analyticsName: Analytics.ViewName { .homeActivity }
    
    @Published var searchKey: String = ""
    @Published var isKeyboardActive: Bool = false
    @Published var error: Error?
    
    private let router: HomeTabRouter
    private var selectedProfile: UserProfile
    private var cancellables: Set<AnyCancellable> = []
 
    private let userProfileService: UserProfileServiceProtocol
    private let walletsDataService: WalletsDataServiceProtocol
    
    init(router: HomeTabRouter,
         userProfileService: UserProfileServiceProtocol = appContext.userProfileService,
         walletsDataService: WalletsDataServiceProtocol = appContext.walletsDataService) {
        self.selectedProfile = router.profile
        self.router = router
        self.userProfileService = userProfileService
        self.walletsDataService = walletsDataService
        setup()
    }
}

// MARK: - Setup methods
private extension ActivityViewModel {
    func setup() {
        
    }
}
