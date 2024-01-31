//
//  NFTDetailsView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.01.2024.
//

import SwiftUI

struct NFTDetailsView: View {
    
    @Environment(\.presentationMode) private var presentationMode

    let nft: NFTDisplayInfo
    @State private var nftImage: UIImage?
    @State private var navigationState: NavigationStateManager?
    @State private var scrollOffset: CGPoint = .zero

    var body: some View {
        NavigationViewWithCustomTitle(content: {
            OffsetObservingScrollView(showsIndicators: false, offset: $scrollOffset) {
                VStack(spacing: 20) {
                    nftImageView()
                    nftCollectionInfoView()
                    separatorView()
                    nftPriceInfoView()
                    separatorView()
                    nftDescriptionInfoView()
                    nftTraitsSectionView()
                    nftOtherDetailsSectionView()
                }
                .padding()
            }
            .onChange(of: scrollOffset) { newValue in
                withAnimation {
                    navigationState?.isTitleVisible = newValue.y > UIScreen.main.bounds.width + 60
                }
            }
            .animation(.default, value: UUID())
            .onAppear(perform: onAppear)
            .toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButtonView {
                        UDVibration.buttonTap.vibrate()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    navActionsView()
                }
            })
        }, navigationStateProvider: { navigationState in
            self.navigationState = navigationState
            navigationState.customTitle = { NavigationTitleView(nft: nft) }
        }, path: .constant(.init()))
    }
}

// MARK: - Private methods
private extension NFTDetailsView {
    func onAppear() {
        Task {
            nftImage = await nft.loadIcon()
        }
    }
    
    struct NavigationTitleView: View {
        
        let nft: NFTDisplayInfo
        @State private var nftImage: UIImage?

        var body: some View {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    if let nftImage {
                        Image(uiImage: nftImage)
                            .resizable()
                            .squareFrame(20)
                            .clipShape(Circle())
                    }
                    Text(nft.displayName)
                        .font(.currentFont(size: 16, weight: .semibold))
                        .foregroundStyle(Color.foregroundDefault)
                        .frame(height: 24)
                }
                Text(nft.collection)
                    .font(.currentFont(size: 16, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.56))
                    .frame(height: 16)
            }
            .task {
                let nftImage = await nft.loadIcon()
                withAnimation {
                    self.nftImage = nftImage
                }
            }
        }
    }
    
    @ViewBuilder
    func nftImageView() -> some View {
        ZStack {
            Image(uiImage: nftImage ?? .init())
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .background(Color.backgroundSubtle)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            if nftImage == nil {
                ProgressView()
            }
        }
    }
    
    @ViewBuilder
    func separatorView(direction: Line.Direction = .horizontal,
                       dashed: Bool = false) -> some View {
        Line(direction: direction)
            .stroke(style: StrokeStyle(lineWidth: 1, 
                                       dash: dashed ? [5] : []))
            .foregroundStyle(Color.foregroundSecondary)
    }
    
    @ViewBuilder
    func nftCollectionInfoView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(nft.displayName)
                    .font(.currentFont(size: 22, weight: .bold))
                    .foregroundStyle(Color.foregroundDefault)
                Spacer()
            }
            Text(collectionName)
                .font(.currentFont(size: 16, weight: .medium))
                .foregroundStyle(Color.foregroundDefault)
        }
    }
    
    var collectionName: String { nft.collection }
    
    @ViewBuilder
    func nftDescriptionInfoView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeaderView(icon: .notesIcon,
                              title: String.Constants.nftDetailsAboutCollectionHeader.localized(collectionName))
            Text(nft.description ?? String.Constants.none.localized())
                .font(.currentFont(size: 16))
                .foregroundStyle(Color.foregroundSecondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    func sectionHeaderView(icon: Image, title: String) -> some View {
        HStack(spacing: 8) {
            icon
                .resizable()
                .renderingMode(.template)
                .squareFrame(20)
            Text(title)
                .font(.currentFont(size: 16, weight: .medium))
            Spacer()
        }
        .foregroundStyle(Color.foregroundDefault)
    }
    
    @ViewBuilder
    func nftPriceInfoView() -> some View {
        HStack(alignment: .center, spacing: 8) {
            Spacer()
            nftPriceValueView(title: String.Constants.lastSalePrice.localized(),
                              value: nft.lastSalePrice)
            separatorView(direction: .vertical)
                .frame(width: 1)
            nftPriceValueView(title: String.Constants.floorPrice.localized(),
                              value: nft.floorPrice)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    func nftPriceValueView(title: String, value: String?) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text(title)
                .frame(height: 20)
                .font(.currentFont(size: 14, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.48))
            Text(value ?? String.Constants.none.localized())
                .frame(height: 24)
                .font(.currentFont(size: 16, weight: .medium))
                .foregroundStyle(Color.white.opacity(value == nil ? 0.32 : 1))
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    func nftTraitsSectionView() -> some View {
        if !nft.traits.isEmpty {
            separatorView()
            VStack(alignment: .leading, spacing: 12) {
                sectionHeaderView(icon: .threeLayersStack,
                                  title: String.Constants.traits.localized())
                FlowLayoutView(nft.traits) { trait in
                    VStack(alignment: .leading, spacing: 0) {
                        Text(trait.name)
                            .font(.currentFont(size: 14))
                            .foregroundColor(.white.opacity(0.48))
                            .frame(height: 20)
                        Text(trait.value)
                            .font(.currentFont(size: 16, weight: .medium))
                            .foregroundColor(.foregroundDefault)
                            .frame(height: 24)
                    }
                    .padding(EdgeInsets(top: 8, leading: 12,
                                        bottom: 8, trailing: 12))
                    .background(Color.backgroundMuted)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    @ViewBuilder
    func nftOtherDetailsSectionView() -> some View {
        if isNFTHasAnyDetails {
            separatorView()
            VStack(alignment: .leading, spacing: 12) {
                sectionHeaderView(icon: .squareInfo,
                                  title: String.Constants.details.localized())
                VStack(spacing: 0) {
                    ForEach(NFTDisplayInfo.DetailType.allCases, id: \.self) { detailType in
                        if let value = nft.valueFor(detailType: detailType) {
                            nftOtherDetailsRowView(icon: detailType.icon,
                                                   title: detailType.title,
                                                   value: value,
                                                   pressedCallback: detailTypeActionHandler(detailType, value: value))
                        }
                    }
                }
            }
        }
    }
    
    var isNFTHasAnyDetails: Bool {
        NFTDisplayInfo.DetailType.allCases.first(where: { nft.valueFor(detailType: $0) != nil }) != nil
    }
    
    func detailTypeActionHandler(_ detailType: NFTDisplayInfo.DetailType, value: String) -> MainActorCallback? {
        switch detailType {
        case .collectionID:
            guard let url = URL(string: value) else { return nil }
            return { openLink(.direct(url: url)) }
        case .chain, .lastSaleDate:
            return nil
        }
    }
    
    @ViewBuilder
    func nftOtherDetailsRowView(icon: Image, 
                                title: String,
                                value: String,
                                pressedCallback: MainActorCallback?) -> some View {
        HStack {
            HStack(spacing: 8) {
                icon
                    .resizable()
                    .squareFrame(20)
                Text(title)
                    .font(.currentFont(size: 16))
                Spacer()
            }
            .foregroundStyle(.white.opacity(0.48))
            .frame(maxWidth: .infinity)
            
            Button {
                Task { @MainActor in
                    UDVibration.buttonTap.vibrate()
                    pressedCallback?()
                }
            } label: {
                HStack {
                    Text(value)
                        .font(.currentFont(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .allowsHitTesting(pressedCallback != nil)
        }
        .frame(height: 40)
        separatorView(dashed: true)
            .offset(y: 4)
    }
    
    @ViewBuilder
    func navActionsView() -> some View {
        Menu {
            ForEach(availableNFTActions(), id: \.self) { action in
                Button {
                    UDVibration.buttonTap.vibrate()
                    handleAction(action)
                } label: {
                    Label(
                        title: { Text(action.title) },
                        icon: { action.icon.bold() }
                    )
                }
            }
        } label: {
            Image.dotsIcon
                .resizable()
                .squareFrame(24)
                .foregroundStyle(Color.foregroundDefault)
        }
        .onButtonTap {
            
        }
    }
    
    func handleAction(_ action: NFTAction) {
        switch action {
        case .savePhoto(let image):
            let saver = PhotoLibraryImageSaver()
            saver.saveImage(image)
        case .refresh:
            return
        case .viewMarketPlace:
            return
        }
    }
    
    func availableNFTActions() -> [NFTAction] {
        var actions: [NFTAction] = []
        if let nftImage {
            actions.append(.savePhoto(nftImage))
        }
        actions.append(.refresh)
        
        return actions
    }
    
    enum NFTAction: Hashable {
        case savePhoto(UIImage)
        case refresh
        case viewMarketPlace
        
        var title: String {
            switch self {
            case .refresh:
                return String.Constants.refreshMetadata.localized()
            case .savePhoto:
                return String.Constants.saveToPhotos.localized()
            case .viewMarketPlace:
                return String.Constants.viewOnMarketPlace.localized()
            }
        }
        
        var icon: Image {
            switch self {
            case .savePhoto:
                return Image(systemName: "square.and.arrow.down")
            case .refresh:
                return .appleIcon
            case .viewMarketPlace:
                return Image(systemName: "arrow.up.right")
            }
        }
    }
}

#Preview {
    NFTDetailsView(nft: MockEntitiesFabric.NFTs.mockDisplayInfo())
}
