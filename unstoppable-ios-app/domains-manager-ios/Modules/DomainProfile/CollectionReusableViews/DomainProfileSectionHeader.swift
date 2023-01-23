//
//  DomainProfileSectionHeader.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.10.2022.
//

import UIKit

final class DomainProfileSectionHeader: UICollectionReusableView {
    
    static var reuseIdentifier = "DomainProfileSectionHeader"
    static let Height: CGFloat = 56

    private let titleLabel = UILabel()
    private let secondaryLabel = UILabel()
    private let loadingView = LoadingIndicatorView()
    private let actionButton = GhostTertiaryWhiteButton()
    private var actionButtonCallback: EmptyCallback?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setup()
    }
    
    func setWith(description: HeaderDescription) {
        titleLabel.setAttributedTextWith(text: description.title,
                                         font: .currentFont(withSize: 20, weight: .bold),
                                         textColor: .brandWhite)

        if let secondaryTitle = description.secondaryTitle {
            secondaryLabel.isHidden = description.isLoading
            loadingView.isHidden = !description.isLoading
            secondaryLabel.setAttributedTextWith(text: secondaryTitle,
                                                 font: .currentFont(withSize: 20, weight: .bold),
                                                 textColor: .brandWhite.withAlphaComponent(0.56))
        } else {
            secondaryLabel.isHidden = true
            loadingView.isHidden = true
        }
        
        if let button = description.button {
            actionButton.isHidden = false
            actionButton.setTitle(button.title, image: button.icon)
            actionButton.isEnabled = button.isEnabled
            self.actionButtonCallback = button.action
        } else {
            actionButton.isHidden = true
        }
    }
    
}

// MARK: - Setup methods
private extension DomainProfileSectionHeader {
    func setup() {
        setupItem()
    }
    
    func setupItem() {
        actionButton.imageLayout = .trailing
        actionButton.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        actionButton.customImageEdgePadding = 0
        
        loadingView.backgroundColor = .white.withAlphaComponent(0.08)
        loadingView.layer.cornerRadius = 8
        loadingView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        
        let spacer = UIView()
        spacer.backgroundColor = .clear
        
        let labelsStack = UIStackView(arrangedSubviews: [titleLabel, secondaryLabel, loadingView, spacer])
        labelsStack.axis = .horizontal
        labelsStack.spacing = 8
        labelsStack.alignment = .fill
        labelsStack.distribution = .fill
        
        let contentStack = UIStackView(arrangedSubviews: [labelsStack, actionButton])
        contentStack.axis = .horizontal
        contentStack.spacing = 8
        contentStack.alignment = .fill
        contentStack.distribution = .equalCentering
        contentStack.heightAnchor.constraint(equalToConstant: 24).isActive = true
        
        [titleLabel, secondaryLabel, loadingView, actionButton, labelsStack, contentStack].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        
        addSubview(contentStack)
        contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 0).isActive = true
        contentStack.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        contentStack.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    @objc func actionButtonPressed() {
        actionButtonCallback?()
    }
}

extension DomainProfileSectionHeader {
    struct HeaderDescription: Hashable {
        let title: String
        let secondaryTitle: String?
        let button: HeaderButton?
        let isLoading: Bool
        let id: UUID
    }
    
    struct HeaderButton: Hashable {
      
        let title: String
        let icon: UIImage
        let isEnabled: Bool
        let action: EmptyCallback
        
        static func add(isEnabled: Bool, callback: @escaping EmptyCallback) -> HeaderButton {
            HeaderButton(title: String.Constants.add.localized(), icon: .plusIconSmall, isEnabled: isEnabled, action: callback)
        }
        
        static func refresh(isEnabled: Bool, callback: @escaping EmptyCallback) -> HeaderButton {
            HeaderButton(title: String.Constants.refresh.localized(), icon: .refreshArrow20, isEnabled: isEnabled, action: callback)
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.title == rhs.title && lhs.icon == rhs.icon && lhs.isEnabled == rhs.isEnabled
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(title)
            hasher.combine(icon)
            hasher.combine(isEnabled)
        }
    }
}
