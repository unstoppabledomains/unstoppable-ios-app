//
//  PreviewCollectionViewCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 22.12.2023.
//

import UIKit

final class PreviewCollectionViewCell<Cell: UICollectionViewCell>: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    let configureCellCallback: ((Cell)->())
    let cellSize: CGSize
    
    init(cellSize: CGSize,
         configureCellCallback: @escaping ((Cell)->())) {
        self.configureCellCallback = configureCellCallback
        self.cellSize = cellSize
        super.init(frame: CGRect(origin: .zero,
                                 size: cellSize))
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueCellOfType(Cell.self, forIndexPath: indexPath)
        configureCellCallback(cell)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        cellSize
    }
    
    private func setup() {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: bounds, collectionViewLayout: layout)
        collectionView.embedInSuperView(self)
        collectionView.registerCellNibOfType(Cell.self)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.reloadData()
    }
    
}
