//
//  PreviewPullUpViewService.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import UIKit

protocol PullUpViewServiceProtocol {
    func showApplePayRequiredPullUp(in viewController: UIViewController)
    func showBadgeInfoPullUp(in viewController: UIViewController,
                             badgeDisplayInfo: DomainProfileBadgeDisplayInfo,
                             domainName: String)
    func showShareDomainPullUp(domain: DomainDisplayInfo, qrCodeImage: UIImage, in viewController: UIViewController) async -> ShareDomainSelectionResult
    func showSaveDomainImageTypePullUp(description: SaveDomainImageDescription,
                                       in viewController: UIViewController) async throws -> SaveDomainSelectionResult
    func showAskToNotifyWhenRecordsUpdatedPullUp(in viewController: UIViewController) async throws
    func showWillNotifyWhenRecordsUpdatedPullUp(in viewController: UIViewController)
    func showDiscardRecordChangesConfirmationPullUp(in viewController: UIViewController) async throws

}

final class PullUpViewService: PullUpViewServiceProtocol {
    func showApplePayRequiredPullUp(in viewController: UIViewController) { }
    func showBadgeInfoPullUp(in viewController: UIViewController,
                             badgeDisplayInfo: DomainProfileBadgeDisplayInfo,
                             domainName: String) { }
    func showShareDomainPullUp(domain: DomainDisplayInfo, qrCodeImage: UIImage, in viewController: UIViewController) async -> ShareDomainSelectionResult {
        return .cancel
    }
    func showSaveDomainImageTypePullUp(description: SaveDomainImageDescription,
                                       in viewController: UIViewController) async throws -> SaveDomainSelectionResult {
        .init(image: description.originalDomainImage, style: .card)
    }
    func showAskToNotifyWhenRecordsUpdatedPullUp(in viewController: UIViewController) async throws { }
    func showWillNotifyWhenRecordsUpdatedPullUp(in viewController: UIViewController) { }
    func showDiscardRecordChangesConfirmationPullUp(in viewController: UIViewController) async throws { }
}


