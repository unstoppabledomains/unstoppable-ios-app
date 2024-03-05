//
//  TaskWithDeadline.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.02.2024.
//

import Foundation

final class TaskWithDeadline<Value> {
        
    let deadline: TimeInterval
    private var ongoingTask: Task<Value, Error>?
    private var operation: @Sendable () async throws -> Value
    private let responseQueue: DispatchQueue
    
    init(deadline: TimeInterval,
         responseQueue: DispatchQueue = .main,
         operation: @escaping @Sendable () async throws -> Value) {
        self.deadline = deadline
        self.responseQueue = responseQueue
        self.operation = operation
    }
    
    var value: Value {
        get async throws {
            if let ongoingTask {
                return try await ongoingTask.value
            }
            
            let ongoingTask = Task<Value, Error> {
                try await performOperationWithDelay()
            }
            self.ongoingTask = ongoingTask
            let result = try await ongoingTask.value
            self.ongoingTask = nil
            return result
        }
    }
    
    private func performOperationWithDelay() async throws -> Value {
        let responseQueue = self.responseQueue
       
        return try await withSafeCheckedThrowingContinuation(critical: false) { continuation in
            
            runOperation { result in
                responseQueue.async {
                    switch result {
                    case .success(let value):
                        continuation(.success(value))
                    case .failure(let error):
                        continuation(.failure(error))
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + deadline) {
                responseQueue.async {
                    continuation(.failure(TaskError.timeout))
                }
            }
        }
    }
    
    private func runOperation(completion: @escaping (Result<Value, Error>)->()) {
        Task {
            do {
                let value = try await operation()
                completion(.success(value))
               
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    private enum TaskError: Error {
        case timeout
    }
}
