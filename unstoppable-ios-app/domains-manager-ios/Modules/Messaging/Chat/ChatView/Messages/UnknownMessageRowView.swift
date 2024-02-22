//
//  UnknownMessageRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI

struct UnknownMessageRowView: View {
    
    let message: MessagingChatMessageDisplayInfo
    let info: MessagingChatMessageUnknownTypeDisplayInfo
    let sender: MessagingChatSender
    @State private var error: Error?

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
        .background(sender.isThisUser ? Color.backgroundAccentEmphasis : Color.backgroundMuted2)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .displayError($error)
        .contextMenu {
            if !sender.isThisUser {
                MessageActionBlockUserButtonView(sender: sender)
            }
        }
    }
}


// MARK: - Private methods
private extension UnknownMessageRowView {
    var canDownload: Bool { info.size != nil }
    
    var fileName: String {
        info.name ?? String.Constants.messageNotSupported.localized()
    }
    var tintColor: Color { sender.isThisUser ? Color.white : Color.foregroundDefault }
    
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
            shareUnknownMessageContent()
        } label: {
            HStack(spacing: 2) {
                Text(String.Constants.download.localized())
                    .foregroundStyle(sender.isThisUser ? Color.white : Color.foregroundAccent)
                    .font(.currentFont(size: 14, weight: .medium))
                Text("(\(bytesFormatter.string(fromByteCount: Int64(size))))")
                    .foregroundStyle(tintColor)
                    .font(.currentFont(size: 14))
            }
        }
        .buttonStyle(.plain)
    }
    
    func shareUnknownMessageContent() {
        Task {
            guard let contentURL = await appContext.messagingService.decryptedContentURLFor(message: message) else {
                error = LocalError.decryptionError
                Debugger.printFailure("Failed to decrypt message content of \(message.id) - \(message.time) in \(message.chatId)")
                return
            }
            
            await shareItems([contentURL], completion: nil)
        }
    }
    
    enum LocalError: Error {
        case decryptionError
    }
}

#Preview {
    UnknownMessageRowView(message: MockEntitiesFabric.Messaging.createUnknownContentMessage(isThisUser: false),
                          info: .init(fileName: "Filename", type: "zip"), sender: MockEntitiesFabric.Messaging.chatSenderFor(isThisUser: false))
}
