//
//  UITableView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.04.2022.
//

import UIKit

extension UITableView {
    func registerCellNibOfType<T: UITableViewCell>(_ type: T.Type) {
        registerCellOfType(type, nibName: String(describing: type))
    }
    
    func registerCellOfType<T: UITableViewCell>(_ type: T.Type, nibName: String) {
        let reuseIdentifier = String(describing: type)
        register(UINib(nibName: nibName, bundle: nil), forCellReuseIdentifier: reuseIdentifier)
    }
    
    func registerHeaderFooterViewNibOfType<T: UITableViewHeaderFooterView>(_ type: T.Type) {
        registerHeaderFooterViewOfType(type, nibName: String(describing: type))
    }
    
    func registerHeaderFooterViewOfType<T: UITableViewHeaderFooterView>(_ type: T.Type, nibName: String) {
        let reuseIdentifier = String(describing: type)
        register(UINib(nibName: nibName, bundle: nil), forHeaderFooterViewReuseIdentifier: reuseIdentifier)
    }
    
    func dequeueCellOfType<T: UITableViewCell>(_ type: T.Type) -> T {
        return self.dequeueReusableCell(withIdentifier: String(describing: T.self)) as! T
    }
    
    func dequeueCellOfType<T: UITableViewCell>(_ type: T.Type, withIdentifier identifier: String) -> T {
        return self.dequeueReusableCell(withIdentifier: identifier) as! T
    }
    
    func dequeueHeaderFooterViewOfType<T: UITableViewHeaderFooterView>(_ type: T.Type) -> T {
        return self.dequeueReusableHeaderFooterView(withIdentifier: String(describing: T.self)) as! T
    }
    
    func dequeueHeaderFooterViewOfType<T: UITableViewHeaderFooterView>(_ type: T.Type, withIdentifier identifier: String) -> T {
        return self.dequeueReusableHeaderFooterView(withIdentifier: identifier) as! T
    }
}

