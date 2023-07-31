//
//  PushServiceHelper.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 24.07.2023.
//

import Foundation
import Push

struct PushServiceHelper {
    func getCurrentPushEnvironment() -> Push.ENV {
        let isTestnetUsed = User.instance.getSettings().isTestnetUsed
        return isTestnetUsed ? .STAGING : .PROD
    }
}
