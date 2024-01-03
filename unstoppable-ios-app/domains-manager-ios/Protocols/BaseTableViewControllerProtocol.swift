//
//  BaseTableViewControllerProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2022.
//

import UIKit

@MainActor
protocol BaseTableViewControllerProtocol: BaseViewControllerProtocol {
    var tableView: UITableView! { get }
    var cellIdentifiers: [UITableViewCell.Type] { get }
    var isRefreshControlEnabled: Bool { get }
    var refreshControlColor: UIColor { get }
    func configureTableView() // MARK: - Should be called in viewDidload()
    func reloadTableView()
    func tableViewRefreshAction()
    func reloadSections(_ sections: IndexSet, withAnimation animation: UITableView.RowAnimation)
    func reloadRowsAt(indexPaths: [IndexPath], withAnimation animation: UITableView.RowAnimation)
    func insertRowsAt(indexPaths: [IndexPath], withAnimation animation: UITableView.RowAnimation)
    func deleteRowsAt(indexPaths: [IndexPath], withAnimation animation: UITableView.RowAnimation, completion: ((Bool)->())?)
    func scrollToRowAt(indexPath: IndexPath, atPosition position: UITableView.ScrollPosition, animated: Bool)
    func reloadVisibleRows()
}

extension BaseTableViewControllerProtocol {
    var refreshControlColor: UIColor { return .white }
    
    var isRefreshControlEnabled: Bool { return true }
    
    func tableViewRefreshAction() { }
    
    func reloadTableView() {
        tableView?.reloadData()
    }
    
    func reloadSections(_ sections: IndexSet, withAnimation animation: UITableView.RowAnimation = .automatic) {
        tableView.reloadSections(sections, with: animation)
    }
    func reloadRowsAt(indexPaths: [IndexPath], withAnimation animation: UITableView.RowAnimation = .automatic) {
        tableView.performBatchUpdates({
            tableView.reloadRows(at: indexPaths, with: animation)
        }, completion: nil)
    }
    
    func insertRowsAt(indexPaths: [IndexPath], withAnimation animation: UITableView.RowAnimation = .automatic) {
        tableView.performBatchUpdates({
            tableView.insertRows(at: indexPaths, with: animation)
        }, completion: nil)
    }
    
    func deleteRowsAt(indexPaths: [IndexPath], withAnimation animation: UITableView.RowAnimation = .automatic, completion: ((Bool)->())? = nil) {
        tableView?.performBatchUpdates({
            tableView.deleteRows(at: indexPaths, with: animation)
        }, completion: completion)
    }
    
    func scrollToRowAt(indexPath: IndexPath, atPosition position: UITableView.ScrollPosition, animated: Bool) {
        tableView.scrollToRow(at: indexPath, at: position, animated: animated)
    }
    
    func reloadVisibleRows() {
        reloadRowsAt(indexPaths: tableView.indexPathsForVisibleRows ?? [], withAnimation: .none)
    }
    
    func configureTableView() {
        for cell in cellIdentifiers {
            guard Bundle.main.path(forResource: cell.cellIdentifier, ofType: "nib") != nil else { continue }
            tableView.registerCellNibOfType(cell.self)
        }
        
        if isRefreshControlEnabled {
            let refreshControl = UIRefreshControl()
            refreshControl.attributedTitle = NSAttributedString(string: "")
            refreshControl.addTarget(self, action: #selector(refreshAction(_:)), for: .valueChanged)
            refreshControl.tintColor = refreshControlColor
            tableView.refreshControl = refreshControl
            tableView.addSubview(refreshControl)
        }
    }
}

@objc extension UIViewController {
    @objc func refreshAction(_ refreshControl: UIRefreshControl) {
        if let self = self as? BaseTableViewControllerProtocol {
            self.tableViewRefreshAction()
        }
    }
}
