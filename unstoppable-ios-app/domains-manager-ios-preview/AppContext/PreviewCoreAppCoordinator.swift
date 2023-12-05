//
//  PreviewCoreAppCoordinator.swift
//  unstoppable-preview
//
//  Created by Oleg Kuplin on 01.12.2023.
//

import Foundation


@MainActor
protocol CoreAppCoordinatorProtocol {
    func didRegisterShakeDevice()
}

final class CoreAppCoordinator: CoreAppCoordinatorProtocol {
    nonisolated init() {
        
    }
    
    func didRegisterShakeDevice() { }
}
