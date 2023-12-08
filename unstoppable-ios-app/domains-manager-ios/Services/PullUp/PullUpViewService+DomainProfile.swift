//
//  PullUpViewService+DomainProfile.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.10.2023.
//

import UIKit

extension PullUpViewService {
    func showManageDomainRouteCryptoPullUp(in viewController: UIViewController,
                                           numberOfCrypto: Int) {
        let selectionViewHeight: CGFloat = 304
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.manageDomainRouteCryptoHeader.localized()),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: .walletBTCIcon,
                                                                                 size: .small),
                                                                     subtitle: .label(.text(String.Constants.manageDomainRouteCryptoDescription.localized())),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        showOrUpdate(in: viewController, pullUp: .routeCryptoInfo, contentView: selectionView, height: selectionViewHeight)
    }
    
    func showDomainProfileChangesConfirmationPullUp(in viewController: UIViewController,
                                                    changes: [DomainProfileSectionUIChangeType]) async throws {
        let selectionViewHeight: CGFloat = 268 + (CGFloat(changes.count) * PullUpCollectionViewCell.Height)
        
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            var didFireContinuation = false
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.confirmUpdates.localized()),
                                                                         contentAlignment: .center,
                                                                         actionButton: .main(content: .init(title: String.Constants.update.localized(),
                                                                                                            icon: nil,
                                                                                                            analyticsName: .confirm,
                                                                                                            action: { completion(.success(Void())) })),
                                                                         cancelButton: .secondaryDanger(content: .init(title: String.Constants.discard.localized(),
                                                                                                                       icon: nil,
                                                                                                                       analyticsName: .cancel,
                                                                                                                       action: { didFireContinuation = true; completion(.failure(PullUpError.cancelled)) }))),
                                                    items: changes)
            
            showOrUpdate(in: viewController, pullUp: .domainRecordsChangesConfirmation, contentView: selectionView, height: selectionViewHeight, closedCallback: { if !didFireContinuation { completion(.failure(PullUpError.dismissed)) } })
        }
    }
    
    func showDiscardRecordChangesConfirmationPullUp(in viewController: UIViewController) async throws {
        let selectionViewHeight: CGFloat = 276
        
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.discardChangesConfirmationMessage.localized()),
                                                                         contentAlignment: .center,
                                                                         actionButton: .main(content: .init(title: String.Constants.discardChanges.localized(),
                                                                                                            icon: nil,
                                                                                                            analyticsName: .confirm,
                                                                                                            action: { completion(.success(Void())) })),
                                                                         cancelButton: .cancelButton),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .discardDomainRecordsChangesConfirmation, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showPayGasFeeConfirmationPullUp(gasFeeInCents: Int,
                                         in viewController: UIViewController) async throws {
        let selectionViewHeight: CGFloat = 464
        let gasFeeLabel = UILabel()
        gasFeeLabel.translatesAutoresizingMaskIntoConstraints = false
        gasFeeLabel.setAttributedTextWith(text: String.Constants.gasFee.localized(),
                                          font: .currentFont(withSize: 16, weight: .medium),
                                          textColor: .foregroundSecondary)
        let gasFeeValueLabel = UILabel()
        gasFeeValueLabel.translatesAutoresizingMaskIntoConstraints = false
        let gasFeeString = String(format: "$%.02f", PaymentConfiguration.centsIntoDollars(cents: gasFeeInCents))
        gasFeeValueLabel.setAttributedTextWith(text: gasFeeString,
                                               font: .currentFont(withSize: 16, weight: .medium),
                                               textColor: .foregroundDefault)
        gasFeeValueLabel.setContentHuggingPriority(.init(rawValue: 1000), for: .horizontal)
        
        let stack = UIStackView(arrangedSubviews: [gasFeeLabel, gasFeeValueLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fill
        stack.alignment = .fill
        stack.spacing = 8
        stack.heightAnchor.constraint(equalToConstant: 24).isActive = true
        
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.gasFeePullUpTitle.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .gasFeeIcon,
                                                                                     size: .small),
                                                                         subtitle: .label(.highlightedText(.init(text: String.Constants.gasFeePullUpSubtitle.localized(),
                                                                                                                 highlightedText: [.init(highlightedText: String.Constants.gasFeePullUpSubtitleHighlighted.localized(),
                                                                                                                                         highlightedColor: .foregroundAccent)],
                                                                                                                 analyticsActionName: .learnMore,
                                                                                                                 action: { [weak self, weak viewController] in
                if let vc = viewController?.presentedViewController {
                    self?.showGasFeeInfoPullUp(in: vc, for: .Ethereum)
                    
                }
            }))),
                                                                         extraViews: [stack],
                                                                         actionButton: .applePay(content: .init(title: String.Constants.pay.localized(),
                                                                                                                icon: nil,
                                                                                                                analyticsName: .pay,
                                                                                                                action: { completion(.success(Void())) })),
                                                                         cancelButton: .cancelButton),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .gasFeeConfirmation, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showShareDomainPullUp(domain: DomainDisplayInfo, qrCodeImage: UIImage, in viewController: UIViewController) async -> ShareDomainSelectionResult {
        await withSafeCheckedMainActorContinuation(critical: false) { completion in
            let selectionViewHeight: CGFloat = NFCService.shared.isNFCSupported ? 584 : 512
            let shareDomainPullUpView = ShareDomainImagePullUpView()
            shareDomainPullUpView.setWithDomain(domain, qrImage: qrCodeImage)
            var isSelected = false
            shareDomainPullUpView.selectionCallback = { result in
                guard !isSelected else { return }
                
                isSelected = true
                completion(result)
            }
            
            showOrUpdate(in: viewController, pullUp: .shareDomainSelection, additionalAnalyticParameters: [.domainName: domain.name], contentView: shareDomainPullUpView, height: selectionViewHeight, closedCallback: {
                completion(.cancel)
            })
        }
    }
    
    func showSaveDomainImageTypePullUp(description: SaveDomainImageDescription,
                                       in viewController: UIViewController) async throws -> SaveDomainSelectionResult {
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionViewHeight: CGFloat = 316
            let shareDomainPullUpView = SaveDomainImageTypePullUpView()
            shareDomainPullUpView.setPreview(with: description)
            shareDomainPullUpView.selectionCallback = { result in
                completion(.success(result))
            }
            
            showOrUpdate(in: viewController, pullUp: .exportDomainPFPStyleSelection, contentView: shareDomainPullUpView, height: selectionViewHeight, closedCallback: {
                completion(.failure(PullUpError.cancelled))
            })
        }
    }
    
    func showDomainProfileInfoPullUp(in viewController: UIViewController) {
        showDomainProfileInfoPullUp(in: viewController, page: 1)
    }
    
    func showDomainProfileAccessInfoPullUp(in viewController: UIViewController) {
        showDomainProfileTutorialPullUp(in: viewController,
                                        useCase: .pullUpPrivacyOnly)
    }
    
    func showImageTooLargeToUploadPullUp(in viewController: UIViewController) async throws {
        let selectionViewHeight: CGFloat = 280
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.profileImageTooLargeToUploadTitle.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .smileIcon,
                                                                                     size: .small),
                                                                         subtitle: .label(.text(String.Constants.profileImageTooLargeToUploadDescription.localized())),
                                                                         actionButton: .secondary(content: .init(title: String.Constants.changePhoto.localized(),
                                                                                                                 icon: nil,
                                                                                                                 analyticsName: .changePhoto,
                                                                                                                 action: { completion(.success(Void())) }))),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            presentPullUpView(in: viewController, pullUp: .selectedImageTooLarge, contentView: selectionView, isDismissAble: true, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showSelectedImageBadPullUp(in viewController: UIViewController) {
        let selectionViewHeight: CGFloat = 280
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.somethingWentWrong.localized()),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: .smileIcon,
                                                                                 size: .small),
                                                                     subtitle: .label(.text(String.Constants.profileImageBadDescription.localized())),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        presentPullUpView(in: viewController, pullUp: .selectedImageBad, contentView: selectionView, isDismissAble: true, height: selectionViewHeight)
    }
    
    func showAskToNotifyWhenRecordsUpdatedPullUp(in viewController: UIViewController) async throws {
        let selectionViewHeight: CGFloat = 368
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.updatingRecords.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .refreshIcon,
                                                                                     size: .small),
                                                                         subtitle: .label(.text(String.Constants.profileUpdatingRecordsNotifyWhenFinishedDescription.localized())),
                                                                         actionButton: .main(content: .init(title: String.Constants.notifyMeWhenFinished.localized(),
                                                                                                            icon: .bellIcon,
                                                                                                            analyticsName: .notifyWhenFinished,
                                                                                                            action: { completion(.success(Void())) })),
                                                                         cancelButton: .gotItButton()),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            presentPullUpView(in: viewController, pullUp: .askToNotifyWhenRecordsUpdated, contentView: selectionView, isDismissAble: true, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showWillNotifyWhenRecordsUpdatedPullUp(in viewController: UIViewController) {
        let selectionViewHeight: CGFloat = 368
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.updatingRecords.localized()),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: .refreshIcon,
                                                                                 size: .small),
                                                                     subtitle: .label(.text(String.Constants.profileUpdatingRecordsWillNotifyWhenFinishedDescription.localized())),
                                                                     actionButton: .main(content: .init(title: String.Constants.weWillNotifyYouWhenFinished.localized(),
                                                                                                        icon: nil,
                                                                                                        analyticsName: .notifyWhenFinished,
                                                                                                        isSuccessState: true,
                                                                                                        action: { [weak viewController] in viewController?.dismissPullUpMenu()})),
                                                                     cancelButton: .gotItButton()),
                                                items: PullUpSelectionViewEmptyItem.allCases)
        
        presentPullUpView(in: viewController, pullUp: .willNotifyWhenRecordsUpdated, contentView: selectionView, isDismissAble: true, height: selectionViewHeight)
    }
    
    func showFailedToFetchProfileDataPullUp(in viewController: UIViewController,
                                            isRefreshing: Bool,
                                            animatedTransition: Bool) async throws {
        let selectionViewHeight: CGFloat = 344
        let refreshTitle = String.Constants.refresh.localized()
        let refreshingTitle = String.Constants.refreshing.localized()
        let buttonTitle = isRefreshing ? refreshingTitle : refreshTitle
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.profileLoadingFailedTitle.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .grimaseIcon,
                                                                                     size: .small),
                                                                         subtitle: .label(.text(String.Constants.profileLoadingFailedDescription.localized())),
                                                                         actionButton: .main(content: .init(title: buttonTitle,
                                                                                                            icon: nil,
                                                                                                            analyticsName: .refresh,
                                                                                                            isLoading: isRefreshing,
                                                                                                            isUserInteractionEnabled: !isRefreshing,
                                                                                                            action: { completion(.success(Void())) })),
                                                                         cancelButton: .secondary(content: .init(title: String.Constants.profileViewOfflineProfile.localized(),
                                                                                                                 icon: nil,
                                                                                                                 analyticsName: .viewOfflineProfile,
                                                                                                                 action: nil))),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .failedToFetchProfileData, contentView: selectionView, isDismissAble: true, height: selectionViewHeight, animated: animatedTransition, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showUpdateDomainProfileFailedPullUp(in viewController: UIViewController) async throws {
        let selectionViewHeight: CGFloat = 344
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.profileUpdateFailed.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .grimaseIcon,
                                                                                     size: .small),
                                                                         subtitle: .label(.text(String.Constants.pleaseTryAgain.localized())),
                                                                         actionButton: .main(content: .init(title: String.Constants.tryAgain.localized(),
                                                                                                            icon: nil,
                                                                                                            analyticsName: .tryAgain,
                                                                                                            action: { completion(.success(Void())) })),
                                                                         cancelButton: .cancelButton),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            presentPullUpView(in: viewController, pullUp: .updateDomainProfileFailed, contentView: selectionView, isDismissAble: true, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showTryUpdateDomainProfileLaterPullUp(in viewController: UIViewController) async throws {
        let selectionViewHeight: CGFloat = 344
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.tryAgainLater.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .hammerWrenchIcon24,
                                                                                     size: .small,
                                                                                     tintColor: .foregroundWarning),
                                                                         subtitle: .label(.text(String.Constants.profileTryUpdateProfileLater.localized())),
                                                                         actionButton: .main(content: .init(title: String.Constants.tryAgain.localized(),
                                                                                                            icon: nil,
                                                                                                            analyticsName: .tryAgain,
                                                                                                            action: { completion(.success(Void())) })),
                                                                         cancelButton: .cancelButton),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            presentPullUpView(in: viewController, pullUp: .tryUpdateProfileLater, contentView: selectionView, isDismissAble: true, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showUpdateDomainProfileSomeChangesFailedPullUp(in viewController: UIViewController,
                                                        changes: [DomainProfileSectionUIChangeFailedItem]) async throws {
        let selectionViewHeight: CGFloat = 268 + (CGFloat(changes.count) * PullUpCollectionViewCell.Height)
        
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.confirmUpdates.localized()),
                                                                         contentAlignment: .center,
                                                                         actionButton: .main(content: .init(title: String.Constants.tryAgain.localized(),
                                                                                                            icon: nil,
                                                                                                            analyticsName: .tryAgain,
                                                                                                            action: { completion(.success(Void())) })),
                                                                         cancelButton: .cancelButton),
                                                    items: changes)
            
            showOrUpdate(in: viewController, pullUp: .updateDomainProfileSomeChangesFailed, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showShowcaseYourProfilePullUp(for domain: DomainDisplayInfo,
                                       in viewController: UIViewController) async throws {
        let selectionViewHeight: CGFloat = 388
        
        let illustration = buildImageViewWith(image: .showcaseDomainProfileIllustration,
                                              width: 358,
                                              height: 56)
        
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(customHeader: illustration,
                                                                         title: .text(String.Constants.profileShowcaseProfileTitle.localized(domain.name)),
                                                                         contentAlignment: .center,
                                                                         subtitle: .label(.text(String.Constants.profileShowcaseProfileDescription.localized())),
                                                                         actionButton: .main(content: .init(title: String.Constants.shareProfile.localized(),
                                                                                                            icon: nil,
                                                                                                            analyticsName: .share,
                                                                                                            action: { completion(.success(Void())) })),
                                                                         cancelButton: .cancelButton),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            presentPullUpView(in: viewController, pullUp: .showcaseYourProfile, additionalAnalyticParameters: [.domainName: domain.name], contentView: selectionView, isDismissAble: true, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showUserProfilePullUp(with email: String,
                               domainsCount: Int,
                               in viewController: UIViewController) async throws -> UserProfileAction {
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { continuation in
            let selectionViewHeight: CGFloat = 288
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(email),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .domainsProfileIcon,
                                                                                     size: .small),
                                                                         subtitle: .label(.text(String.Constants.pluralNParkedDomains.localized(domainsCount, domainsCount)))),
                                                    items: UserProfileAction.allCases,
                                                    itemSelectedCallback: { legalType in
                continuation(.success(legalType))
            })
            
            showOrUpdate(in: viewController, pullUp: .loggedInUserProfile, contentView: selectionView, height: selectionViewHeight, closedCallback: { continuation(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showFinishSetupProfilePullUp(pendingProfile: DomainProfilePendingChanges,
                                      in viewController: UIViewController) async {
        let domainName = pendingProfile.domainName
        await withSafeCheckedMainActorContinuation(critical: false) { completion in
            let selectionViewHeight: CGFloat = 410
            let selectionView = PullUpSelectionView(configuration: .init(title: .highlightedText(.init(text: String.Constants.finishSetupProfilePullUpTitle.localized(String(domainName.prefix(40))),
                                                                                                       highlightedText: [.init(highlightedText: domainName, highlightedColor: .foregroundSecondary)],
                                                                                                       analyticsActionName: nil,
                                                                                                       action: nil)),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .infoIcon,
                                                                                     size: .large),
                                                                         subtitle: .label(.text(String.Constants.finishSetupProfilePullUpSubtitle.localized())),
                                                                         actionButton: .main(content: .init(title: String.Constants.signTransaction.localized(), icon: nil, analyticsName: .confirm, action: {
                completion(Void())
            }))),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showIfNotPresent(in: viewController,
                         pullUp: .finishProfileForPurchasedDomains,
                         contentView: selectionView,
                         isDismissAble: false,
                         height: selectionViewHeight)
        }
    }
    
    func showFinishSetupProfileFailedPullUp(in viewController: UIViewController) async throws  {
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionViewHeight: CGFloat = 308
            let title = String.Constants.finishSetupProfileFailedPullUpTitle.localized()
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(title),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .grimaseIcon,
                                                                                     size: .small),
                                                                         actionButton: .main(content: .init(title: String.Constants.tryAgain.localized(),
                                                                                                            icon: nil,
                                                                                                            analyticsName: .tryAgain,
                                                                                                            action: { completion(.success(Void())) })),
                                                                         cancelButton: .secondary(content: .init(title: String.Constants.cancelSetup.localized(),
                                                                                                                 icon: nil,
                                                                                                                 analyticsName: .cancel,
                                                                                                                 action: {
                completion(.failure(PullUpError.dismissed))
            }))),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showIfNotPresent(in: viewController,
                              pullUp: .failedToFinishProfileForPurchasedDomains,
                              contentView: selectionView,
                              isDismissAble: false,
                              height: selectionViewHeight)
        }
    }
}

// MARK: - Private methods
private extension PullUpViewService {
    func showDomainProfileInfoPullUp(in viewController: UIViewController,
                                     page: Int) {
        showDomainProfileTutorialPullUp(in: viewController,
                                        useCase: .pullUp)
    }
    
    func showDomainProfileTutorialPullUp(in viewController: UIViewController,
                                         useCase: DomainProfileTutorialViewController.UseCase) {
        var selectionViewHeight: CGFloat
        let pullUp: Analytics.PullUp
        
        switch useCase {
        case .largeTutorial:
            Debugger.printFailure("Should not be used in pull up", critical: true)
            return
        case .pullUp:
            selectionViewHeight = UIScreen.main.bounds.width > 400 ? 540 : 520
            pullUp = .domainProfileInfo
        case .pullUpPrivacyOnly:
            selectionViewHeight = 420
            pullUp = .domainProfileAccessInfo
        }
        
        switch deviceSize {
        case .i4Inch:
            selectionViewHeight -= 40
        case .i4_7Inch:
            selectionViewHeight -= 30
        default:
            Void()
        }
        
        let vc = DomainProfileTutorialViewController()
        vc.completionCallback = { [weak viewController] in
            viewController?.dismissPullUpMenu()
        }
        vc.useCase = useCase
        
        let pullUpVC = showOrUpdate(in: viewController, pullUp: pullUp, contentView: vc.view!, height: selectionViewHeight)
        
        vc.didMove(toParent: pullUpVC)
        pullUpVC.addChild(vc)
    }
}
