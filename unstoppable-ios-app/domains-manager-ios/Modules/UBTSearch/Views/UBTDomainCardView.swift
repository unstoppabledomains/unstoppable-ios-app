//
//  UDDomainCardView.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 18.08.2023.
//

import SwiftUI

struct UBTDomainCardView: View {
    
    let device: BTDomainUIInfo
    private let widthToHeightRatio: CGFloat = 160/208
    private let innerImageOffset: CGFloat = 8
    @State private var avatarImage: UIImage?
    
    var body: some View {
        GeometryReader { geom in
            let contentWidth = geom.size.width
            let contentHeight = geom.size.width / widthToHeightRatio
            let innerImageSize = contentWidth - innerImageOffset * 2
            let domainNameHeight: CGFloat = 22
            let domainTLDHeight: CGFloat = 18
            let udLogoSize: CGFloat = 27
            
            ZStack(alignment: .top) {
                backgroundView(contentWidth: contentWidth,
                               contentHeight: contentHeight)
                
                HStack {
                    Spacer(minLength: innerImageOffset)
                    VStack(alignment: .leading, spacing: 8) {
                        innerImageView(innerImageSize: innerImageSize,
                                       udLogoSize: udLogoSize)
                        
                        HStack {
                            labelsView(domainNameHeight: domainNameHeight,
                                       domainTLDHeight: domainTLDHeight)
                        }
                    }
                    .offset(y: innerImageOffset)
                    Spacer(minLength: innerImageOffset)
                }
            }
            .frame(width: contentWidth, height: contentHeight)
            .cornerRadius(12)
            .offset(y: 2)
            .shadow(color: .black.opacity(0.08), radius: 2)
        }
        .onAppear(perform: loadAvatar)
    }
    
    init(device: BTDomainUIInfo) {
        self.device = device
    }
    
}

// MARK: - Private methods
private extension UBTDomainCardView {
    func loadAvatar() {
        Task {
            do {
                let profileDetails = try await NetworkService().fetchPublicProfile(for: device.domainName,
                                                                                   fields: [.profile, .records])
                
                if let pfpURL = profileDetails.profile.imagePath,
                   let url = URL(string: pfpURL) {
                    avatarImage = await appContext.imageLoadingService.loadImage(from: .url(url),
                                                                                 downsampleDescription: .mid)
                }
            }
        }
    }
}

// MARK: - Subviews
private extension UBTDomainCardView {
    @ViewBuilder
    func backgroundView(contentWidth: CGFloat,
                        contentHeight: CGFloat) -> some View {
        if let avatarImage {
            Image(uiImage: avatarImage)
                .resizable()
                .scaledToFill()
                .frame(width: contentWidth, height: contentHeight)
                .clipped()
                .blur(radius: 50, opaque: true)
        } else {
            Color.backgroundAccentEmphasis
                .frame(width: contentWidth, height: contentHeight)
        }
    }
    
    @ViewBuilder
    func innerImageView(innerImageSize: CGFloat,
                        udLogoSize: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            Image(uiImage: avatarImage ?? .domainSharePlaceholder)
                .resizable()
                .scaledToFill()
                .frame(width: innerImageSize,
                       height: innerImageSize)
                .cornerRadius(8)
                .clipped()
            Image.udCartLogoRaster
                .resizable()
                .frame(width: udLogoSize,
                       height: udLogoSize)
                .offset(x: 8, y: 8)
            if avatarImage == nil {
                Color.black.opacity(0.16)
                    .cornerRadius(8)
                    .frame(width: innerImageSize,
                           height: innerImageSize)
            }
        }
    }
    
    @ViewBuilder
    func labelsView(domainNameHeight: CGFloat,
                    domainTLDHeight: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(device.domainName.getBelowTld()?.uppercased() ?? "")
                .foregroundColor(.white)
                .frame(height: domainNameHeight, alignment: .leading)
                .font(.helveticaNeueCustom(size: 21))
            
            AttributedText(text: ".\(device.domainName.getTldName() ?? "")".uppercased(),
                           font: .helveticaNeueCustom(size: 18),
                           letterSpacing: 0,
                           textColor: .clear,
                           lineBreakMode: .byTruncatingTail,
                           strokeColor: .white,
                           strokeWidth: 3)
            .frame(height: domainTLDHeight, alignment: .leading)
            .offset(x: -4)
        }
    }
}

struct UDDomainCardView_Previews: PreviewProvider {
    static var previews: some View {
        UBTDomainCardView(device: .mock)
            .frame(width: 160)
    }
}
