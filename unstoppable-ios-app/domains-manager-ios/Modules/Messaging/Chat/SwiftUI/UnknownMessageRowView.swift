//
//  UnknownMessageRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI

struct UnknownMessageRowView: View {
    
    let info: MessagingChatMessageUnknownTypeDisplayInfo
    let isThisUser: Bool

    var body: some View {
        HStack {
            iconView()
            VStack(alignment: .leading, spacing: 0) {
                Text(fileName)
                    .font(.currentFont(size: 16))
                    .foregroundStyle(tintColor)
                if let size = info.size {
                    downloadView(size: size)
                }
            }
        }
        .padding(6)
        .background(isThisUser ? Color.backgroundAccentEmphasis : Color.backgroundMuted2)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}


// MARK: - Private methods
private extension UnknownMessageRowView {
    var canDownload: Bool { info.size != nil }
    
    var fileName: String {
        info.name ?? String.Constants.messageNotSupported.localized()
    }
    var tintColor: Color { isThisUser ? Color.white : Color.foregroundDefault }
    
    var fileIcon: Image {
        if info.name == nil {
            return .helpIcon
        }
        return .docsIcon
    }
    
    @ViewBuilder
    func iconView() -> some View {
        fileIcon
            .resizable()
            .squareFrame(24)
            .padding(10)
            .foregroundStyle(tintColor)
            .background(Color.backgroundMuted2)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(lineWidth: 1)
                    .foregroundStyle(Color.borderMuted)
            }
    }
    
    
    @ViewBuilder
    func downloadView(size: Int) -> some View {
        Button {
            
        } label: {
            HStack(spacing: 2) {
                Text(String.Constants.download.localized())
                    .foregroundStyle(isThisUser ? Color.white : Color.foregroundAccent)
                    .font(.currentFont(size: 14, weight: .medium))
                Text("(\(bytesFormatter.string(fromByteCount: Int64(size))))")
                    .foregroundStyle(tintColor)
                    .font(.currentFont(size: 14))
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    UnknownMessageRowView(info: .init(fileName: "Filename", type: "zip"), isThisUser: false)
}
