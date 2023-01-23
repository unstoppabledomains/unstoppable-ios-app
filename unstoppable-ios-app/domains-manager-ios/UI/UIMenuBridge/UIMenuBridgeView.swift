//
//  UIMenuBridgeViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.08.2022.
//

import UIKit

struct UIActionBridgeItem {
    var title: String = ""
    var image: UIImage? = nil
    var isSelected: Bool = false
    var attributes: [Attributes] = []
    var handler: EmptyCallback?
    
    enum Attributes {
        case destructive, disabled
    }
}

final class UIMenuBridgeView: UIView{

    private var tableView: UITableView!
    static let Width: CGFloat = 254
    private var dismissView: UIView?
    var menuTitle: String = ""
    var actions = [UIActionBridgeItem]()
    
    static func instance(with menuTitle: String, actions: [UIActionBridgeItem]) -> UIMenuBridgeView {
        let vc = UIMenuBridgeView(frame: CGRect(origin: .zero, size: CGSize(width: Width,
                                                                            height: heightFor(actions: actions, title: menuTitle))))
        vc.menuTitle = menuTitle
        vc.actions = actions
        
        return vc
    }
    
    static func heightFor(actions: [UIActionBridgeItem], title: String) -> CGFloat {
        let actionsHeight = actions.map({ RowName.action($0) }).reduce(0, { $0 + $1.rowHeight }) - 2
        if title.isEmpty {
            return actionsHeight
        }
        return actionsHeight + RowName.title.rowHeight
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    func show(in view: UIView, sourceView: UIView) {
        let dismissView = UIView(frame: view.bounds)
        self.dismissView = dismissView
        dismissView.isUserInteractionEnabled = true
        dismissView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dismissView.backgroundColor = .clear
        dismissView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismiss)))
        view.addSubview(dismissView)
        
        alpha = 0
        view.addSubview(self)
        let spacing: CGFloat = 8
        let sourceFrame = sourceView.convert(sourceView.frame, to: view)
        
        if (sourceFrame.maxX + frame.width + spacing) < view.frame.width {
            frame.origin.x = sourceFrame.minX
        } else {
            frame.origin.x = view.frame.width - frame.width - spacing
        }
        if (sourceFrame.maxY + frame.height + spacing) < view.frame.height {
            frame.origin.y = sourceFrame.maxY + spacing
        } else {
            frame.origin.y = sourceFrame.minY - frame.height - spacing
        }
        
        applyFigmaShadow(style: .medium)
        transform = .init(scaleX: 0.7, y: 0.7)
        UIView.animate(withDuration: 0.15) {
            self.alpha = 1
            self.transform = .identity
        }
    }
    
}

// MARK: - UITableViewDataSource
extension UIMenuBridgeView: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return allSections().count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = allSections()[section]
        
        return rowsFor(section: section).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = allSections()[indexPath.section]
        let row  = rowsFor(section: section)[indexPath.row]
        
        switch row {
        case .title:
            let cell = tableView.dequeueCellOfType(UIMenuBridgeViewControllerTitleCell.self)
            cell.setTitle(menuTitle)
            
            return cell
        case .action(let action):
            let cell = tableView.dequeueCellOfType(UIMenuBridgeViewControllerItemCell.self)
            cell.setWith(text: action.title,
                         icon: action.image,
                         isSelected: action.isSelected,
                         style: action.attributes.contains(.destructive) ? .destructive : .default,
                         isEnabled: !action.attributes.contains(.disabled))
            
            return cell
        }
    }
}

// MARK: - UITableViewDelegate
extension UIMenuBridgeView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let section = allSections()[indexPath.section]
        let row  = rowsFor(section: section)[indexPath.row]
        
        return row.rowHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = allSections()[indexPath.section]
        let row  = rowsFor(section: section)[indexPath.row]
        
        switch row {
        case .title:
            return
        case .action(let action):
            action.handler?()
            dismiss()
        }
    }
}

// MARK: - Private methods
private extension UIMenuBridgeView {
    @objc
    func dismiss() {
        UIView.animate(withDuration: 0.15) {
            self.alpha = 0
            self.transform = .init(scaleX: 0.7, y: 0.7)
        } completion: { _ in
            self.removeSubviewWith()
            self.dismissView?.removeFromSuperview()
        }
    }
}

// MARK: - Setup methods
private extension UIMenuBridgeView {
    func setup() {
        clipsToBounds = true
        layer.cornerRadius = 12
        layer.borderWidth = 1
        layer.borderColor = UIColor.borderMuted.cgColor
        setupBackground()
        setupTableView()
    }
    
    func setupBackground() {
        let blur = UIVisualEffectView(frame: bounds)
        addSubview(blur)
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blur.effect = UIBlurEffect(style: .systemMaterial)
    }
    
    func setupTableView() {
        tableView = UITableView(frame: bounds)
        tableView.backgroundColor = .clear
        addSubview(tableView)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isScrollEnabled = false
        
        tableView.tableFooterView = UIView()
        tableView.registerCellNibOfType(UIMenuBridgeViewControllerTitleCell.self)
        tableView.registerCellNibOfType(UIMenuBridgeViewControllerItemCell.self)
    }
}
// MARK: - TableView enums
private extension UIMenuBridgeView {
    enum TableSection: Int, CaseIterable {
        case main
    }
    
    func rowsFor(section: TableSection) -> [RowName] {
        switch section {
        case .main:
            var rows = self.actions.map({ RowName.action($0) })
            if !menuTitle.isEmpty {
                rows.insert(.title, at: 0)
            }
            
            return rows
        }
    }
    
    func isLastSection(_ section: TableSection) -> Bool {
        return allSections().firstIndex(of: section) == allSections().count - 1
    }
    
    func heightForFooterIn(section: TableSection) -> CGFloat {
        let bottomFooterHeight: CGFloat = 100
        
        if isLastSection(section) {
            return bottomFooterHeight
        } else {
            return .leastNormalMagnitude
        }
    }
    
    func allSections() -> [TableSection] {
        return TableSection.allCases
    }
    
    enum RowName {
        case title, action(_ action: UIActionBridgeItem)
        
        // Height for row
        fileprivate var rowHeight: CGFloat {
            switch self {
            case .title:
                return 38
            case .action:
                return 44
            }
        }
    }
}
