//
//  TextMessageRowView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI

struct TextMessageRowView: View {
    
    @EnvironmentObject var viewModel: ChatViewModel

    let message: MessagingChatMessageDisplayInfo
    let info: MessagingChatMessageTextTypeDisplayInfo
    let referenceMessageId: String? 
    var sender: MessagingChatSender { message.senderType }
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading) {
            replyReferenceView()
            Text(toDetectedAttributedString(info.text))
        }
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
                MessageActionReplyButtonView(message: message)
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
        if message.isFailedMessage {
            return .foregroundOnEmphasisOpacity
        }
        return sender.isThisUser ? .foregroundOnEmphasis : .foregroundDefault
    }
    
    func toDetectedAttributedString(_ string: String) -> AttributedString {
        var attributedString = AttributedString(string)
        
        detectAndInsertLinks(to: &attributedString)
        detectAndInsertUserMentions(to: &attributedString)
        
        return attributedString
    }
    
    func detectAndInsertLinks(to attributedString: inout AttributedString) {
        let linkMatches = detectLinksIn(string: NSAttributedString(attributedString).string)
        
        for match in linkMatches {
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
    }
    
    func detectLinksIn(string: String) -> [NSTextCheckingResult] {
        let types = NSTextCheckingResult.CheckingType.link.rawValue | NSTextCheckingResult.CheckingType.phoneNumber.rawValue
        guard let detector = try? NSDataDetector(types: types) else { return [] }
        
        return detector.matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
    }
    
    func detectAndInsertUserMentions(to attributedString: inout AttributedString) {
        let string = NSAttributedString(attributedString).string
        let users = viewModel.listOfGroupParticipants.compactMap { $0.anyDomainName }
        let usernameMatches = detectUsernamesIn(string: string,
                                                users: users)
        let nsText = string as NSString

        for match in usernameMatches {
            let range = match.range
            let startIndex = attributedString.index(attributedString.startIndex, offsetByCharacters: range.lowerBound)
            let endIndex = attributedString.index(startIndex, offsetByCharacters: range.length)
            
            let username = nsText.substring(with: range)

            attributedString[startIndex..<endIndex].link = URL(string: username)
            attributedString[startIndex..<endIndex].foregroundColor = .white
            attributedString[startIndex..<endIndex].backgroundColor = .white.opacity(0.3)
        }
    }
    
    func detectUsernamesIn(string: String, users: [String]) -> [NSTextCheckingResult] {
        let pattern = "\(MessageMentionString.messageMentionPrefix)([\\w.]+)"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let nsText = string as NSString
        
        let matches = regex.matches(in: string, options: [], range: NSRange(location: 0, length: string.count))
        var detectedUsers: [NSTextCheckingResult] = []
        for match in matches {
            let rangeOfUsername = match.range(at: 1)
            let username = nsText.substring(with: rangeOfUsername)
            
            if users.contains(username) {
                detectedUsers.append(match)
            }
        }
        return detectedUsers
    }

}

// MARK: - Private methods
private extension TextMessageRowView {
    @ViewBuilder
    func replyReferenceView() -> some View {
        if let referenceMessageId {
            Button {
                
            } label: {
                HStack(spacing: 2) {
                    Line(direction: .vertical)
                        .stroke(lineWidth: 6)
                        .foregroundStyle(Color.brandUnstoppableBlue)
                        .frame(width: 6)
                        .padding(.init(vertical: -8))
                        .offset(x: -6)
                        .frame(height: 30)
                    VStack(alignment: .leading) {
                        Text("Hello there")
                            .font(.currentFont(size: 14, weight: .semibold))
                        Text("Hello there")
                            .font(.currentFont(size: 14))
                    }
                    .lineLimit(1)
                    Spacer()
                }
                .padding(.init(horizontal: 8, vertical: 8))
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }
    
    struct ReferenceWidthKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = value + nextValue()
        }
    }
}

#Preview {
    TextMessageRowView(message: MockEntitiesFabric.Messaging.createTextMessage(text: "Hello world", isThisUser: false),
                       info: .init(text: "Hello world"),
                       referenceMessageId: nil)
}
