//
//  UICollectionViewCellPreview.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 11.10.2022.
//

import UIKit
import SwiftUI

struct UICollectionViewCellPreview<Cell: UICollectionViewCell>: UIViewRepresentable {
    
    let viewBuilder: () -> UIView
    
    init(cellType: Cell.Type,
         width: CGFloat = 390,
         height: CGFloat,
         modificationBlock: @escaping (Cell)->() = { _ in }) {
        self.viewBuilder = {
            let collection = UICollectionView(frame: .zero, collectionViewLayout: .init())
            collection.registerCellNibOfType(cellType)
            
            let cell = collection.dequeueCellOfType(cellType, forIndexPath: IndexPath(row: 0, section: 0))
            cell.frame = CGRect(x: 0, y: 0, width: width, height: height)
            cell.alpha = 1
            modificationBlock(cell)
            
            return cell
        }
    }
    
    func makeUIView(context: Self.Context) -> some UIView {
        return viewBuilder()
    }
    
    func updateUIView(_ uiView: Self.UIViewType, context: Self.Context) { }
    
}
