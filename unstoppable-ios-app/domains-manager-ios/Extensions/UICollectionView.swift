//
//  UICollectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 08.04.2022.
//

import UIKit

extension UICollectionView {
    
    static let SideOffset: CGFloat = 16
    
    func registerCellNibOfType<T: UICollectionViewCell>(_ type: T.Type) {
        registerCellOfType(type, nibName: String(describing: type))
    }
    
    func registerCellOfType<T: UICollectionViewCell>(_ type: T.Type, nibName: String) {
        let reuseIdentifier = String(describing: type)
        register(UINib(nibName: nibName, bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
    }
    
    func dequeueCellOfType<T: UICollectionViewCell>(_ type: T.Type, forIndexPath indexPath: IndexPath) -> T {
        self.dequeueCellOfType(type, withIdentifier: String(describing: T.self), forIndexPath: indexPath)
    }
    
    func dequeueCellOfType<T: UICollectionViewCell>(_ type: T.Type, withIdentifier identifier: String, forIndexPath indexPath: IndexPath) -> T {
        self.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! T
    }
    
    func registerReusableViewNibOfType<T: UICollectionReusableView>(_ type: T.Type, forSupplementaryViewOfKind kind: String)  {
        registerReusableViewNibOfType(type, nibName: String(describing: type), forSupplementaryViewOfKind: kind)
    }
    
    func registerReusableViewNibOfType<T: UICollectionReusableView>(_ type: T.Type, nibName: String, forSupplementaryViewOfKind kind: String) {
        let reuseIdentifier = String(describing: type)
        register(UINib(nibName: nibName, bundle: nil), forSupplementaryViewOfKind: kind, withReuseIdentifier: reuseIdentifier)
    }
    
    func registerReusableViewOfType<T: UICollectionReusableView>(_ type: T.Type, forSupplementaryViewOfKind kind: String)  {
        let reuseIdentifier = String(describing: type)
        register(type, forSupplementaryViewOfKind: kind, withReuseIdentifier: reuseIdentifier)
    }
    
    func dequeueReusableViewOfType<T: UICollectionReusableView>(_ type: T.Type, withIdentifier identifier: String, supplementaryViewOfKind kind: String, forIndexPath indexPath: IndexPath) -> T {
        self.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: indexPath)  as! T
    }
    
    func dequeueReusableViewOfType<T: UICollectionReusableView>(_ type: T.Type, withSupplementaryViewOfKind kind: String, forIndexPath indexPath: IndexPath) -> T {
        self.dequeueReusableViewOfType(type, withIdentifier: String(describing: T.self), supplementaryViewOfKind: kind, forIndexPath: indexPath)
    }
}
