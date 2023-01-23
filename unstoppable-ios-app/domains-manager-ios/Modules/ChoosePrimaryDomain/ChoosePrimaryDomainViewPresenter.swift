//
//  ChoosePrimaryDomainViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.05.2022.
//

import Foundation

protocol ChoosePrimaryDomainViewPresenterProtocol: BasePresenterProtocol, ViewAnalyticsLogger {
    var progress: Double? { get }
    var title: String { get }
    func didSelectItem(_ item: ChoosePrimaryDomainViewController.Item)
    func confirmButtonPressed()
    func reverseResolutionInfoHeaderPressed()
}

class ChoosePrimaryDomainViewPresenter: ChoosePrimaryDomainViewPresenterProtocol {
    
    private(set) weak var view: ChoosePrimaryDomainViewProtocol?
    var progress: Double? { nil }
    var title: String { "" }
    var analyticsName: Analytics.ViewName { .unspecified }
    
    init(view: ChoosePrimaryDomainViewProtocol) {
        self.view = view
    }
    
    // MARK: - ChoosePrimaryDomainViewPresenterProtocol
    func viewDidLoad() { }
    func didSelectItem(_ item: ChoosePrimaryDomainViewController.Item) { }
    func confirmButtonPressed() { }
    func reverseResolutionInfoHeaderPressed() {
        Task {
            guard let view = self.view else { return }
            
            await appContext.pullUpViewService.showWhatIsReverseResolutionInfoPullUp(in: view)
        }
    }
}

