//
//  KeepingAnimationImageView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 14.06.2022.
//

import UIKit

class KeepingAnimationImageView: UIImageView {
    
    private var animationsStorage: [String: CAAnimation] = [:]
    private var didStoreAnimations = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        registerForNotifications()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        registerForNotifications()
    }
    
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil { storeAnimations() }
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { restoreAnimations() }
    }
}

private extension KeepingAnimationImageView {
    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillResignActive),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillEnterForeground),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    @objc func applicationWillResignActive() {
        
        guard window != nil else { return }
        storeAnimations()
    }
    
    @objc func applicationWillEnterForeground() {
        
        guard window != nil else { return }
        restoreAnimations()
    }
    
    func storeAnimations() {
        guard !didStoreAnimations else { return }
        
        layer.pause()
        animationsStorage = layer.animationsForKeys
        didStoreAnimations = true
    }
    
    func restoreAnimations() {
        guard didStoreAnimations else { return }
        
        animationsStorage.forEach { layer.add($0.value, forKey: $0.key) }
        animationsStorage = [:]
        layer.resume()
        didStoreAnimations = false
    }
}

extension CALayer {
    /// Returns a dictionary of copies of animations currently attached to the layer along with their's keys.
    var animationsForKeys: [String: CAAnimation] {
        guard let keys = animationKeys() else { return [:] }
        return keys.reduce([:], {
            var result = $0
            let key = $1
            result[key] = (animation(forKey: key)!.copy() as! CAAnimation)
            return result
        })
    }
 
    /// Pauses animations in layer tree.
    func pause() {
        let pausedTime = convertTime(CACurrentMediaTime(), from: nil)
        speed = 0.0;
        timeOffset = pausedTime;
    }
    
    /// Resumes animations in layer tree.
    func resume() {
        let pausedTime = timeOffset;
        speed = 1.0;
        timeOffset = 0.0;
        beginTime = 0.0;
        let timeSincePause = convertTime(CACurrentMediaTime(), from: nil) - pausedTime;
        beginTime = timeSincePause;
    }
}
