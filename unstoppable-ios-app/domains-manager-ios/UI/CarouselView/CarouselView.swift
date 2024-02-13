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
    var tintColor: UIColor { get }
    var backgroundColor: UIColor { get }
}

final class CarouselView: UIView {
    
    private var collectionView: UICollectionView!
    
    private let dataMultiplier = 100
    private let gradientViewWidth: CGFloat = 48
    private var sideGradientViews: [GradientView] = []

    var elementSideOffset: CGFloat = 12
    var style: CarouselCollectionViewCell.Style = .default
    var data: [CarouselViewItem] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard !sideGradientViews.isEmpty else { return }
        
        let height = bounds.height
        sideGradientViews[0].frame = CGRect(x: 0, // Left side
                                            y: 0,
                                            width: gradientViewWidth,
                                            height: height)
        sideGradientViews[1].frame = CGRect(x: bounds.width - gradientViewWidth, // Right side
                                            y: 0,
                                            width: gradientViewWidth,
                                            height: height)
    }
}

// MARK: - Open methods
extension CarouselView {
    func set(data: [CarouselViewItem]) {
        guard data.map({ $0.text }) != self.data.map({ $0.text }) else { return }
        
        self.data = data
        collectionView.reloadData()
        startAutoScroll()
    }
    
    func setSideGradient(hidden: Bool) {
        sideGradientViews.forEach { view in
            view.isHidden = hidden
        }
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
        cell.set(carouselItem: carouselItem, sideOffset: elementSideOffset, style: style)
        
        return cell
    }
}

//MARK: - UICollectionViewDelegateFlowLayout
extension CarouselView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemNum = indexPath.item % data.count
        let carouselItem = data[itemNum]
        let width = CarouselCollectionViewCell.widthFor(carouselItem: carouselItem, sideOffset: elementSideOffset, style: style)
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
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(collectionView)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.registerCellNibOfType(CarouselCollectionViewCell.self)
        collectionView.isUserInteractionEnabled = false
        collectionView.contentInset.left = 16
        collectionView.backgroundColor = .clear
    }
    
    func buildLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        
        layout.scrollDirection = .horizontal
        
        return layout
    }
    
    func addGradientViews() {
        let leftGradientView = GradientView(frame: .zero)
        leftGradientView.gradientDirection = .leftToRight
        leftGradientView.gradientColors = [.backgroundDefault, .backgroundDefault.withAlphaComponent(0.01)]
        addSubview(leftGradientView)

        let rightGradientView = GradientView(frame: .zero)
        rightGradientView.gradientDirection = .leftToRight
        rightGradientView.gradientColors = [.backgroundDefault.withAlphaComponent(0.01), .backgroundDefault]
        addSubview(rightGradientView)
        
        sideGradientViews = [leftGradientView, rightGradientView]
    }
    
    func startAutoScroll() {
        guard !data.isEmpty else { return }
        
        let dur: Double = 0.1
        let ptsPerSecond: Double = 15 // Adjust this value to control speed
        
        if collectionView.contentOffset.x + collectionView.bounds.width > collectionView.contentSize.width {
            collectionView.setContentOffset(.zero, animated: false)
        }
        
        UIView.animate(withDuration: dur, delay: 0, options: [.curveLinear]) { [weak self] in
            self?.collectionView.contentOffset.x += ptsPerSecond * dur
        } completion: { [weak self] _ in
            self?.startAutoScroll()
        }
    }
}

struct CarouselViewBridgeView: UIViewRepresentable {
    
    let data: [CarouselViewItem]
    let backgroundColor: UIColor
    var sideGradientHidden: Bool = true
    
    func makeUIView(context: Context) -> UIView {
        let view = CarouselView()
        view.set(data: data)
        view.backgroundColor = backgroundColor
        view.setSideGradient(hidden: sideGradientHidden)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
}
