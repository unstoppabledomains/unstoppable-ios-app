//
//  SegmentPicker.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 28.04.2022.
//

import UIKit

final class SegmentPicker: UIControl {
    
    private var height: CGFloat { SegmentPickerSegmentContainerView.height + contentInset * 2 }
    private let contentInset: CGFloat = 4
    private let imageSegmentWidth: CGFloat = 44
    private let selectedColor: UIColor = .black
    private let unselectedColor: UIColor = .foregroundDefault.withAlphaComponent(0.32)

    private var highlightView = UIView()
    private var segmentViews = [SegmentPickerSegmentContainerView]()
    private lazy var contentHeight: CGFloat = {
        height - (contentInset * 2)
    }()
    var layoutType: LayoutType = .autoSize { didSet { setNeedsLayout(); layoutIfNeeded() } }
    
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
        
        switch layoutType {
        case .autoSize:
            self.bounds.size = CGSize(width: imageSegmentWidth * CGFloat(numberOfSegments) + (contentInset * 2),
                                      height: height)
        case .fillParent:
            self.bounds.size = CGSize(width: superview?.bounds.width ?? 0,
                                      height: height)
            let segmentWidth = bounds.width / CGFloat(numberOfSegments)
            
            for (i, segmentContainer) in segmentViews.enumerated() {
                segmentContainer.bounds.size.width = segmentWidth
                segmentContainer.frame.origin = CGPoint(x: contentInset + (CGFloat(i) * segmentWidth),
                                                        y: contentInset)
            }
        }
        
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
    
    func insertSegment(with image: UIImage, title: String, at segment: Int, animated: Bool) {
        let segmentContainer = createSegmentContainerView()
        segmentContainer.setTintColor(unselectedColor)
        segmentContainer.set(title: title, icon: image)
       
        segmentViews.append(segmentContainer)
        addSubview(segmentContainer)
        setNeedsLayout()
        layoutIfNeeded()
    }
}

// MARK: - Private methods
private extension SegmentPicker {
    func createSegmentContainerView() -> SegmentPickerSegmentContainerView {
        let view = SegmentPickerSegmentContainerView(frame: CGRect(x: 0, y: 0, width: imageSegmentWidth, height: contentHeight))
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapSegment(_:)))
        view.addGestureRecognizer(tap)
        
        return view
    }
    
    func updateUIForSelectedSegment() {
        for (i, containerView) in segmentViews.enumerated() {
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
        guard let view = gesture.view as? SegmentPickerSegmentContainerView,
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

// MARK: - Open methods
extension SegmentPicker {
    enum LayoutType {
        case autoSize
        case fillParent
    }
}

private final class SegmentPickerSegmentContainerView: UIView {
    
    static let height: CGFloat = 28

    private var titleLabel: UILabel!
    private var imageView: UIImageView!
    private let font = UIFont.currentFont(withSize: 14, weight: .semibold)
    private let imageSegmentImageSize: CGFloat = 16
    private let titleToImageSpace: CGFloat = 8

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
        
        let contentWidth = requiredWidth()
        let freeSpace = bounds.width - contentWidth
        imageView.frame.origin = CGPoint(x: freeSpace / 2,
                                         y: (Self.height - imageSegmentImageSize) / 2)
        titleLabel.bounds.size.width = requiredTitleWidth()
        titleLabel.frame.origin.x = imageView.frame.maxX + titleToImageSpace
    }
    
    func setTintColor(_ tintColor: UIColor) {
        self.tintColor = tintColor
        imageView.tintColor = tintColor
        titleLabel.updateAttributesOf(text: titleLabel.attributedString?.string ?? "", textColor: tintColor)
    }
    
    func set(title: String, icon: UIImage) {
        titleLabel.setAttributedTextWith(text: title,
                                         font: font,
                                         textColor: tintColor)
        imageView.image = icon
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func requiredWidth() -> CGFloat {
        imageSegmentImageSize + titleToImageSpace + requiredTitleWidth()
    }
    
    private func requiredTitleWidth() -> CGFloat {
        (titleLabel.attributedString?.string ?? "").width(withConstrainedHeight: Self.height, font: font)
    }
}

// MARK: - Setup methods
private extension SegmentPickerSegmentContainerView {
    func setup() {
        createImageView()
        createTitleLabel()
        backgroundColor = .clear
    }
    
    func createImageView() {
        imageView = UIImageView(frame: CGRect(origin: .zero,
                                              size: .square(size: imageSegmentImageSize)))
        
        addSubview(imageView)
    }
    
    func createTitleLabel() {
        titleLabel = UILabel(frame: CGRect(origin: .zero,
                                           size: .square(size: Self.height)))
        addSubview(titleLabel)
    }
}
