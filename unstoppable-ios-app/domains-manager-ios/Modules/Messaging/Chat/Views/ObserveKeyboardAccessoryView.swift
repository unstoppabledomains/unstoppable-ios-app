//
//  ObserveKeyboardAccessoryView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2023.
//

import UIKit

final class ObserveKeyboardAccessoryView: UIView {
    
    
    private var observerAdded = false
    var context: UnsafeMutableRawPointer?
    var inputAccessoryViewFrameChangedBlock: ((CGRect)->())?
    var inputAccessorySuperviewFrame: CGRect { superview?.frame ?? .zero }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        if observerAdded {
            superview?.removeObserver(self, forKeyPath: "frame", context: context)
            superview?.removeObserver(self, forKeyPath: "center", context: context)
        }
        
        newSuperview?.addObserver(self, forKeyPath: "frame", context: context)
        newSuperview?.addObserver(self, forKeyPath: "center", context: context)
        self.observerAdded = true
        
        
        super.willMove(toSuperview: newSuperview)
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if let objectView = object as? UIView,
           objectView == self.superview,
           (keyPath == "frame" || keyPath == "center") {
            let frame = self.superview?.frame ?? .zero
            inputAccessoryViewFrameChangedBlock?(frame)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let frame = self.superview?.frame ?? .zero
        inputAccessoryViewFrameChangedBlock?(frame)
    }
}

// MARK: - Setup methods
private extension ObserveKeyboardAccessoryView {
    func setup() {
        isUserInteractionEnabled = false
    }
}
