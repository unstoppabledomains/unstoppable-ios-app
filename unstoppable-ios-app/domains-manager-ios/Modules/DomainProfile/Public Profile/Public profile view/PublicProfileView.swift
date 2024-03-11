//
//  PublicProfileView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 21.08.2023.
//

import SwiftUI

struct PublicProfileView: View, ViewAnalyticsLogger {
    
    @MainActor
    static func instantiate(configuration: PublicProfileViewConfiguration) -> UIViewController {
        let view = PublicProfileView(configuration: configuration)
        let vc = UIHostingController(rootView: view)
        return vc
    }
    
    @StateObject private var viewModel: PublicProfileViewModel
    @Environment(\.presentationMode) private var presentationMode

    private weak var delegate: PublicProfileViewDelegate?
    private let avatarSize: CGFloat = 80
    private let sidePadding: CGFloat = 16
    private var avatarStyle: DomainAvatarImageView.AvatarStyle {
        switch viewModel.profile?.imageType {
        case .onChain:
            return .hexagon
        default:
            return .circle
        }
    }
    @State private var isCryptoListPresented = false
    @State private var isFollowersListPresented = false
    @State private var isSocialsListPresented = false
    @State private var offset: CGPoint = .zero
    @State private var didCoverActionsWithNav = false
    @State private var navigationState: NavigationStateManager?
    var analyticsName: Analytics.ViewName { .publicDomainProfile }
    var additionalAppearAnalyticParameters: Analytics.EventParameters { [.domainName : viewModel.domain.name]}
    
    
    var body: some View {
        NavigationViewWithCustomTitle(content: {
            ZStack {
                backgroundView()
                ZStack(alignment: .bottom) {
                    OffsetObservingScrollView(offset: $offset) {
                        contentView()
                    }
                    if isBottomViewVisible {
                        bottomActionView()
                    }
                }
                if viewModel.isLoading {
                    ProgressView()
                }
            }
            .ignoresSafeArea()
            .environmentObject(viewModel)
            .passViewAnalyticsDetails(logger: self)
            .animation(.easeInOut(duration: 0.3), value: UUID())
            .displayError($viewModel.error)
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: offset, perform: { _ in
                didScroll()
            })
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButtonView {
                        logButtonPressedAnalyticEvents(button: .close)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if didCoverActionsWithNav {
                        navShareProfileButtonView()
                    }
                }
            }
            .modifier(ShowingCryptoList(isCryptoListPresented: $isCryptoListPresented,
                                        domainName: viewModel.domain.name,
                                        records: viewModel.records))
            .modifier(ShowingFollowersList(isFollowersListPresented: $isFollowersListPresented,
                                           socialInfo: viewModel.socialInfo,
                                           domainName: viewModel.domain.name,
                                           followerSelectionCallback: followerSelected))
            .modifier(ShowingSocialsList(isSocialsListPresented: $isSocialsListPresented,
                                         socialAccounts: viewModel.socialAccounts,
                                         domainName: viewModel.domain.name))
            .onAppear(perform: onAppear)
            .trackAppearanceAnalytics(analyticsLogger: self)
        }, navigationStateProvider: { state in
            self.navigationState = state
        }, path: .constant(EmptyNavigationPath()))
    }
    
    init(configuration: PublicProfileViewConfiguration) {
        _viewModel = StateObject(wrappedValue: PublicProfileViewModel(configuration: configuration))
        self.delegate = configuration.delegate
    }
}

// MARK: - Private methods
private extension PublicProfileView {
    func onAppear() {
        setupTitle()
    }
    
    func setupTitle() {
        navigationState?.setCustomTitle(customTitle: { PublicProfileTitleView()
            .environmentObject(viewModel)},
                                        id: UUID().uuidString)
        setTitleVisibility()
    }
    
    func setTitleVisibility() {
        withAnimation {
            navigationState?.isTitleVisible = offset.y > 130
        }
    }
    
    func followerSelected(_ follower: DomainProfileFollowerDisplayInfo) {
        viewModel.didSelectFollower(follower)
    }
    
    func didScroll() {
        didCoverActionsWithNav = offset.y > 90
        setTitleVisibility()
    }
    
    var isBottomViewVisible: Bool { !viewModel.isUserDomainSelected && didCoverActionsWithNav }

    
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
        
        setModal(modal, presented: true)
    }
    
    func showFollowersList() {
        present(modal: .followers)
    }
    
    func showCryptoList() {
        present(modal: .crypto)
    }
    
    func showSocialAccountsList() {
        present(modal: .socials)
    }
}

// MARK: - Views
private extension PublicProfileView {
    @ViewBuilder
    func backgroundView() -> some View {
        ZStack {
            Color.brandUnstoppableBlue 
            if let coverImage = viewModel.coverImage {
                UIImageBridgeView(image: coverImage)
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
            
            avatarWithActionsView()
            
            VStack(spacing: 16) {
                profileInfoView()
                if let profile = viewModel.profile {
                    infoCarouselView(for: profile)
                }
                followersView()
                PublicProfileTokensSectionView()
                if let badges = viewModel.badgesDisplayInfo {
                    PublicProfileSeparatorView()
                    PublicProfileBadgesSectionView(sidePadding: sidePadding,
                                                   badges: badges)
                }
            }
            .offset(y: -26)
            Spacer()
        }
        .sideInsets(sidePadding)
        .frame(width: UIScreen.main.bounds.width)
    }
        
    @ViewBuilder
    func avatarWithActionsView() -> some View {
        HStack {
            avatarView()
                .offset(y: -32)
            Spacer()
            HStack(spacing: 8) {
                shareProfileButtonView()
                if !viewModel.isUserDomainSelected {
                    startMessagingButtonView(title: "",
                                             style: .medium(.raisedTertiaryWhite))
                    followButtonIfAvailable(isLarge: false)
                }
            }
            .offset(y: -18)
        }
    }
    
    @ViewBuilder
    func followButtonIfAvailable(isLarge: Bool) -> some View {
        if isCanFollowThisProfile,
           let isFollowing = viewModel.isFollowing {
            followButton(isFollowing: isFollowing,
                         isLarge: isLarge)
        }
    }
    
    var isCanFollowThisProfile: Bool {
        if let viewingDomain = viewModel.viewingDomain {
          return viewModel.domain.name != viewingDomain.name // Can't follow myself
        }
        return false
    }
    
    @ViewBuilder
    func shareProfileButtonView() -> some View {
        UDButtonView(text: "",
                     icon: .shareIcon,
                     style: .medium(.raisedTertiaryWhite),
                     callback: didTapShareProfileButton)
    }
    
    @ViewBuilder
    func navShareProfileButtonView() -> some View {
        Button(action: didTapShareProfileButton, 
               label: {
            Image.shareIcon
                .resizable()
                .squareFrame(24)
                .foregroundStyle(.white)
        })
        .buttonStyle(.plain)
    }
    
    func didTapShareProfileButton() {
        logButtonPressedAnalyticEvents(button: .share)
        delegate?.publicProfileDidSelectShareProfile(viewModel.domain.name)
    }
    
    @ViewBuilder
    func startMessagingButtonView(title: String,
                                  style: UDButtonStyle) -> some View {
        if let viewingDomain = viewModel.viewingDomain,
           let wallet = appContext.walletsDataService.wallets.first(where: { $0.isOwningDomain(viewingDomain.name) }) {
            UDButtonView(text: title,
                         icon: .messageCircleIcon24,
                         style: style) {
                logButtonPressedAnalyticEvents(button: .messaging)
                presentationMode.wrappedValue.dismiss()
                delegate?.publicProfileDidSelectMessagingWithProfile(viewModel.domain,
                                                                     by: wallet)
            }
        }
    }
    
    @ViewBuilder
    func bannerView() -> some View {
        if let coverImage = viewModel.coverImage {
            UIImageBridgeView(image: coverImage)
        } else {
            Color.black.opacity(0.32)
        }
    }
    
    @ViewBuilder
    func avatarView() -> some View {
        ZStack(alignment: .bottomTrailing) {
            UIImageBridgeView(image: viewModel.avatarImage ?? .domainSharePlaceholder)
                .squareFrame(avatarSize)
                .clipForAvatarStyle(avatarStyle)
        }
    }
    
    func followButtonStyle(isLarge: Bool) -> UDButtonStyle {
        isLarge ? .large(.raisedPrimaryWhite) : .medium(.raisedPrimaryWhite)
    }
    
    func followingButtonStyle(isLarge: Bool) -> UDButtonStyle {
        isLarge ? .large(.raisedTertiaryWhite) : .medium(.raisedTertiaryWhite)
    }
    
    @ViewBuilder
    func followButton(isFollowing: Bool,
                      isLarge: Bool) -> some View {
        if isFollowing {
            followButtonWith(title: String.Constants.following.localized(),
                             icon: nil,
                             style: followingButtonStyle(isLarge: isLarge),
                             analytic: .unfollow)
        } else {
            followButtonWith(title: String.Constants.follow.localized(),
                             icon: .plusIconNav,
                             style: followButtonStyle(isLarge: isLarge),
                             analytic: .follow)
        }
    }
    
    @ViewBuilder
    func followButtonWith(title: String,
                          icon: Image?,
                          style: UDButtonStyle,
                          analytic: Analytics.Button) -> some View {
        UDButtonView(text: title,
                     icon: icon,
                     style: style) {
            viewModel.followButtonPressed()
            logButtonPressedAnalyticEvents(button: analytic)
        }
    }
    
    // Profile info
    @ViewBuilder
    func profileInfoView() -> some View {
        HStack {
            VStack(alignment: .leading,
                   spacing: 16) {
                VStack(alignment: .leading,
                       spacing: 0) {
                    if let displayName = viewModel.profile?.profileName,
                       !displayName.trimmedSpaces.isEmpty {
                        PublicProfilePrimaryLargeTextView(text: displayName)
                        profileNameButton(isPrimary: false)
                    } else {
                        profileNameButton(isPrimary: true)
                    }
                }
                if isBioTextAvailable() {
                    bioText()
                }
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    func profileNameButton(isPrimary: Bool) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            delegate?.publicProfileDidSelectViewInBrowser(domainName: viewModel.domain.name)
        } label: {
            HStack(alignment: .center) {
                if isPrimary {
                    PublicProfilePrimaryLargeTextView(text: viewModel.domain.name)
                } else {
                    PublicProfileSecondaryLargeTextView(text: viewModel.domain.name)
                }
                Image.systemGlobe
                    .renderingMode(.template)
                    .resizable()
                    .squareFrame(20)
                    .foregroundColor(.white)
                    .opacity(isPrimary ? 1 : 0.56)
            }
        }
    }
    
    func isBioTextAvailable() -> Bool {
        isStringValueSet(viewModel.profile?.description) ||
        isStringValueSet(viewModel.profile?.web2Url) ||
        isStringValueSet(viewModel.profile?.location)
    }
    
    func isStringValueSet(_ string: String?) -> Bool {
        guard let string else { return false }
        
        return !string.trimmedSpaces.isEmpty
    }
    
    @ViewBuilder
    func bioText() -> some View {
        Text(
            attributedStringIfNotNil(viewModel.profile?.description, isPrimary: true) +
            attributedStringIfNotNil(viewModel.profile?.web2Url, isPrimary: false) +
            attributedStringIfNotNil(viewModel.profile?.location, isPrimary: false)
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
    func infoCarouselView(for profile: DomainProfileDisplayInfo) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                carouselSocialItemIfAvailable(in: profile)
                carouselSocialAccountsItemIfAvailable(in: profile)
                carouselCryptoRecordsItemIfAvailable(in: profile)
            }
            .sideInsets(sidePadding)
        }
        .sideInsets(-sidePadding)
    }
    
    @ViewBuilder
    func carouselSocialItemIfAvailable(in profile: DomainProfileDisplayInfo) -> some View {
        carouselFollowersItem(for: profile, callback: { showFollowersList() })
    }
    
    @ViewBuilder
    func carouselSocialAccountsItemIfAvailable(in profile: DomainProfileDisplayInfo) -> some View {
        if !profile.socialAccounts.isEmpty {
            carouselItem(text: String.Constants.pluralNSocials.localized(profile.socialAccounts.count, profile.socialAccounts.count),
                         icon: .twitterIcon24,
                         button: .socialsList,
                         callback: { showSocialAccountsList() })
        }
    }
    
    @ViewBuilder
    func carouselCryptoRecordsItemIfAvailable(in profile: DomainProfileDisplayInfo) -> some View {
        if let records = viewModel.records,
           !records.isEmpty {
            carouselItem(text: String.Constants.pluralNAddresses.localized(records.count, records.count),
                         icon: .walletAddressesIcon,
                         button: .cryptoList,
                         callback: { showCryptoList() })
        }
    }
    
    @ViewBuilder
    func carouselItemWithContent(callback: @escaping MainActorAsyncCallback,
                                 button: Analytics.Button,
                                 @ViewBuilder content: ()->(some View)) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            logButtonPressedAnalyticEvents(button: button)
            callback()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .opacity(0.16)
                content()
                    .sideInsets(12)
            }
            .frame(height: 32)
            
        }
    }
    
    @ViewBuilder
    func carouselFollowersItem(for profile: DomainProfileDisplayInfo,
                               callback: @escaping MainActorAsyncCallback) -> some View {
        let followerCount = profile.followerCount
        let followingCount = profile.followingCount
        let havingFollowers = followerCount > 0
        let havingFollowings = followingCount > 0
        let havingFollowersOrFollowings = havingFollowers || havingFollowings
        let dimOpacity: CGFloat = 0.32
        carouselItemWithContent(callback: callback,
                                button: .followersList) {
            HStack(spacing: 8) {
                Text(String.Constants.pluralNFollowers.localized(followerCount, followerCount))
                    .foregroundColor(.white)
                    .opacity(havingFollowers ? 1 : dimOpacity)
                Text("·")
                    .foregroundColor(.white)
                    .opacity(havingFollowersOrFollowings ? 1 : dimOpacity)
                Text(String.Constants.pluralNFollowing.localized(followingCount, followingCount))
                    .foregroundColor(.white)
                    .opacity(havingFollowings ? 1 : dimOpacity)
            }
            .font(.currentFont(size: 14, weight: .medium))
        }
    }
    
    @ViewBuilder
    func carouselItem(text: String,
                      icon: UIImage,
                      button: Analytics.Button,
                      callback: @escaping MainActorAsyncCallback) -> some View {
        carouselItemWithContent(callback: callback,
                                button: button) {
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
    
    var bottomActionGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .black, location: 0),
                .init(color: .black, location: 0.8),
                .init(color: .black.opacity(0.12), location: 1)
            ]),
            startPoint: .bottom,
            endPoint: .top
        )
    }
    
    @ViewBuilder
    func bottomActionView() -> some View {
        ZStack(alignment: .top) {
            Rectangle()
                .foregroundStyle(.ultraThinMaterial)
            
                .mask(bottomActionGradient)
            
            HStack(spacing: 16) {
                startMessagingButtonView(title: String.Constants.chat.localized(),
                                         style: .large(.raisedTertiaryWhite))
                followButtonIfAvailable(isLarge: true)
            }
            .padding()
            
        }
        .frame(height: 116)
        .frame(maxWidth: .infinity)
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
        var records: [CryptoRecord]?
        
        func body(content: Content) -> some View {
            if let records {
                content
                    .sheet(isPresented: $isCryptoListPresented, content: {
                        PublicProfileCryptoListView(domainName: domainName,
                                                    records: records)
                        .adaptiveSheet()
                    })
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
                    .sheet(isPresented: $isFollowersListPresented, content: {
                        PublicProfileFollowersView(domainName: domainName,
                                                   socialInfo: socialInfo,
                                                   followerSelectionCallback: followerSelectionCallback)
                        .adaptiveSheet()
                    })
            } else {
                content
            }
        }
    }
    
    struct ShowingSocialsList: ViewModifier {
        @Binding var isSocialsListPresented: Bool
        var socialAccounts: [DomainProfileSocialAccount]?
        let domainName: DomainName
        
        func body(content: Content) -> some View {
            if let socialAccounts {
                content
                    .sheet(isPresented: $isSocialsListPresented, content: {
                        PublicProfileSocialsListView(domainName: domainName,
                                                     socialAccounts: socialAccounts)
                        .adaptiveSheet()
                    })
            } else {
                content
            }
        }
    }
}

@available(iOS 17, *)
#Preview {
    PreviewContainerView()
}

private struct PreviewContainerView: View  {
    
    @State var isPresentingProfile = false
    var body: some View {
        Text("Container")
            .sheet(isPresented: $isPresentingProfile, content: {
                targetView()
            })
            .onAppear {
                isPresentingProfile = true
            }
    }
    
    @ViewBuilder
    func targetView() -> some View {
        PublicProfileView(configuration: PublicProfileViewConfiguration(domain: .init(walletAddress: "0x123", name: "gounstoppable.polygon"),
                                                                        viewingWallet: MockEntitiesFabric.Wallet.mockEntities()[0]))
    }
    
}
