//
//  DomainProfileSectionsController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.10.2022.
//

import UIKit

typealias UpdateProfileAccessResultCallback = (Result<Void, Error>)->()

protocol DomainProfileSectionsController: AnyObject, ViewAnalyticsLogger {
    
    var viewController: DomainProfileSectionViewProtocol? { get }
    var generalData: DomainProfileGeneralData { get }
    
    func sectionDidUpdate(animated: Bool)
    func backgroundImageDidUpdate(_ image: UIImage?)
    func avatarImageDidUpdate(_ image: UIImage?, avatarType: DomainProfileImageType)
    func updateAccessPreferences(attribute: ProfileUpdateRequest.Attribute, resultCallback: @escaping UpdateProfileAccessResultCallback)
    func manageDataOnTheWebsite()
}
