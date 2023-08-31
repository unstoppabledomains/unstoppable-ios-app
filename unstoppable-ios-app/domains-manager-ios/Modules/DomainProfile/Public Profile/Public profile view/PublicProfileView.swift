//
//  PublicProfileView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 21.08.2023.
//

import SwiftUI

struct PublicProfileView: View {
    
    @MainActor
    static func instantiate(domainName: String,
                            viewingDomain: DomainItem,
                            delegate: PublicProfileViewDelegate? = nil) -> UIViewController {
        let view = PublicProfileView(domainName: domainName,
                                           viewingDomain: viewingDomain,
                                           delegate: delegate)
        let vc = UIHostingController(rootView: view)
        return vc
    }
    
    @StateObject private var viewModel: PublicProfileViewModel
 
    private weak var delegate: PublicProfileViewDelegate?
    private let avatarSize: CGFloat = 80
    private let sidePadding: CGFloat = 16
    private var avatarStyle: DomainAvatarImageView.AvatarStyle {
        switch viewModel.profile?.profile.imageType {
        case .onChain:
            return .hexagon
        default:
            return .circle
        }
    }
    @State private var isCryptoListPresented = false
    @State private var isFollowersListPresented = false
    @State private var isSocialsListPresented = false

    var body: some View {
        ZStack {
            backgroundView()
            ScrollView {
                contentView()
            }
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: UUID())
        .modifier(ShowingCryptoList(isCryptoListPresented: $isCryptoListPresented,
                                    domainName: viewModel.domainName,
                                    records: viewModel.records))
        .modifier(ShowingFollowersList(isFollowersListPresented: $isFollowersListPresented,
                                      socialInfo: viewModel.socialInfo,
                                      domainName: viewModel.domainName,
                                      followerSelectionCallback: followerSelected))
        .modifier(ShowingSocialsList(isSocialsListPresented: $isSocialsListPresented,
                                     socialAccounts: viewModel.socialAccounts,
                                     domainName: viewModel.domainName))
    }
    
    init(domainName: String,
         viewingDomain: DomainItem,
         delegate: PublicProfileViewDelegate? = nil) {
        _viewModel = StateObject(wrappedValue: PublicProfileViewModel(domain: domainName, viewingDomain: viewingDomain))
        self.delegate = delegate
    }
}

// MARK: - Private methods
private extension PublicProfileView {
    func followerSelected(_ follower: DomainProfileFollowerDisplayInfo) {
        viewModel.didSelectFollower(follower)
    }
    
    @ViewBuilder
    func backgroundView() -> some View {
        ZStack {
            Color.brandUnstoppableBlue 
            if let coverImage = viewModel.coverImage {
                Image(uiImage: coverImage)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 80)
            }
            Color.black.opacity(0.56)
        }
        .ignoresSafeArea()
    }
    
    @ViewBuilder
    func contentView() -> some View {
        VStack {
            bannerView()
                .frame(height: 90)
                .clipped()
                .reverseMask({
                    AvatarShapeClipper(style: avatarStyle,
                                       avatarSize: avatarSize)
                })
                .sideInsets(-sidePadding)
            
            HStack {
                avatarView()
                    .offset(y: -32)
                Spacer()
                HStack(spacing: 8) {
                    CircleIconButton(icon: .uiImage(.shareIcon),
                                     size: .medium,
                                     callback: {
                        delegate?.publicProfileDidSelectShareProfile(viewModel.domainName)
                    })
                    CircleIconButton(icon: .uiImage(.messageCircleIcon24),
                                     size: .medium,
                                     callback: {
                        delegate?.publicProfileDidSelectMessagingProfile(viewModel.domainName)
                    })
                    if let isFollowing = viewModel.isFollowing {
                        followButton(isFollowing: isFollowing)
                    }
                }
                .offset(y: -18)
            }
            
            VStack(spacing: 16) {
                profileInfoView()
                if let profile = viewModel.profile {
                    infoCarouselView(for: profile)
                }
                followersView()
                if let badges = viewModel.badgesDisplayInfo {
                    profileDashSeparator()
                    badgesView(badges: badges)
                }
            }
            .offset(y: -26)
            Spacer()
        }
        .sideInsets(sidePadding)
        .frame(width: UIScreen.main.bounds.width)
    }
    
    @ViewBuilder
    func bannerView() -> some View {
        if let coverImage = viewModel.coverImage {
            Image(uiImage: coverImage)
                .resizable()
                .scaledToFill()
        } else {
            Color.black.opacity(0.32)
        }
    }
    
    @ViewBuilder
    func avatarView() -> some View {
        Image(uiImage: viewModel.avatarImage ?? .domainSharePlaceholder)
            .resizable()
            .scaledToFill()
            .frame(width: avatarSize,
                   height: avatarSize)
            .clipForAvatarStyle(avatarStyle)
    }
    
    @ViewBuilder
    func followButton(isFollowing: Bool) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            viewModel.followButtonPressed()
        } label: {
            HStack(spacing: 8) {
                if !isFollowing {
                    Image.plusIconNav
                }
                
                Text(isFollowing ? String.Constants.following.localized() : String.Constants.follow.localized())
            }
            .foregroundColor(isFollowing ? .white : .black)
            .font(.currentFont(size: 16, weight: .medium))
            .frame(height: 24)
        }
        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
        .background(.white.opacity(isFollowing ? 0.16 : 1.0))
        .clipShape(Capsule())
    }
    
    // Profile info
    @ViewBuilder
    func profileInfoView() -> some View {
        HStack {
            VStack(alignment: .leading,
                   spacing: 16) {
                VStack(alignment: .leading,
                       spacing: 0) {
                    if let displayName = viewModel.profile?.profile.displayName {
                        primaryLargeText(displayName)
                        secondaryLargeText(viewModel.domainName)
                    } else {
                        primaryLargeText(viewModel.domainName)
                    }
                }
                if isBioTextAvailable() {
                    bioText()
                }
            }
            Spacer()
        }
    }
    
    func isBioTextAvailable() -> Bool {
        isStringValueSet(viewModel.profile?.profile.description) ||
        isStringValueSet(viewModel.profile?.profile.web2Url) ||
        isStringValueSet(viewModel.profile?.profile.location)
    }
    
    func isStringValueSet(_ string: String?) -> Bool {
        guard let string else { return false }
        
        return !string.trimmedSpaces.isEmpty
    }
    
    @ViewBuilder
    func bioText() -> some View {
        Text(
            attributedStringIfNotNil(viewModel.profile?.profile.description, isPrimary: true) +
            attributedStringIfNotNil(viewModel.profile?.profile.web2Url, isPrimary: false) +
            attributedStringIfNotNil(viewModel.profile?.profile.location, isPrimary: false)
        )
        .lineLimit(3)
    }
    
    func attributedStringIfNotNil(_ string: String?,
                                  isPrimary: Bool) -> AttributedString {
        if let string {
            if isPrimary {
                return bioPrimaryAttributedString(text: string)
            }
            return bioPrimarySeparator() + bioSecondaryAttributedString(text: string)
        }
        return ""
    }
    
    func bioPrimaryAttributedString(text: String) -> AttributedString {
        var result = AttributedString(text)
        result.font = .currentFont(size: 14)
        result.foregroundColor = .white
        return result
    }
    
    func bioPrimarySeparator() -> AttributedString {
        bioPrimaryAttributedString(text: " · ")
    }
    
    func bioSecondaryAttributedString(text: String) -> AttributedString {
        var result = AttributedString(text)
        result.font = .currentFont(size: 14, weight: .medium)
        result.foregroundColor = .white.opacity(0.56)
        return result
    }
    
    // Carousel
    @ViewBuilder
    func infoCarouselView(for profile: SerializedPublicDomainProfile) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let social = profile.social {
                    carouselFollowersItem(for: social, callback: showFollowersList)
                }
                if let social = profile.socialAccounts {
                    let accounts = SocialDescription.typesFrom(accounts: social)
                    if !accounts.isEmpty {
                        carouselItem(text: String.Constants.pluralNSocials.localized(accounts.count, accounts.count),
                                     icon: .twitterIcon24,
                                     callback: showSocialsList)
                    }
                }
                if let records = profile.records,
                   !records.isEmpty {
                    carouselItem(text: String.Constants.pluralNCrypto.localized(records.count, records.count),
                                 icon: .walletBTCIcon20,
                                 callback: showCryptoList)
                }
            }
            .sideInsets(sidePadding)
        }
        .sideInsets(-sidePadding)
    }
    
    enum PresentingModalsOption: CaseIterable, Hashable {
        case followers, crypto, socials
    }
    
    func isPresenting(modal: PresentingModalsOption) -> Bool {
        switch modal {
        case .followers:
            return isFollowersListPresented
        case .crypto:
            return isCryptoListPresented
        case .socials:
            return isSocialsListPresented
        }
    }
    
    func present(modal: PresentingModalsOption) {
        let otherViews = PresentingModalsOption.allCases.filter({ $0 != modal })
        if let presentedView = otherViews.first(where: { isPresenting(modal: $0) }) {
            // Showing some other view
            setModal(presentedView, presented: false)
            afterAdaptiveSheetDismiss {
                present(modal: modal)
            }
        } else {
            setModal(modal, presented: true)
        }
    }
    
    func setModal(_ modal: PresentingModalsOption, presented: Bool) {
        switch modal {
        case .followers:
            isFollowersListPresented = presented
        case .crypto:
            isCryptoListPresented = presented
        case .socials:
            isSocialsListPresented = presented
        }
    }
    
    func showFollowersList() {
        present(modal: .followers)
    }
    
    func showCryptoList() {
        present(modal: .crypto)
    }
    
    func showSocialsList() {
        present(modal: .socials)
    }
    
    @ViewBuilder
    func carouselItemWithContent(callback: @escaping EmptyCallback,
                                 @ViewBuilder content: ()->(any View)) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            callback()
        } label: {
            ZStack {
                Capsule()
                    .fill(Color.white)
                    .opacity(0.16)
                AnyView(content())
                    .sideInsets(12)
            }
            .frame(height: 32)
            .clipShape(Capsule())
        }
    }
    
    @ViewBuilder
    func carouselFollowersItem(for social: DomainProfileSocialInfo,
                               callback: @escaping EmptyCallback) -> some View {
        let havingFollowers = social.followerCount > 0
        let havingFollowings = social.followingCount > 0
        let havingFollowersOrFollowings = havingFollowers || havingFollowings
        let dimOpacity: CGFloat = 0.32
        carouselItemWithContent(callback: callback) {
            HStack(spacing: 8) {
                Text(String.Constants.pluralNFollowers.localized(social.followerCount, social.followerCount))
                    .foregroundColor(.white)
                    .opacity(havingFollowers ? 1 : dimOpacity)
                Text("·")
                    .foregroundColor(.white)
                    .opacity(havingFollowersOrFollowings ? 1 : dimOpacity)
                Text(String.Constants.pluralNFollowing.localized(social.followingCount, social.followingCount))
                    .foregroundColor(.white)
                    .opacity(havingFollowings ? 1 : dimOpacity)
            }
            .font(.currentFont(size: 14, weight: .medium))
        }
    }
    
    @ViewBuilder
    func carouselItem(text: String,
                      icon: UIImage,
                      callback: @escaping EmptyCallback) -> some View {
        carouselItemWithContent(callback: callback) {
            HStack(spacing: 8) {
                Image(uiImage: icon)
                    .resizable()
                    .frame(width: 16, height: 16)
                Text(text)
                    .font(.currentFont(size: 14, weight: .medium))
            }
            .foregroundColor(.white)
        }
    }
    
    // Followers
    @ViewBuilder
    func followersView() -> some View {
        HStack {
            if let followersDisplayInfo = viewModel.followersDisplayInfo,
               !followersDisplayInfo.topFollowersList.isEmpty {
                followersIcons(followersDisplayInfo.topFollowersList)
                followersTextView(followersDisplayInfo)
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    func followersIcons(_ followers: [DomainProfileFollowerDisplayInfo]) -> some View {
        let iconSize: CGFloat = 20
        HStack(spacing: -6) {
            ForEach(Array(followers.enumerated()), id: \.offset) { (index, follower) in
                ZStack {
                    Image(uiImage: follower.icon ?? .followerGrayPlaceholder)
                        .resizable()
                        .scaledToFill()
                        .frame(width: iconSize, height: iconSize)
                        .clipped()
                }
                .task {
                    viewModel.loadIconIfNeededFor(follower: follower)
                }
                .clipShape(Capsule())
                .frame(width: iconSize, height: iconSize)
                .reverseMask({
                    if index != 0 {
                        Circle()
                            .frame(width: iconSize,
                                   height: iconSize)
                            .offset(x: -(iconSize * 0.6))
                    }
                })
                .zIndex(Double(followers.count - index))
            }
        }
    }
    
    @ViewBuilder
    func followersTextView(_ displayInfo: FollowersDisplayInfo) -> some View {
        Text(followersText(displayInfo))
        .lineLimit(2)
    }
    
    func followersText(_ displayInfo: FollowersDisplayInfo) -> AttributedString {
        let followers = displayInfo.topFollowersList
        var text = bioPrimaryAttributedString(text: String.Constants.followedBy.localized() + " ")
        text += bioSecondaryAttributedString(text: followers[0].domain)
        let andString = " \(String.Constants.and.localized().lowercased()) "
        let comaString = ", "
        
        switch displayInfo.totalNumberOfFollowers {
        case 1:
            return text
        case 2:
            guard followers.count >= 2 else { return text }
            
            text += bioPrimaryAttributedString(text: andString)
            text += bioSecondaryAttributedString(text: followers[1].domain)
        case 3:
            guard followers.count >= 3 else { return text }
            
            text += bioPrimaryAttributedString(text: comaString)
            text += bioSecondaryAttributedString(text: followers[1].domain)
            
            text += bioPrimaryAttributedString(text: andString)
            text += bioSecondaryAttributedString(text: followers[2].domain)
        default:
            guard followers.count >= 2 else { return text }

            text += bioPrimaryAttributedString(text: comaString)
            text += bioSecondaryAttributedString(text: followers[1].domain)
            
            text += bioPrimaryAttributedString(text: andString)
            text += bioSecondaryAttributedString(text: String.Constants.followedByNOthersSuffix.localized(displayInfo.totalNumberOfFollowers - 2))
        }
        return text
    }
    
    @ViewBuilder
    func profileDashSeparator() -> some View {
        Line()
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [3]))
            .foregroundColor(.white)
            .opacity(0.08)
            .frame(height: 1)
            .padding(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
    }
    
    @ViewBuilder
    func badgesView(badges: [DomainProfileBadgeDisplayInfo]) -> some View {
        VStack(spacing: sidePadding) {
            badgesTitle(badges: badges)
            badgesGrid(badges: badges)
        }
    }
        
    @ViewBuilder
    func badgesTitle(badges: [DomainProfileBadgeDisplayInfo]) -> some View {
        HStack {
            primaryLargeText(String.Constants.domainProfileSectionBadgesName.localized())
            secondaryLargeText("\(badges.count)")
            Spacer()
            Button {
                UDVibration.buttonTap.vibrate()
                delegate?.publicProfileDidSelectOpenLeaderboard()
            } label: {
                HStack(spacing: 8) {
                    Text(String.Constants.leaderboard.localized())
                        .font(.currentFont(size: 16, weight: .medium))
                        .frame(height: 24)
                    Image.arrowTopRight
                        .resizable()
                        .frame(width: 20,
                               height: 20)
                }
                .foregroundColor(.white).opacity(0.56)
            }
        }
    }

    @ViewBuilder
    func badgesGrid(badges: [DomainProfileBadgeDisplayInfo]) -> some View {
        LazyVGrid(columns: Array(repeating: .init(), count: 5)) {
            ForEach(badges, id: \.self) { badge in
                badgeView(badge: badge)
            }
        }
    }
    
    @ViewBuilder
    func badgeView(badge: DomainProfileBadgeDisplayInfo) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            delegate?.publicProfileDidSelectBadge(badge, in: viewModel.domainName)
        } label: {
            ZStack {
                Color.white
                    .opacity(0.16)
                let imagePadding: CGFloat = badge.badge.isUDBadge ? 8 : 4
                Image(uiImage: badge.icon ?? badge.defaultIcon)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .scaledToFill()
                    .clipped()
                    .clipShape(Circle())
                    .foregroundColor(.white)
                    .padding(EdgeInsets(top: imagePadding, leading: imagePadding,
                                        bottom: imagePadding, trailing: imagePadding))
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(Circle())
        }
        .task {
            viewModel.loadIconIfNeededFor(badge: badge)
        }
    }
    
    @ViewBuilder
    func largeText(_ text: String) -> some View {
        Text(text)
            .font(.currentFont(size: 22, weight: .bold))
            .frame(height: 28)
    }
    
    @ViewBuilder
    func primaryLargeText(_ text: String) -> some View {
        largeText(text)
            .foregroundColor(.white)
    }
    
    @ViewBuilder
    func secondaryLargeText(_ text: String) -> some View {
        primaryLargeText(text)
            .opacity(0.56)
    }
}

// MARK: - Private methods
private extension PublicProfileView {
    struct AvatarShapeClipper: Shape {
        let style: DomainAvatarImageView.AvatarStyle
        let avatarSize: CGFloat
        
        func path(in rect: CGRect) -> Path {
            switch style {
            case .circle:
                return circlePath(in: rect)
            case .hexagon:
                return hexagonPath(in: rect)
            }
        }
        
        private func circlePath(in rect: CGRect) -> Path {
            let sideOffset: CGFloat = 16
            let maskShapeSizeDiff: CGFloat = 4
            let maskSize = avatarSize + maskShapeSizeDiff
            let currentX = sideOffset - (maskShapeSizeDiff / 2)
            
            return Circle().path(in: CGRect(x: currentX, y: 62, width: maskSize, height: maskSize))
        }
        
        private func hexagonPath(in rect: CGRect) -> Path {
            HexagonShape(rotation: .horizontal, offset: CGPoint(x: 11, y: 62)).path(in: rect)
        }
    }
    
    struct ShowingCryptoList: ViewModifier {
        @Binding var isCryptoListPresented: Bool
        let domainName: DomainName
        var records: [String : String]?
        
        func body(content: Content) -> some View {
            if let records {
                content
                    .adaptiveSheet(isPresented: $isCryptoListPresented,
                                   detents: [.medium(), .large()],
                                   smallestUndimmedDetentIdentifier: .large) {
                        PublicProfileCryptoListView(domainName: domainName,
                                                    recordsDict: records,
                                                    isPresenting: $isCryptoListPresented)
                    }
            } else {
                content
            }
        }
    }
    
    struct ShowingFollowersList: ViewModifier {
        @Binding var isFollowersListPresented: Bool
        var socialInfo: DomainProfileSocialInfo?
        let domainName: DomainName
        let followerSelectionCallback: FollowerSelectionCallback
        
        func body(content: Content) -> some View {
            if let socialInfo {
                content
                    .adaptiveSheet(isPresented: $isFollowersListPresented,
                                   detents: [.medium(), .large()],
                                   smallestUndimmedDetentIdentifier: .large) {
                        PublicProfileFollowersView(domainName: domainName,
                                                   socialInfo: socialInfo,
                                                   followerSelectionCallback: followerSelectionCallback,
                                                   isPresenting: $isFollowersListPresented)
                    }
            } else {
                content
            }
        }
    }
    
    struct ShowingSocialsList: ViewModifier {
        @Binding var isSocialsListPresented: Bool
        var socialAccounts: SocialAccounts?
        let domainName: DomainName
        
        func body(content: Content) -> some View {
            if let socialAccounts {
                content
                    .adaptiveSheet(isPresented: $isSocialsListPresented,
                                   detents: [.medium(), .large()],
                                   smallestUndimmedDetentIdentifier: .large) {
                        PublicProfileSocialsListView(domainName: domainName,
                                                     socialAccounts: socialAccounts,
                                                     isPresenting: $isSocialsListPresented)
                    }
            } else {
                content
            }
        }
    }
    
}

struct PublicProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(Constants.swiftUIPreviewDevices, id: \.self) { device in
            PublicProfileView(domainName: "dans.crypto",
                              viewingDomain: .init(name: "oleg.x"))
                .previewDevice(PreviewDevice(rawValue: device))
                .previewDisplayName(device)
        }
    }
}
