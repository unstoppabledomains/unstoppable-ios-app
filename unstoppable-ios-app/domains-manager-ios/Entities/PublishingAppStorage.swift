//
//  PublishingAppStorage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.11.2023.
//

import Foundation
import Combine
import SwiftUI

@propertyWrapper
struct PublishingAppStorage<Value> {
    var wrappedValue: Value {
        get { storage.wrappedValue }
        set {
            storage.wrappedValue = newValue
            subject.send(storage.wrappedValue)
        }
    }
    
    var projectedValue: Self {
        self
    }
    
    
    
    private var storage: AppStorage<Value>
    /// Provides a ``Publisher`` for non view code to respond to value updates.
    private let subject = PassthroughSubject<Value, Never>()
    var publisher: AnyPublisher<Value, Never> {
        subject.eraseToAnyPublisher()
    }
    
    /// Provides access to ``AppStorage.projectedValue`` for binding purposes.
    var binding: Binding<Value> {
        Binding {
            storage.wrappedValue
        } set: { value in
            storage.wrappedValue = value
            subject.send(storage.wrappedValue)
        }
    }
    
    
    init(wrappedValue: Value, _ key: String) where Value == String {
        storage = AppStorage(wrappedValue: wrappedValue, key)
    }
    init(wrappedValue: Value, _ key: String) where Value: RawRepresentable, Value.RawValue == Int {
        storage = AppStorage(wrappedValue: wrappedValue, key)
    }
    init(wrappedValue: Value, _ key: String) where Value == Data {
        storage = AppStorage(wrappedValue: wrappedValue, key)
    }
    init(wrappedValue: Value, _ key: String) where Value == Int {
        storage = AppStorage(wrappedValue: wrappedValue, key)
    }
    init(wrappedValue: Value, _ key: String) where Value: RawRepresentable, Value.RawValue == String {
        storage = AppStorage(wrappedValue: wrappedValue, key)
    }
    init(wrappedValue: Value, _ key: String) where Value == URL {
        storage = AppStorage(wrappedValue: wrappedValue, key)
    }
    init(wrappedValue: Value, _ key: String) where Value == Double {
        storage = AppStorage(wrappedValue: wrappedValue, key)
    }
    init(wrappedValue: Value, _ key: String) where Value == Bool {
        storage = AppStorage(wrappedValue: wrappedValue, key)
    }
    mutating func update() {
        storage.update()
    }
}
