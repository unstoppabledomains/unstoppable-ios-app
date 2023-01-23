//
//  AppearanceSettingsViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.05.2022.
//

import Foundation
import UIKit

protocol AppearanceSettingsViewPresenterProtocol: BasePresenterProtocol {
    func didSelectItem(_ item: AppearanceSettingsViewController.Item)
}

final class AppearanceSettingsViewPresenter {
    private weak var view: AppearanceSettingsViewProtocol?
    
    init(view: AppearanceSettingsViewProtocol) {
        self.view = view
    }
}

// MARK: - AppearanceSettingsViewPresenterProtocol
extension AppearanceSettingsViewPresenter: AppearanceSettingsViewPresenterProtocol {
    func viewDidLoad() {
        displayUI()
    }
    
    func didSelectItem(_ item: AppearanceSettingsViewController.Item) {
        Task {
            switch item {
            case .theme(let selectedStyle):
                await showSelectAppearanceStyle(selectedStyle: selectedStyle)
            }
        }
    }
}

// MARK: - Private functions
private extension AppearanceSettingsViewPresenter {
    func displayUI() {
        Task {
            var snapshot = AppearanceSettingsSnapshot()
            
            snapshot.appendSections([.theme])
            snapshot.appendItems([.theme(UserDefaults.appearanceStyle)])
            
            await view?.applySnapshot(snapshot, animated: true)
        }
    }
    
    @MainActor
    func showSelectAppearanceStyle(selectedStyle: UIUserInterfaceStyle) {
        guard let view = self.view else { return }
        
        appContext.pullUpViewService.showAppearanceStyleSelectionPullUp(in: view, selectedStyle: selectedStyle) { [weak self] newStyle in
            Debugger.printInfo("New style \(newStyle.rawValue)")
            SceneDelegate.shared?.setAppearanceStyle(newStyle)
            self?.displayUI()
        }
    }
}
