//
//  TextMessageRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI

struct TextMessageRowView: View {
    
    @EnvironmentObject var viewModel: ChatViewModel

    let info: MessagingChatMessageTextTypeDisplayInfo
    let sender: MessagingChatSender
    let isFailed: Bool
    @Environment(\.openURL) private var openURL

    var body: some View {
        Text(toDetectedAttributedString(info.text))
            .padding(.init(horizontal: 12))
            .padding(.init(vertical: 6))
            .foregroundStyle(foregroundColor)
            .background(sender.isThisUser ? Color.backgroundAccentEmphasis : Color.backgroundMuted2)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .environment(\.openURL, OpenURLAction { url in
                viewModel.handleExternalLinkPressed(url, by: sender)
                return .discarded
            })
            .contextMenu {
                Button {
                    viewModel.handleChatMessageAction(.copyText(info.text))
                } label: {
                    Label(String.Constants.copy.localized(), systemImage: "doc.on.doc")
                }
                
                if !sender.isThisUser {
                    Divider()
                    MessageActionBlockUserButtonView(sender: sender)
                }
            }
    }
}

// MARK: - Private methods
private extension TextMessageRowView {
    var foregroundColor: Color {
        if isFailed {
            return .foregroundOnEmphasisOpacity
        }
        return sender.isThisUser ? .foregroundOnEmphasis : .foregroundDefault
    }
    
    func toDetectedAttributedString(_ string: String) -> AttributedString {
        var attributedString = AttributedString(string)
        
        let types = NSTextCheckingResult.CheckingType.link.rawValue | NSTextCheckingResult.CheckingType.phoneNumber.rawValue
        
        guard let detector = try? NSDataDetector(types: types) else {
            return attributedString
        }
        
        let matches = detector.matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
        
        for match in matches {
            let range = match.range
            let startIndex = attributedString.index(attributedString.startIndex, offsetByCharacters: range.lowerBound)
            let endIndex = attributedString.index(startIndex, offsetByCharacters: range.length)
            // Setting URL for link
            if match.resultType == .link, let url = match.url {
                attributedString[startIndex..<endIndex].link = url
            }
            // Setting URL for phone number
            if match.resultType == .phoneNumber, let phoneNumber = match.phoneNumber {
                let url = URL(string: "tel:\(phoneNumber)")
                attributedString[startIndex..<endIndex].link = url
            }
            attributedString[startIndex..<endIndex].foregroundColor = .white
            attributedString[startIndex..<endIndex].underlineStyle = .single
        }
        return attributedString
    }
}

#Preview {
    TextMessageRowView(info: .init(text: "Hello world"),
                       sender: MockEntitiesFabric.Messaging.chatSenderFor(isThisUser: false),
                       isFailed: true)
}
