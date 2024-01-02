//
//  DomainProfileUpdatingRecordsSection.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.11.2022.
//

import UIKit

@MainActor
final class DomainProfileUpdatingRecordsSection {
    typealias SectionData = DomainProfileUpdatingRecordsData
    
    weak var controller: DomainProfileSectionsController?
    private let topInfoData: SectionData
    var state: DomainProfileViewController.State
    private let id = UUID()
    private var isNotificationPermissionsGranted: Bool?
    private let sectionAnalyticName: String = "updatingRecords"

    init(sectionData: SectionData,
         state: DomainProfileViewController.State,
         controller: DomainProfileSectionsController) {
        self.topInfoData = sectionData
        self.state = state
        self.controller = controller
        NotificationCenter.default.addObserver(self, selector: #selector(checkForNotificationPermissions), name: UIApplication.didBecomeActiveNotification, object: nil)
    }
}

// MARK: - DomainProfileSection
extension DomainProfileUpdatingRecordsSection: DomainProfileSection {
    func didSelectItem(_ item: DomainProfileViewController.Item) {
        switch item {
        case .updatingRecords(let displayInfo):
            switch displayInfo.dataType {
            case .onChain, .mixed:
                logProfileSectionButtonPressedAnalyticEvent(button: .notifyWhenFinished,
                                                            parameters: [.section: sectionAnalyticName])
                if !displayInfo.isNotificationPermissionsGranted {
                    askForNotificationPermissions()
                } else {
                    showWeWillNotifyPullUp()
                }
            case .offChain:
                return
            }
        default:
            return
        }
    }
    
    func fill(snapshot: inout DomainProfileSnapshot, withGeneralData generalData: DomainProfileGeneralData) {
        func addUpdatingRecordsSection(dataType: DomainProfileViewController.State.UpdateProfileDataType) {
            snapshot.appendSections([.updatingRecords])
            snapshot.appendItems([.updatingRecords(displayInfo: .init(id: id,
                                                                      isNotificationPermissionsGranted: isNotificationPermissionsGranted ?? false,
                                                                      dataType: dataType))])
            if dataType != .offChain {
                if isNotificationPermissionsGranted == nil {
                    checkForNotificationPermissions()
                }
            }
        }
        
        switch state {
        case .updatingRecords:
            addUpdatingRecordsSection(dataType: .onChain)
        case .updatingProfile(let dataType):
            addUpdatingRecordsSection(dataType: dataType)
        default:
            return
        }
    }
    
    func areAllFieldsValid() -> Bool { true }
    func resetChanges() { }
}

// MARK: - Private methods
private extension DomainProfileUpdatingRecordsSection {
    @objc func checkForNotificationPermissions() {
        Task {
            let isGranted = await appContext.permissionsService.checkPermissionsFor(functionality: .notifications(options: []))
            self.isNotificationPermissionsGranted = isGranted
            controller?.sectionDidUpdate(animated: false)
        }
    }
    
    func askForNotificationPermissions() {
        guard let view = self.controller?.viewController else { return }
        
        Task {
            do {
                try await appContext.pullUpViewService.showAskToNotifyWhenRecordsUpdatedPullUp(in: view)
                await view.dismissPullUpMenu()
                isNotificationPermissionsGranted = await appContext.permissionsService.askPermissionsFor(functionality: .notifications(options: []), in: view, shouldShowAlertIfNotGranted: true)
                controller?.sectionDidUpdate(animated: false)
            }
        }
    }
    
    func showWeWillNotifyPullUp() {
        guard let view = self.controller?.viewController else { return }

        Task {
            await appContext.pullUpViewService.showWillNotifyWhenRecordsUpdatedPullUp(in: view)
        }
    }
}
