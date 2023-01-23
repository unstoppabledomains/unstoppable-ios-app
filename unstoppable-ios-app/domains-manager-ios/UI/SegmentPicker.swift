//
//  SegmentPicker.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.04.2022.
//

import UIKit

final class SegmentPicker: UIControl {
    
    private let height: CGFloat = 36
    private let contentInset: CGFloat = 4
    private let imageSegmentWidth: CGFloat = 44
    private let imageSegmentImageSize: CGFloat = 20
    private let selectedColor: UIColor = .black
    private let unselectedColor: UIColor = .foregroundDefault.withAlphaComponent(0.32)

    private var highlightView = UIView()
    private var segmentViews = [UIView]()
    private lazy var contentHeight: CGFloat = {
        height - (contentInset * 2)
    }()
    
    var selectedSegmentIndex: Int = 0 {
        didSet {
            if selectedSegmentIndex >= numberOfSegments {
                fatalError("Selected segment is out of range")
            }
            updateUIForSelectedSegment()
        }
    }
    
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
        
        
        self.bounds.size = CGSize(width: imageSegmentWidth * CGFloat(numberOfSegments) + (contentInset * 2),
                                  height: height)
        updateUIForSelectedSegment()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        layer.borderColor = UIColor.borderSubtle.cgColor
    }
    
}

// MARK: - Open methods
extension SegmentPicker {
    var numberOfSegments: Int { segmentViews.count }
    
    func insertSegment(with image: UIImage, at segment: Int, animated: Bool) {
        let imageContainer = createImageContainerView()
        let imageView = createImageView(image: image)
        imageContainer.addSubview(imageView)
        
        imageView.frame.origin = CGPoint(x: (imageSegmentWidth - imageSegmentImageSize) / 2,
                                         y: (imageContainer.bounds.height - imageSegmentImageSize) / 2)
        imageContainer.frame.origin = CGPoint(x: contentInset + (CGFloat(numberOfSegments) * imageSegmentWidth), y: contentInset)
        segmentViews.append(imageContainer)
        addSubview(imageContainer)
        updateUIForSelectedSegment()
    }
}

// MARK: - Private methods
private extension SegmentPicker {
    func createImageContainerView() -> SegmentPickerSegmentContainerView {
        let view = SegmentPickerSegmentContainerView(frame: CGRect(x: 0, y: 0, width: imageSegmentWidth, height: contentHeight))
        view.backgroundColor = .clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapSegment(_:)))
        view.addGestureRecognizer(tap)
        
        return view
    }
    
    func createImageView(image: UIImage) -> UIImageView {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageSegmentImageSize, height: imageSegmentImageSize))
        imageView.image = image
        imageView.tintColor = unselectedColor

        return imageView
    }
    
    func updateUIForSelectedSegment() {
        for (i, subview) in segmentViews.enumerated() {
            guard let containerView = subview as? SegmentPickerSegmentContainerView else { continue }
            
            let isSelected = selectedSegmentIndex == i
            let colour = isSelected ? selectedColor : unselectedColor
            containerView.setTintColor(colour)
            
            if isSelected {
                UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) { [weak self] in
                    self?.highlightView.frame = containerView.frame
                    self?.highlightView.applyFigmaShadow(style: .small)
                }
            }
        }
    }
    
    @objc func didTapSegment(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view,
              let index = segmentViews.firstIndex(of: view) else { return }
        
        if index != selectedSegmentIndex {
            self.selectedSegmentIndex = index
            updateUIForSelectedSegment()
            UDVibration.buttonTap.vibrate()
            sendActions(for: .valueChanged)
        }
    }
}

// MARK: - Setup methods
private extension SegmentPicker {
    func setup() {
        setupContainer()
        setupHighlightView()
    }
    
    func setupContainer() {
        backgroundColor = .backgroundSubtle
        frame.size.height = height
        layer.borderColor = UIColor.borderSubtle.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = height / 2
    }
    
    func setupHighlightView() {
        addSubview(highlightView)
        highlightView.frame.origin = CGPoint(x: contentInset, y: contentInset)
        highlightView.bounds.size = CGSize(width: imageSegmentWidth, height: height - (contentInset * 2))
        highlightView.layer.cornerRadius = highlightView.bounds.size.height / 2
        highlightView.backgroundColor = .white
    }
}

final class SegmentPickerSegmentContainerView: UIView {
    func setTintColor(_ tintColor: UIColor) {
        if let imageView = subviews.first as? UIImageView {
            imageView.tintColor = tintColor
        }
    }
}
