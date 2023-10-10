//
//  PullUpViewService+Messaging.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.10.2023.
//

import UIKit

extension PullUpViewService {
    func showMessagingChannelInfoPullUp(channel: MessagingNewsChannel,
                                        in viewController: UIViewController) async throws {
        var selectionViewHeight: CGFloat = 304
        
        let labelWidth = UIScreen.main.bounds.width - 32 // 16 * 2 side offsets
        
        let title = channel.name
        let titleHeight = title.height(withConstrainedWidth: labelWidth,
                                       font: .currentFont(withSize: 22, weight: .bold))
        selectionViewHeight += titleHeight
        
        let subtitle = channel.info
        let subtitleHeight = subtitle.height(withConstrainedWidth: labelWidth,
                                             font: .currentFont(withSize: 16, weight: .regular))
        selectionViewHeight += subtitleHeight
        
        
        let subscribersLabel = UILabel(frame: .zero)
        subscribersLabel.translatesAutoresizingMaskIntoConstraints = false
        subscribersLabel.setAttributedTextWith(text: String.Constants.messagingNFollowers.localized(channel.subscriberCount),
                                               font: .currentFont(withSize: 16, weight: .medium),
                                               textColor: .foregroundSecondary)
        let subscribersIcon = UIImageView(image: .reputationIcon20)
        subscribersIcon.translatesAutoresizingMaskIntoConstraints = false
        subscribersIcon.tintColor = .foregroundSecondary
        
        let subscribersStack = UIStackView(arrangedSubviews: [subscribersIcon, subscribersLabel])
        subscribersStack.translatesAutoresizingMaskIntoConstraints = false
        subscribersStack.axis = .horizontal
        subscribersStack.alignment = .center
        subscribersStack.spacing = 8
        
        let subscribersView = UIView()
        subscribersView.translatesAutoresizingMaskIntoConstraints = false
        subscribersView.addSubview(subscribersStack)
        subscribersView.layer.cornerRadius = 16
        subscribersView.backgroundColor = .backgroundSubtle
        
        
        let subscribersContainer = UIView()
        subscribersContainer.translatesAutoresizingMaskIntoConstraints = false
        subscribersContainer.backgroundColor = .clear
        subscribersContainer.addSubview(subscribersView)
        
        NSLayoutConstraint.activate([subscribersContainer.heightAnchor.constraint(equalToConstant: 32),
                                     subscribersView.centerXAnchor.constraint(equalTo: subscribersContainer.centerXAnchor),
                                     subscribersView.centerYAnchor.constraint(equalTo: subscribersContainer.centerYAnchor),
                                     subscribersView.topAnchor.constraint(equalTo: subscribersContainer.topAnchor),
                                     subscribersView.bottomAnchor.constraint(equalTo: subscribersContainer.bottomAnchor),
                                     subscribersStack.leadingAnchor.constraint(equalTo: subscribersView.leadingAnchor, constant: 12),
                                     subscribersView.trailingAnchor.constraint(equalTo: subscribersStack.trailingAnchor, constant: 12),
                                     subscribersStack.topAnchor.constraint(equalTo: subscribersView.topAnchor),
                                     subscribersStack.bottomAnchor.constraint(equalTo: subscribersView.bottomAnchor),
                                     subscribersIcon.widthAnchor.constraint(equalToConstant: 20),
                                     subscribersIcon.heightAnchor.constraint(equalToConstant: 20)
                                    ])
        
        var avatarImage = await appContext.imageLoadingService.loadImage(from: .url(channel.icon),
                                                                         downsampleDescription: nil) ?? .init()
        avatarImage = avatarImage.circleCroppedImage(size: 56)
        let buttonTitle = String.Constants.profileOpenWebsite.localized()
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(title),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: avatarImage,
                                                                                     size: .large),
                                                                         subtitle: .label(.text(subtitle)),
                                                                         extraViews: [subscribersContainer],
                                                                         actionButton: .main(content: .init(title: buttonTitle,
                                                                                                            icon: nil,
                                                                                                            analyticsName: .logOut,
                                                                                                            action: { completion(.success(Void())) }))),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            presentPullUpView(in: viewController, pullUp: .messagingChannelInfo, contentView: selectionView, isDismissAble: true, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showMessagingBlockConfirmationPullUp(blockUserName: String,
                                              in viewController: UIViewController) async throws {
        let selectionViewHeight: CGFloat = 276
        let title: String = String.Constants.messagingBlockUserConfirmationTitle.localized(blockUserName)
        let buttonTitle: String = String.Constants.block.localized()
        
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { completion in
            let selectionView = PullUpSelectionView(configuration: .init(title: .highlightedText(.init(text: title,
                                                                                                       highlightedText: [.init(highlightedText: blockUserName,
                                                                                                                               highlightedColor: .foregroundSecondary)],
                                                                                                       analyticsActionName: nil,
                                                                                                       action: nil)),
                                                                         contentAlignment: .center,
                                                                         actionButton: .primaryDanger(content: .init(title: buttonTitle,
                                                                                                                     icon: nil,
                                                                                                                     analyticsName: .block,
                                                                                                                     action: { completion(.success(Void())) })),
                                                                         cancelButton: .cancelButton),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .logOutConfirmation, contentView: selectionView, height: selectionViewHeight, closedCallback: { completion(.failure(PullUpError.dismissed)) })
        }
    }
    
    func showUnencryptedMessageInfoPullUp(in viewController: UIViewController) {
        let selectionViewHeight: CGFloat = 288
        let shareDomainPullUpView = UnencryptedMessageInfoPullUpView()
        showOrUpdate(in: viewController, pullUp: .unencryptedMessageInfo, contentView: shareDomainPullUpView, height: selectionViewHeight)
        shareDomainPullUpView.dismissCallback = { [weak viewController] in
            viewController?.dismissPullUpMenu()
        }
    }
    
    func showHandleChatLinkSelectionPullUp(in viewController: UIViewController) async throws -> Chat.ChatLinkHandleAction {
        try await withSafeCheckedThrowingMainActorContinuation(critical: false) { continuation in
            let selectionViewHeight: CGFloat = 456
            let selectionView = PullUpSelectionView(configuration: .init(title: .text(String.Constants.warning.localized()),
                                                                         contentAlignment: .center,
                                                                         icon: .init(icon: .warningIconLarge, size: .large, tintColor: .foregroundWarning),
                                                                         subtitle: .label(.text(String.Constants.messagingOpenLinkWarningMessage.localized())),
                                                                         actionButton: .raisedTertiary(content: .init(title: String.Constants.messagingOpenLinkActionTitle.localized(), icon: .safari, analyticsName: .clear, action: {
                continuation(.success(.handle))
            })),
                                                                         extraButton: .primaryDanger(content: .init(title: String.Constants.messagingCancelAndBlockActionTitle.localized(), icon: .systemMinusCircle, analyticsName: .clear, action: {
                continuation(.success(.block))
                
            })),
                                                                         cancelButton: .cancelButton),
                                                    items: PullUpSelectionViewEmptyItem.allCases)
            
            showOrUpdate(in: viewController, pullUp: .settingsLegalSelection, contentView: selectionView, height: selectionViewHeight, closedCallback: { continuation(.failure(PullUpError.dismissed)) })
        }
    }

    func showGroupChatInfoPullUp(groupChatDetails: MessagingGroupChatDetails,
                                 in viewController: UIViewController) async {
        let groupMembers = groupChatDetails.allMembers
        let title = String.Constants.pluralNMembers.localized(groupMembers.count, groupMembers.count)
        let avatarImage = await MessagingImageLoader.buildImageForGroupChatMembers(groupMembers,
                                                                                   iconSize: 56) ?? .domainSharePlaceholder
        let admins = Set(groupChatDetails.adminWallets)
        let memberItems = groupChatDetails.members.map({ MessagingChatUserPullUpSelectionItem(userInfo: $0, isAdmin: admins.contains($0.wallet), isPending: false) })
        let pendingMemberItems = groupChatDetails.pendingMembers.map({ MessagingChatUserPullUpSelectionItem(userInfo: $0, isAdmin: admins.contains($0.wallet), isPending: true) })
        let items = memberItems + pendingMemberItems
        
        let baseContentHeight: CGFloat = 216
        let requiredSelectionViewHeight = baseContentHeight + items.reduce(0.0, { $0 + $1.height })
        let topScreenOffset: CGFloat = 40
        let maxHeight = UIScreen.main.bounds.height - topScreenOffset
        let shouldScroll = requiredSelectionViewHeight > maxHeight
        let selectionViewHeight = min(requiredSelectionViewHeight, maxHeight)
        
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(title),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: avatarImage,
                                                                                 size: .large),
                                                                     isScrollingEnabled: shouldScroll),
                                                items: items)
        
        let pullUpVC = presentPullUpView(in: viewController, pullUp: .messagingChannelInfo, contentView: selectionView, isDismissAble: true, height: selectionViewHeight)
        
        selectionView.itemSelectedCallback = { [weak pullUpVC] item in
            guard let domainName = item.userInfo.domainName else { return }
            
            pullUpVC?.openLink(.domainProfilePage(domainName: domainName))
        }
    }
    
    
    func showCommunityChatInfoPullUp(communityDetails: MessagingCommunitiesChatDetails,
                                     in viewController: UIViewController) async {
        let groupMembers = communityDetails.allMembers
        let title = String.Constants.pluralNMembers.localized(groupMembers.count, groupMembers.count)
        let avatarImage = await MessagingImageLoader.buildImageForGroupChatMembers(groupMembers,
                                                                                   iconSize: 56) ?? .domainSharePlaceholder
        let admins = Set(communityDetails.adminWallets)
        let memberItems = communityDetails.members.map({ MessagingChatUserPullUpSelectionItem(userInfo: $0, isAdmin: admins.contains($0.wallet), isPending: false) })
        let pendingMemberItems = communityDetails.pendingMembers.map({ MessagingChatUserPullUpSelectionItem(userInfo: $0, isAdmin: admins.contains($0.wallet), isPending: true) })
        let items = memberItems + pendingMemberItems
        
        let baseContentHeight: CGFloat = 216
        let requiredSelectionViewHeight = baseContentHeight + items.reduce(0.0, { $0 + $1.height })
        let topScreenOffset: CGFloat = 40
        let maxHeight = UIScreen.main.bounds.height - topScreenOffset
        let shouldScroll = requiredSelectionViewHeight > maxHeight
        let selectionViewHeight = min(requiredSelectionViewHeight, maxHeight)
        
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(title),
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: avatarImage,
                                                                                 size: .large),
                                                                     isScrollingEnabled: shouldScroll),
                                                items: items)
        
        let pullUpVC = presentPullUpView(in: viewController, pullUp: .messagingChannelInfo, contentView: selectionView, isDismissAble: true, height: selectionViewHeight)
        
        selectionView.itemSelectedCallback = { [weak pullUpVC] item in
            guard let domainName = item.userInfo.domainName else { return }
            
            pullUpVC?.openLink(.domainProfilePage(domainName: domainName))
        }
    }
    
}
