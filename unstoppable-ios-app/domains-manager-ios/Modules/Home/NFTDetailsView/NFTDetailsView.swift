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
            })
        }, navigationStateProvider: { navigationState in
            self.navigationState = navigationState
            navigationState.customTitle = navigationView
        }, path: .constant(.init()))
    }
}

// MARK: - Private methods
private extension NFTDetailsView {
    func onAppear() {
        Task {
            try? await Task.sleep(seconds: 1)
            nftImage = await nft.loadIcon()
        }
    }
    
    @ViewBuilder
    func navigationView() -> some View {
        VStack(spacing: 0) {
            Text(nft.displayName)
                .font(.currentFont(size: 16, weight: .semibold))
                .foregroundStyle(Color.foregroundDefault)
                .frame(height: 24)
            Text(collectionName)
                .font(.currentFont(size: 16, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.56))
                .frame(height: 16)
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
                Menu {
                    ForEach(NFTAction.allCases, id: \.self) { action in
                        Button {
                            UDVibration.buttonTap.vibrate()
                            
                        } label: {
                            Label(
                                title: { Text(action.title) },
                                icon: { action.icon }
                            )
                        }
                    }
                } label: {
                    Image.dotsIcon
                        .resizable()
                        .squareFrame(24)
                        .foregroundStyle(Color.foregroundSecondary)
                }
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
            Text(nft.description ?? "-")
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
            nftPriceValueView(title: "Last Sale Price",
                              value: nft.lastSalePrice)
            separatorView(direction: .vertical)
                .frame(width: 1)
            nftPriceValueView(title: "Floor Price",
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
            Text(value ?? "None")
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
                                  title: "Traits")
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
                                  title: "Details")
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
    
    enum NFTAction: CaseIterable {
        case refresh, savePhoto, viewMarketPlace
        
        var title: String {
            switch self {
            case .refresh:
                return "Refresh Metadata"
            case .savePhoto:
                return "Save to Photos"
            case .viewMarketPlace:
                return "View on Marketplace"
            }
        }
        
        var icon: Image {
            switch self {
            case .refresh:
                return .appleIcon
            case .savePhoto:
                return .appleIcon
            case .viewMarketPlace:
                return .appleIcon
            }
        }
    }
}

#Preview {
    NFTDetailsView(nft: MockEntitiesFabric.NFTs.mockDisplayInfo())
}
