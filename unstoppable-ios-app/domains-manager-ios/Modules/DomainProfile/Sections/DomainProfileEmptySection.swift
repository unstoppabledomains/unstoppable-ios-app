//
//  DomainProfileEmptySection.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.10.2022.
//

import Foundation

final class DomainProfileEmptySection: DomainProfileSection {
    
    typealias SectionData = String
    weak var controller: DomainProfileSectionsController?
    var state: DomainProfileViewController.State = .default

    required init(sectionData: SectionData,
                  state: DomainProfileViewController.State,
                  controller: DomainProfileSectionsController) { }
    
    func fill(snapshot: inout DomainProfileSnapshot, withGeneralData generalData: DomainProfileGeneralData) { }
    func areAllFieldsValid() -> Bool { true }
    func resetChanges() { }
}
