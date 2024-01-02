//
//  MessagingServiceDataRefreshManager.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.07.2023.
//

import Foundation

protocol MessagingServiceDataRefreshManagerDelegate: AnyObject {
    func didStartUpdatingProfile(_ userProfile: MessagingChatUserProfileDisplayInfo)
    func didFinishUpdatingProfile(_ userProfile: MessagingChatUserProfileDisplayInfo)
}

final class MessagingServiceDataRefreshManager {
    
    weak var delegate: MessagingServiceDataRefreshManagerDelegate?
    
    private let serialQueue = DispatchQueue(label: "com.messaging.service.unstoppable")
    private var updatingChatUsersIds: Set<String> = []
    private var updatingChannelsUsersIds: Set<String> = []
    
    func isUpdatingUserData(_ userProfile: MessagingChatUserProfileDisplayInfo) -> Bool {
        serialQueue.sync {
            updatingChatUsersIds.contains(userProfile.id) || updatingChannelsUsersIds.contains(userProfile.id)
        }
    }
    
    func startUpdatingChats(for userProfile: MessagingChatUserProfileDisplayInfo) {
        notifyIfNeededUpdateStartedForProfile(userProfile)
        _ = serialQueue.sync {
            updatingChatUsersIds.insert(userProfile.id)
        }
    }
    
    func stopUpdatingChats(for userProfile: MessagingChatUserProfileDisplayInfo) {
        _ = serialQueue.sync {
            updatingChatUsersIds.remove(userProfile.id)
        }
        notifyIfNeededUpdateFinishedForProfile(userProfile)
    }
    
    func startUpdatingChannels(for userProfile: MessagingChatUserProfileDisplayInfo) {
        notifyIfNeededUpdateStartedForProfile(userProfile)
        _ = serialQueue.sync {
            updatingChannelsUsersIds.insert(userProfile.id)
        }
    }
    
    func stopUpdatingChannels(for userProfile: MessagingChatUserProfileDisplayInfo) {
        _ = serialQueue.sync {
            updatingChannelsUsersIds.remove(userProfile.id)
        }
        notifyIfNeededUpdateFinishedForProfile(userProfile)
    }
    
    private func notifyIfNeededUpdateStartedForProfile(_ userProfile: MessagingChatUserProfileDisplayInfo) {
        if !isUpdatingUserData(userProfile) {
            didStartUpdatingProfile(userProfile)
        }
    }
    
    private func notifyIfNeededUpdateFinishedForProfile(_ userProfile: MessagingChatUserProfileDisplayInfo) {
        if !isUpdatingUserData(userProfile) {
            didFinishUpdatingProfile(userProfile)
        }
    }
    
    private func didStartUpdatingProfile(_ userProfile: MessagingChatUserProfileDisplayInfo) {
        Debugger.printInfo(topic: .Messaging, "Did start updating profile: \(userProfile.id)")
        delegate?.didStartUpdatingProfile(userProfile)
    }
    
    private func didFinishUpdatingProfile(_ userProfile: MessagingChatUserProfileDisplayInfo) {
        Debugger.printInfo(topic: .Messaging, "Did finish updating profile: \(userProfile.id)")
        delegate?.didFinishUpdatingProfile(userProfile)
    }
}
