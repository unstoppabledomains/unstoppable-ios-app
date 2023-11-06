//
//  PullUpViewService+Badges.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.10.2023.
//

import UIKit

extension PullUpViewService {
    
    func showBadgeInfoPullUp(in viewController: UIViewController,
                             badgeDisplayInfo: DomainProfileBadgeDisplayInfo,
                             domainName: String) {
        Task {
            var selectionViewHeight: CGFloat = 0
            let selectionView = await buildBadgesInfoPullUp(in: viewController,
                                                            badgeDisplayInfo: badgeDisplayInfo,
                                                            domainName: domainName,
                                                            selectionViewHeight: &selectionViewHeight)
            
            showOrUpdate(in: viewController, pullUp: .badgeInfo, contentView: selectionView, height: selectionViewHeight)
        }
    }
    
}

// MARK: - Private methods
private extension PullUpViewService {
    func buildBadgesInfoPullUp(in viewController: UIViewController,
                               badgeDisplayInfo: DomainProfileBadgeDisplayInfo,
                               domainName: String,
                               selectionViewHeight: inout CGFloat) async -> PullUpSelectionView<BadgeLeaderboardSelectionItem> {
        
        let badge = badgeDisplayInfo.badge
        selectionViewHeight = 256
        let labelWidth = UIScreen.main.bounds.width - 32 // 16 * 2 side offsets
        
        // Load badge icon
        var badgeIcon = badgeDisplayInfo.defaultIcon
        if let url = URL(string: badgeDisplayInfo.badge.logo),
           let image = await appContext.imageLoadingService.loadImage(from: .url(url, maxSize: Constants.downloadedIconMaxSize),
                                                                      downsampleDescription: .mid) {
            badgeIcon = image
        }
        
        var leaderboardItems = [BadgeLeaderboardSelectionItem]()
        var subtitleText = badge.description
        var subtitle: PullUpSelectionViewConfiguration.Subtitle = .label(.text(subtitleText))
        var extraTitle: PullUpSelectionViewConfiguration.LabelType?
        var actionButton: PullUpSelectionViewConfiguration.ButtonType?
        
        // Load badge detailed info
        if !badgeDisplayInfo.isExploreWeb3Badge,
           let badgeDetailedInfo = try? await NetworkService().fetchBadgeDetailedInfo(for: badge) {
            let leaderboardItem = BadgeLeaderboardSelectionItem(badgeDetailedInfo: badgeDetailedInfo)
            leaderboardItems.append(leaderboardItem)
            selectionViewHeight += 72 + 48 // Leaderboard cell height + vertical margins
            
            // Add extra title for sponsor
            extraTitle = buildBadgeInfoExtraTitle(badgeDetailedInfo: badgeDetailedInfo,
                                                  selectionViewHeight: &selectionViewHeight,
                                                  in: viewController)
        }
        
        if !badge.isUDBadge {
            // Add action button to share badge ownership
            actionButton = buildBadgeInfoActionButton(domainName: domainName,
                                                      badge: badge,
                                                      selectionViewHeight: &selectionViewHeight,
                                                      in: viewController)
            
            // Update subtitle with Learn more action
            if let linkUrl = badge.linkUrl,
               URL(string: linkUrl) != nil {
                
                let learnMoreText = String.Constants.learnMore.localized()
                let textToAdd = "... \(learnMoreText)"
                let maximumDescriptionSize = 218
                if (subtitleText.count + textToAdd.count) > maximumDescriptionSize {
                    let numberOfCharsToLeave = maximumDescriptionSize - textToAdd.count
                    subtitleText = String(subtitleText.prefix(numberOfCharsToLeave))
                    subtitleText += textToAdd
                } else {
                    subtitleText += textToAdd
                }
                
                subtitle = .label(.highlightedText(.init(text: subtitleText,
                                                         highlightedText: [.init(highlightedText: learnMoreText,
                                                                                 highlightedColor: .foregroundAccent)],
                                                         analyticsActionName: .learnMore,
                                                         action: { [weak viewController] in
                    UDVibration.buttonTap.vibrate()
                    let link = String.Links.generic(url: linkUrl)
                    viewController?.presentedViewController?.openLink(link)
                })))
            }
        }
        
        // Final subtitle height calculation
        let descriptionHeight = subtitleText.height(withConstrainedWidth: labelWidth,
                                                    font: .currentFont(withSize: 16,
                                                                       weight: .regular))
        selectionViewHeight += descriptionHeight
        
        
        let selectionView = PullUpSelectionView(configuration: .init(title: .text(badge.name),
                                                                     extraTitle: extraTitle,
                                                                     contentAlignment: .center,
                                                                     icon: .init(icon: badgeIcon,
                                                                                 size: badge.isUDBadge ? .small : .large),
                                                                     subtitle: subtitle,
                                                                     actionButton: actionButton,
                                                                     cancelButton: .gotItButton()),
                                                items: leaderboardItems,
                                                itemSelectedCallback: { [weak viewController] _ in
            // Show leaderboard
            let link = String.Links.badgesLeaderboard
            viewController?.presentedViewController?.openLink(link)
        })
        
        return selectionView
    }
    
    func buildBadgeInfoActionButton(domainName: String,
                                    badge: BadgesInfo.BadgeInfo,
                                    selectionViewHeight: inout CGFloat,
                                    in viewController: UIViewController) -> PullUpSelectionViewConfiguration.ButtonType? {
        var actionButton: PullUpSelectionViewConfiguration.ButtonType?
        if let url = String.Links.showcaseDomainBadge(domainName: domainName,
                                                      badgeCode: badge.code).url {
            actionButton = .raisedTertiary(content: .init(title: String.Constants.share.localized(),
                                                          icon: nil,
                                                          analyticsName: .share,
                                                          action: { [weak viewController] in
                let activityViewController = UIActivityViewController(activityItems: [url],
                                                                      applicationActivities: nil)
                viewController?.presentedViewController?.present(activityViewController, animated: true)
            }))
            selectionViewHeight += 48 + 40 // Button height + vertical margins
        }
        return actionButton
    }
    
    func buildBadgeInfoExtraTitle(badgeDetailedInfo: BadgeDetailedInfo,
                                  selectionViewHeight: inout CGFloat,
                                  in viewController: UIViewController) -> PullUpSelectionViewConfiguration.LabelType? {
        var extraTitle: PullUpSelectionViewConfiguration.LabelType?
        if let sponsor = badgeDetailedInfo.badge.sponsor {
            let text = String.Constants.profileBadgesSponsoredByMessage.localized(sponsor)
            extraTitle = .highlightedText(.init(text: text,
                                                highlightedText: [.init(highlightedText: text,
                                                                        highlightedColor: .foregroundAccent)],
                                                analyticsActionName: .badgeSponsor, action: { [weak viewController] in
                UDVibration.buttonTap.vibrate()
                let link = String.Links.domainProfilePage(domainName: sponsor)
                viewController?.presentedViewController?.openLink(link)
            }))
            selectionViewHeight += 24 + 8 // Label height + vertical margins
        }
        return extraTitle
    }
}
