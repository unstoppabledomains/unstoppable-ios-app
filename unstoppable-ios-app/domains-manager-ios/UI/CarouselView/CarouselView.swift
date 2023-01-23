//
//  CarouselView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.10.2022.
//

import UIKit
import SwiftUI

protocol CarouselViewItem {
    var icon: UIImage  { get }
    var text: String  { get }
}

final class CarouselView: UIView {
    
    private var collectionView: UICollectionView!
    
    private let dataMultiplier = 1000
    var data: [CarouselViewItem] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
}

// MARK: - Open methods
extension CarouselView {
    func set(data: [CarouselViewItem]) {
        self.data = data
        collectionView.reloadData()
        startAutoScroll()
    }
}

// MARK: - UICollectionViewDataSource
extension CarouselView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        data.count * dataMultiplier
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueCellOfType(CarouselCollectionViewCell.self, forIndexPath: indexPath)
        
        let itemNum = indexPath.item % data.count
        let carouselItem = data[itemNum]
        cell.set(carouselItem: carouselItem)
        
        return cell
    }
}

//MARK: - UICollectionViewDelegateFlowLayout
extension CarouselView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemNum = indexPath.item % data.count
        let carouselItem = data[itemNum]
        let width = CarouselCollectionViewCell.widthFor(carouselItem: carouselItem)
        return CGSize(width: width, height: 32)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        8
    }
}

// MARK: - Setup methods
private extension CarouselView {
    func setup() {
        backgroundColor = .clear
        setupCollectionView()
        addGradientViews()
        startAutoScroll()
    }
    
    func setupCollectionView() {
        collectionView = UICollectionView(frame: bounds, collectionViewLayout: buildLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.registerCellNibOfType(CarouselCollectionViewCell.self)
        collectionView.isUserInteractionEnabled = false
        collectionView.contentInset.left = 16
        collectionView.backgroundColor = .clear
        
        addSubview(collectionView)
        collectionView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        collectionView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        collectionView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    func buildLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        
        layout.scrollDirection = .horizontal
        
        return layout
    }
    
    func addGradientViews() {
        let gradientViewWidth: CGFloat = 48
        
        let leftGradientView = GradientView(frame: .zero)
        leftGradientView.translatesAutoresizingMaskIntoConstraints = false
        leftGradientView.gradientDirection = .leftToRight
        leftGradientView.gradientColors = [.backgroundDefault, .backgroundDefault.withAlphaComponent(0.01)]
        
        addSubview(leftGradientView)
        leftGradientView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        leftGradientView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        leftGradientView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        leftGradientView.widthAnchor.constraint(equalToConstant: gradientViewWidth).isActive = true

        let rightGradientView = GradientView(frame: .zero)
        rightGradientView.translatesAutoresizingMaskIntoConstraints = false
        rightGradientView.gradientDirection = .leftToRight
        rightGradientView.gradientColors = [.backgroundDefault.withAlphaComponent(0.01), .backgroundDefault]
        
        addSubview(rightGradientView)
        rightGradientView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        rightGradientView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        rightGradientView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        rightGradientView.widthAnchor.constraint(equalToConstant: gradientViewWidth).isActive = true
    }
    
    func startAutoScroll() {
        let dur: Double = 0.1
        let ptsPerSecond: Double = 15 // Adjust this value to control speed
        
        UIView.animate(withDuration: dur, delay: 0, options: [.curveLinear]) { [weak self] in
            self?.collectionView.contentOffset.x += ptsPerSecond * dur
        } completion: { [weak self] _ in
            self?.startAutoScroll()
        }
    }
}

struct CarouselView_Previews: PreviewProvider {
    
    static var previews: some View {
        UIViewPreview {
            let carouselView = CarouselView(frame: CGRect(x: 0, y: 0, width: 390, height: 32))
            
            return carouselView
        }
        .frame(width: 390, height: 32)
    }
    
}
