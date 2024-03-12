//
//  CombineValuesCapturer.swift
//  domains-manager-iosTests
//
//  Created by Oleg Kuplin on 07.03.2024.
//

import Foundation
import Combine

final class CombineValuesCapturer<Entity> {
    
    private(set) var capturedValues: [Entity] = []
    private var cancellables: [AnyCancellable] = []
    
    init(currentValueSubject: CurrentValueSubject<Entity,Never>) {
        currentValueSubject.sink { value in
            self.capturedValues.append(value)
        }
        .store(in: &cancellables)
    }
    
    init(passthroughSubject: PassthroughSubject<Entity, Never>) {
        passthroughSubject.sink { value in
            self.capturedValues.append(value)
        }
        .store(in: &cancellables)
    }
    
    func clear() {
        capturedValues.removeAll()
    }
}
