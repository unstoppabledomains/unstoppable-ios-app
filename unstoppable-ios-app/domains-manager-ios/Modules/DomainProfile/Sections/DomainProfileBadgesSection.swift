//
//  DomainProfileBadgesSection.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.11.2022.
//

import Foundation
import Combine

@MainActor
final class DomainProfileBadgesSection {
    typealias SectionData = BadgesInfo
    
    weak var controller: DomainProfileSectionsController?
    private var badgesData: SectionData
    var state: DomainProfileViewController.State
    private let id = UUID()
    private var sectionId = UUID()
    private var isSectionExpanded = false
    private let sectionAnalyticName: String = "badges"
    private var isRefreshingBadges = false
    private var isBadgesUpToDate = false

    init(sectionData: SectionData,
         state: DomainProfileViewController.State,
         controller: DomainProfileSectionsController) {
        self.badgesData = sectionData
        self.controller = controller
        self.state = state
        setBadgesUpToDateFor(nextRefreshDate: nil)
    }
    
    static func numberOfBadgesInTheRow() -> Int {
        if deviceSize == .i4Inch {
            return 4
        }
        return 5
    }
}

// MARK: - DomainProfileSection
extension DomainProfileBadgesSection: DomainProfileSection {
    func didSelectItem(_ item: DomainProfileViewController.Item) {
        switch item {
        case .hide(let section):
            logProfileSectionButtonPressedAnalyticEvent(button: .hide,
                                                        parameters: [.section: sectionAnalyticName])
            setSectionIfCurrent(section, isExpanded: false)
        case .showAll(let section):
            logProfileSectionButtonPressedAnalyticEvent(button: .showAll,
                                                        parameters: [.section: sectionAnalyticName])
            setSectionIfCurrent(section, isExpanded: true)
        case .badge(let displayInfo):
            UDVibration.buttonTap.vibrate()
            let badge = displayInfo.badge
            logProfileSectionButtonPressedAnalyticEvent(button: .badge,
                                                        parameters: [.section: sectionAnalyticName,
                                                                     .fieldName: badge.name])
            didSelect(displayInfo: displayInfo)
        default:
            return
        }
    }
    
    func fill(snapshot: inout DomainProfileSnapshot, withGeneralData generalData: DomainProfileGeneralData) {
        snapshot.appendSections([.dashesSeparator()])
        let maxItems = Self.numberOfBadgesInTheRow() * 3
        switch state {
        case .default, .updatingRecords, .loadingError, .updatingProfile:
            let isRefreshBadgesButtonEnabled = state == .default || state == .updatingRecords
            let sectionHeaderDescription = sectionHeader(isLoading: false,
                                                         isButtonEnabled: isRefreshBadgesButtonEnabled)
            let section: DomainProfileViewController.Section = .badges(headerDescription: sectionHeaderDescription)
            snapshot.appendSections([section])
            
            var items: [DomainProfileViewController.Item] = badgesData.badges.map({ .badge(displayInfo: .init(badge: $0, isExploreWeb3Badge: false)) })
            if items.count <= 1 {
                items.append(.badge(displayInfo: .init(badge: .exploreWeb3, isExploreWeb3Badge: true)))
            }
            
            if items.count > maxItems {
                if isSectionExpanded {
                    snapshot.appendItems(items)
                } else {
                    snapshot.appendItems(Array(items.prefix(maxItems)))
                }
                
                snapshot.appendSections([.showHideItem()])
                if isSectionExpanded {
                    snapshot.appendItems([.hide(section: section)])
                } else {
                    snapshot.appendItems([.showAll(section: section)])
                }
            } else {
                snapshot.appendItems(items)
            }
            snapshot.appendSections([.footer(sectionFooter())])
        case .loading:
            snapshot.appendSections([.badges(headerDescription: sectionHeader(isLoading: true,
                                                                              isButtonEnabled: false))])
            for _ in 0..<maxItems {
                snapshot.appendItems([.loading(style: .hideShow, uiConfiguration: .profileBadges)])
            }

            snapshot.appendSections([.showHideItem()])
            snapshot.appendItems([.loading(style: .hideShow)])
        }
    }
    
    func areAllFieldsValid() -> Bool { true }
    func update(sectionTypes: [DomainProfileSectionType]) {
        for sectionType in sectionTypes {
            switch sectionType {
            case .badges(let data):
                self.badgesData = data
                
                return
            default:
                continue
            }
        }
    }
    func resetChanges() { }
}

// MARK: - Private methods
private extension DomainProfileBadgesSection {
    func sectionHeader(isLoading: Bool,
                       isButtonEnabled: Bool) -> DomainProfileSectionHeader.HeaderDescription {
        var headerButton: DomainProfileSectionHeader.HeaderButton? = nil
        
        if !isBadgesUpToDate {
            /// Refresh action is available
            let isEnabled = isRefreshingBadges ? false : isButtonEnabled
            headerButton = .refresh(isEnabled: isEnabled,
                                    isSpinning: isRefreshingBadges,
                                    refreshingTitle: String.Constants.profileRefreshingBadgesTitle.localized(),
                                    callback: { [weak self] in
                self?.logProfileSectionButtonPressedAnalyticEvent(button: .refresh,
                                                                  parameters: [:])
                self?.refreshDomainBadges()
            })
        } else {
            /// Refresh action is not available
            headerButton = .init(title: String.Constants.profileBadgesUpToDate.localized(),
                                 icon: .checkmark,
                                 isEnabled: false,
                                 action: { })
        }
        
        
        let numberOfBadges = badgesData.badges.count
        let secondaryTitle = numberOfBadges == 0 ? "" : String(numberOfBadges)

        return .init(title: String.Constants.domainProfileSectionBadgesName.localized(),
                     secondaryTitle: secondaryTitle,
                     button: headerButton,
                     isLoading: isLoading,
                     id: sectionId)
    }
    
    @MainActor
    func sectionFooter() -> String {
        String.Constants.profileBadgesFooter.localized(controller?.generalData.domain.ownerWallet?.walletAddressTruncated ?? "")
    }
    
    func setSectionIfCurrent(_ section: DomainProfileViewController.Section,
                             isExpanded: Bool) {
        switch section {
        case .badges:
            self.isSectionExpanded = isExpanded
            controller?.viewController?.view.endEditing(true)
            controller?.sectionDidUpdate(animated: true)
        default:
            return
        }
    }

    func didSelect(displayInfo: DomainProfileBadgeDisplayInfo) {
        Task { @MainActor in
            guard let view = controller?.viewController,
                  let domain = controller?.generalData.domain else { return }
            
            appContext.pullUpViewService.showBadgeInfoPullUp(in: view,
                                                             badgeDisplayInfo: displayInfo,
                                                             domainName: domain.name)
        }
    }
    
    func refreshDomainBadges() {
        Task {
            guard let controller else { return }
            let domain = controller.generalData.domain.toDomainItem()
            updateRefreshingStatusAndUpdateSectionHeader(isRefreshingBadges: true)
            do {
                try await NetworkService().refreshDomainBadges(for: domain)
                setBadgesUpToDateFor(nextRefreshDate: nil)
                updateRefreshingStatusAndUpdateSectionHeader(isRefreshingBadges: false)
            } catch {
                appContext.toastMessageService.showToast(.failedToRefreshBadges, isSticky: false)
                updateRefreshingStatusAndUpdateSectionHeader(isRefreshingBadges: false)
            }
        }
    }
    
    func updateRefreshingStatusAndUpdateSectionHeader(isRefreshingBadges: Bool) {
        if self.isRefreshingBadges != isRefreshingBadges {
            self.isRefreshingBadges = isRefreshingBadges
            sectionId = .init()
            controller?.sectionDidUpdate(animated: false)
        }
    }
    
    func setBadgesUpToDateFor(nextRefreshDate: Date?) {
        guard let nextRefreshDate else {
            self.isBadgesUpToDate = false
            return
        }
        isBadgesUpToDate = nextRefreshDate > Date()
    }
}

extension BadgesInfo.BadgeInfo {
    static let exploreWeb3: BadgesInfo.BadgeInfo = .init(code: UUID().uuidString,
                                                         name: String.Constants.profileBadgeExploreWeb3TitleFull.localized(),
                                                         logo: "",
                                                         description: String.Constants.profileBadgeExploreWeb3DescriptionFull.localized())
}
