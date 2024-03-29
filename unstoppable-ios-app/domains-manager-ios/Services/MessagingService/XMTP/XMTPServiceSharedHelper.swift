//
//  XMTPServiceSharedHelper.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.08.2023.
//

import Foundation

struct XMTPServiceSharedHelper {
    
    static func isInvitationTopic(_ topic: String) -> Bool {
        let inviteKeyword = "invite"
        let inviteAddressSeparator = "-"
        
        let topicComponents = topic.components(separatedBy: "/")
        guard let inviteComponent = topicComponents.first(where: { $0.lowercased().contains(inviteKeyword) }),
              inviteComponent.contains(inviteAddressSeparator) else { return false }
        
        let inviteComponents = inviteComponent.components(separatedBy: inviteAddressSeparator)
        guard inviteComponents.count == 2,
              inviteComponents.first == inviteKeyword else { return false }
        
        return true
    }
    
    static func getXMTPVersion() -> String {
        let appName = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? ""
        let version: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let build: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        let xmtpVersion = "\(appName)/\(version)(\(build))"
        return xmtpVersion
    }
}
