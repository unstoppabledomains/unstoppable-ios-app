//
//  DomainProfileSection.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.10.2022.
//

import Foundation

@MainActor
protocol DomainProfileSection: AnyObject, ViewAnalyticsLogger {
    
    associatedtype SectionData
    
    var controller: DomainProfileSectionsController? { get }
    var state: DomainProfileViewController.State { get set }
    
    @MainActor
    init(sectionData: SectionData,
         state: DomainProfileViewController.State,
         controller: DomainProfileSectionsController)

    func didSelectItem(_ item: DomainProfileViewController.Item)
    func fill(snapshot: inout DomainProfileSnapshot, withGeneralData generalData: DomainProfileGeneralData)
    func calculateChanges() -> [DomainProfileSectionChangeDescription]
    func areAllFieldsValid() -> Bool
    func update(sectionTypes: [DomainProfileSectionType])
    func update(state: DomainProfileViewController.State)
    /// This function called when some update profile requests are failed.
    /// Changes passed in argument reflects successfully updated changes.
    /// Each section that can edit data, should if related change was updated and update original data.
    /// This will allow to not show this change in the list of changes to update and not take into account when show number of changes. 
    func apply(changes: [DomainProfileSectionChangeDescription])
    func resetChanges()
    nonisolated func hideKeyboard()
}

extension DomainProfileSection {
    
    var analyticsName: Analytics.ViewName { controller?.analyticsName ?? .unspecified }
    
    func didSelectItem(_ item: DomainProfileViewController.Item) { }
    func calculateChanges() -> [DomainProfileSectionChangeDescription] { [] }
    func update(sectionTypes: [DomainProfileSectionType]) { }
    func update(state: DomainProfileViewController.State) {
        self.state = state
    }
    func apply(changes: [DomainProfileSectionChangeDescription]) { }

    nonisolated func logProfileSectionAnalytic(event: Analytics.Event,
                                               parameters: Analytics.EventParameters = [:]) {
        Task { @MainActor in
            guard let domain = controller?.generalData.domain else {
                Debugger.printFailure("Couldn't get domain in profile section", critical: true)
                return
            }
            logAnalytic(event: event, parameters: [.domainName : domain.name].adding(parameters))
        }
    }
    
    nonisolated func logProfileSectionButtonPressedAnalyticEvent(button: Analytics.Button,
                                                                 parameters: Analytics.EventParameters) {
        Task { @MainActor in
            guard let domain = controller?.generalData.domain else {
                Debugger.printFailure("Couldn't get domain in profile section", critical: true)
                return
            }
            logButtonPressedAnalyticEvents(button: button,
                                           parameters: [.domainName : domain.name].adding(parameters))
        }
    }
    
    func truncatedItems(_ items: [DomainProfileViewController.Item],
                        maxItems: Int,
                        isExpanded: Bool,
                        in section: DomainProfileViewController.Section) -> [DomainProfileViewController.Item] {
        if isExpanded {
            if items.count > maxItems {
                return items + [.hide(section: section)]
            }
            return items
        } else if items.count > maxItems {
            return Array(items.prefix(maxItems)) + [.showAll(section: section)]
        } else {
            return items
        }
    }
    
    nonisolated func hideKeyboard() {
        Task { @MainActor in
            controller?.viewController?.hideKeyboard()
        }
    }
    
    func uiChangeTypeBetween(oldValue: String,
                             newValue: String,
                             changeItem: DomainProfileGenericChangeDescription) -> DomainProfileSectionUIChangeType? {
        let old = oldValue.trimmedSpaces
        let new = newValue.trimmedSpaces
        
        guard new != old else { return nil }
        
        if old.isEmpty,
           !new.isEmpty {
            return .added(changeItem)
        } else if !old.isEmpty,
                  new.isEmpty {
            return .removed(changeItem)
        }
        
        return .updated(changeItem)
    }
}
