//
//  PublicDomainProfileDisplayInfoStorageService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.03.2024.
//

import Foundation

final class PublicDomainProfileDisplayInfoStorageService: CoreDataService {
    
    init() {
        super.init(inMemory: false)
    }
    
}

// MARK: - Open methods
extension PublicDomainProfileDisplayInfoStorageService {
    func store(profile: PublicDomainProfileDisplayInfo) {
        coreDataQueue.sync {
            let _ = try? convertPublicProfileToCoreDataPublicProfile(profile)
            saveContext(backgroundContext)
        }
    }
    
    func retrieveProfileFor(domainName: DomainName) throws -> PublicDomainProfileDisplayInfo {
        try coreDataQueue.sync {
            let domainNamePredicate = NSPredicate(format: "domainName == %@", domainName)
            let coreDataProfiles: [CoreDataPublicDomainProfile] = try getEntities(predicate: domainNamePredicate,
                                                                                      from: backgroundContext)
            guard let coreDataProfile = coreDataProfiles.first else {
                throw Error.entityNotFound
            }
            
            return try convertCoreDataProfileToPublicProfile(coreDataProfile)
        }
    }
}

// MARK: - Private methods
private extension PublicDomainProfileDisplayInfoStorageService {
    @discardableResult
    func convertPublicProfileToCoreDataPublicProfile(_ profile: PublicDomainProfileDisplayInfo) throws -> CoreDataPublicDomainProfile {
        let coreDataProfile: CoreDataPublicDomainProfile = try createEntity(in: backgroundContext)
        
        coreDataProfile.owner = profile.ownerWallet
        coreDataProfile.domainName = profile.domainName
        coreDataProfile.profileName = profile.profileName
        coreDataProfile.pfpURL = profile.pfpURL
        coreDataProfile.imageType = profile.imageType?.rawValue
        coreDataProfile.bannerURL = profile.bannerURL
        
        return coreDataProfile
    }
    
    func convertCoreDataProfileToPublicProfile(_ coreDataUserProfile: CoreDataPublicDomainProfile) throws -> PublicDomainProfileDisplayInfo {
        guard let domainName = coreDataUserProfile.domainName,
              let ownerWallet = coreDataUserProfile.owner else { throw Error.invalidEntity }
        var imageType: DomainProfileImageType?
        if let imageTypeRaw = coreDataUserProfile.imageType {
            imageType = DomainProfileImageType(rawValue: imageTypeRaw)
        }
        
        return PublicDomainProfileDisplayInfo(domainName: domainName,
                                              ownerWallet: ownerWallet,
                                              profileName: coreDataUserProfile.profileName,
                                              pfpURL: coreDataUserProfile.pfpURL,
                                              imageType: imageType,
                                              bannerURL: coreDataUserProfile.bannerURL)
    }
}

// MARK: - Open methods
extension PublicDomainProfileDisplayInfoStorageService {
    enum Error: Swift.Error {
        case entityNotFound
        case invalidEntity
    }
}
