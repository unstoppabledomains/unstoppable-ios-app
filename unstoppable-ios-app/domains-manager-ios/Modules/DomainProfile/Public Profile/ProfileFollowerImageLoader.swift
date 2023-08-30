//
//  ProfileFollowerImageLoader.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 29.08.2023.
//

import UIKit

protocol ProfileFollowerImageLoader { }

extension ProfileFollowerImageLoader {
    func loadIconFor(follower: DomainProfileFollowerDisplayInfo) async -> UIImage? {
        let num = Double(arc4random_uniform(10))
        try? await Task.sleep(seconds: num / 10)
        let icon = UIImage(named: "testava")
        return icon
    }
}
