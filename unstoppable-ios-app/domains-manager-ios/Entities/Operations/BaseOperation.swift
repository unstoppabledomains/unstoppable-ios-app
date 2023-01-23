//
//  BaseOperation.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.08.2022.
//

import Foundation

class BaseOperation: Operation {
    
    private var _finished = false {
        willSet {
            willChangeValue(forKey: "isFinished")
        }
        
        didSet {
            didChangeValue(forKey: "isFinished")
        }
    }
    
    override var isFinished: Bool {
        return _finished
    }
    
    func finish(_ finished: Bool) {
        _finished = finished
    }
    
    func checkIfCancelled() -> Bool {
        if isCancelled {
            finish(true)
            return true
        }
        return false
    }
    
}
