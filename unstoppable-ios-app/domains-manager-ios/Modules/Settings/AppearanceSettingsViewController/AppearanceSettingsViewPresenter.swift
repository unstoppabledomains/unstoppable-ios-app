//
//  AppearanceSettingsViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.05.2022.
//

import Foundation
import UIKit

@MainActor
protocol AppearanceSettingsViewPresenterProtocol: BasePresenterProtocol {
    func didSelectItem(_ item: AppearanceSettingsViewController.Item)
}

@MainActor
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
        switch item {
        case .theme(let selectedStyle):
            showSelectAppearanceStyle(selectedStyle: selectedStyle)
        }
    }
}

// MARK: - Private functions
private extension AppearanceSettingsViewPresenter {
    func displayUI() {
        var snapshot = AppearanceSettingsSnapshot()
        
        snapshot.appendSections([.theme])
        snapshot.appendItems([.theme(UserDefaults.appearanceStyle)])
        
        view?.applySnapshot(snapshot, animated: true)
    }
    
    func showSelectAppearanceStyle(selectedStyle: UIUserInterfaceStyle) {
        guard let view = self.view else { return }
        
        appContext.pullUpViewService.showAppearanceStyleSelectionPullUp(in: view, selectedStyle: selectedStyle) { [weak self] newStyle in
            Debugger.printInfo(topic: .UI, "New style \(newStyle.rawValue)")
            SceneDelegate.shared?.setAppearanceStyle(newStyle)
            self?.displayUI()
        }
    }
}
