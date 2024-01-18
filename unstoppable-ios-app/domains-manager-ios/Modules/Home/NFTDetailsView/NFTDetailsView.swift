//
//  NFTDetailsView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.01.2024.
//

import SwiftUI

struct NFTDetailsView: View {
    
    let nft: NFTDisplayInfo
    @State private var nftImage: UIImage?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                DismissIndicatorView()
                nftImageView()
                nftCollectionInfoView()
                separatorView()
                nftDescriptionInfoView()
            }
            .padding()
        }
        .animation(.default, value: UUID())
        .onAppear(perform: onAppear)
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
    func separatorView() -> some View {
        Line()
            .stroke(lineWidth: 1)
            .foregroundStyle(Color.foregroundSecondary)
    }
    
    @ViewBuilder
    func nftCollectionInfoView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(nft.name ?? "-")
                    .font(.currentFont(size: 22, weight: .bold))
                    .foregroundStyle(Color.foregroundDefault)
                Spacer()
                Menu {
                    ForEach(NFTAction.allCases, id: \.self) { action in
                        Button {
                            
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
    
    var collectionName: String { nft.collection ?? "-" }
    
    @ViewBuilder
    func nftDescriptionInfoView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image.notesIcon
                    .resizable()
                    .squareFrame(20)
                    .foregroundStyle(Color.foregroundSecondary)
                Text(String.Constants.nftDetailsAboutCollectionHeader.localized(collectionName))
                    .font(.currentFont(size: 16, weight: .medium))
                    .foregroundStyle(Color.foregroundDefault)
                Spacer()
            }
            Text(nft.description ?? "-")
                .font(.currentFont(size: 16))
                .foregroundStyle(Color.foregroundSecondary)
        }
        .frame(maxWidth: .infinity)
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
    NFTDetailsView(nft: .mock())
}
