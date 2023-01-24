//
//  DomainsListViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.12.2022.
//

import Foundation

@MainActor
protocol DomainsListViewPresenterProtocol: BasePresenterProtocol {
    var analyticsName: Analytics.ViewName { get }
    var scrollableContentYOffset: CGFloat { get }
    var navBackStyle: BaseViewController.NavBackIconStyle { get }
    var title: String { get }
    var isSearchable: Bool { get }
    
    func didSelectItem(_ item: DomainsListViewController.Item)
    func didSearchWith(key: String)
    func rearrangeButtonPressed()
}

class DomainsListViewPresenter: ViewAnalyticsLogger {
    
    private(set) weak var view: DomainsListViewProtocol?
    var domains: [DomainDisplayInfo]

    var scrollableContentYOffset: CGFloat { 48 }
    var analyticsName: Analytics.ViewName { .unspecified }
    var navBackStyle: BaseViewController.NavBackIconStyle { .arrow }
    var title: String { "" }
    var isSearchable: Bool { false }
    private(set) var searchKey: String = ""

    init(view: DomainsListViewProtocol,
         domains: [DomainDisplayInfo]) {
        self.view = view
        self.domains = domains
    }
    
    @MainActor func viewDidLoad() { }
    @MainActor func didSelectItem(_ item: DomainsListViewController.Item) { }
    @MainActor func didSearchWith(key: String) {
        self.searchKey = key.trimmedSpaces.lowercased()
    }
    @MainActor func rearrangeButtonPressed() { }
}

// MARK: - DomainsListViewPresenterProtocol
extension DomainsListViewPresenter: DomainsListViewPresenterProtocol { }

// MARK: - Private functions
private extension DomainsListViewPresenter { }
