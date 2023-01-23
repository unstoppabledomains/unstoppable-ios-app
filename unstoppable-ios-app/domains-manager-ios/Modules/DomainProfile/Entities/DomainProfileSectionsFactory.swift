//
//  DomainProfileSectionsFactory.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.10.2022.
//

import Foundation

struct DomainProfileSectionsFactory {
    
    @MainActor
    func buildSectionOf(type: DomainProfileSectionType,
                        state: DomainProfileViewController.State,
                        controller: DomainProfileSectionsController) -> any DomainProfileSection {
        switch type {
        case .topInfo(let sectionData):
            return buildTopInfoProfileSectionWith(sectionData: sectionData, state: state, controller: controller)
        case .updatingRecords(let sectionData):
            return buildUpdatingRecordsProfileSectionWith(sectionData: sectionData, state: state, controller: controller)
        case .generalInfo(let sectionData):
            return buildGeneralInfoProfileSectionWith(sectionData: sectionData, state: state, controller: controller)
        case .socials(let sectionData):
            return buildSocialsProfileSectionWith(sectionData: sectionData, state: state, controller: controller)
        case .crypto(let sectionData):
            return buildCryptoProfileSectionWith(sectionData: sectionData, state: state, controller: controller)
        case .badges(let sectionData):
            return buildBadgesProfileSectionWith(sectionData: sectionData, state: state, controller: controller)
        case .web3Website(let sectionData):
            return buildWeb3WebsiteProfileSectionWith(sectionData: sectionData, state: state, controller: controller)
        case .metadata(let sectionData):
            return buildMetadataProfileSectionWith(sectionData: sectionData, state: state, controller: controller)
        }
    }
    
}

// MARK: - Private methods
private extension DomainProfileSectionsFactory {
    @MainActor
    func buildTopInfoProfileSectionWith(sectionData: DomainProfileTopInfoSection.SectionData,
                                        state: DomainProfileViewController.State,
                                        controller: DomainProfileSectionsController) -> any DomainProfileSection {
        DomainProfileTopInfoSection(sectionData: sectionData, state: state, controller: controller)
    }
    
    @MainActor
    func buildUpdatingRecordsProfileSectionWith(sectionData: DomainProfileUpdatingRecordsSection.SectionData,
                                                state: DomainProfileViewController.State,
                                                controller: DomainProfileSectionsController) -> any DomainProfileSection {
        DomainProfileUpdatingRecordsSection(sectionData: sectionData, state: state, controller: controller)
    }
    
    @MainActor
    func buildGeneralInfoProfileSectionWith(sectionData: DomainProfileGeneralInfoSection.SectionData,
                                            state: DomainProfileViewController.State,
                                            controller: DomainProfileSectionsController) -> any DomainProfileSection {
        DomainProfileGeneralInfoSection(sectionData: sectionData, state: state, controller: controller)
    }
    
    @MainActor
    func buildSocialsProfileSectionWith(sectionData: DomainProfileSocialsSection.SectionData,
                                        state: DomainProfileViewController.State,
                                        controller: DomainProfileSectionsController) -> any DomainProfileSection {
        DomainProfileSocialsSection(sectionData: sectionData, state: state, controller: controller)
    }
    
    @MainActor
    func buildCryptoProfileSectionWith(sectionData: DomainProfileCryptoSection.SectionData,
                                       state: DomainProfileViewController.State,
                                       controller: DomainProfileSectionsController) -> any DomainProfileSection {
        DomainProfileCryptoSection(sectionData: sectionData, state: state, controller: controller)
    }
    
    @MainActor
    func buildBadgesProfileSectionWith(sectionData: DomainProfileBadgesSection.SectionData,
                                       state: DomainProfileViewController.State,
                                       controller: DomainProfileSectionsController) -> any DomainProfileSection {
        DomainProfileBadgesSection(sectionData: sectionData, state: state, controller: controller)
    }
    
    @MainActor
    func buildWeb3WebsiteProfileSectionWith(sectionData: DomainProfileWeb3WebsiteSection.SectionData,
                                            state: DomainProfileViewController.State,
                                            controller: DomainProfileSectionsController) -> any DomainProfileSection {
        DomainProfileWeb3WebsiteSection(sectionData: sectionData, state: state, controller: controller)
    }
    
    @MainActor
    func buildMetadataProfileSectionWith(sectionData: DomainProfileMetadataSection.SectionData,
                                         state: DomainProfileViewController.State,
                                         controller: DomainProfileSectionsController) -> any DomainProfileSection {
        DomainProfileMetadataSection(sectionData: sectionData, state: state, controller: controller)
    }
}
