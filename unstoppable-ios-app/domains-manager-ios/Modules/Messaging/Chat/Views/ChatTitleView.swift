//
//  ChatTitleView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 18.05.2023.
//

import UIKit

final class ChatTitleView: UIView {
    
    private let contentHeight: CGFloat = 20
    private let iconSize: CGFloat = 20
    
    private var iconImageView: UIImageView!
    private var titleLabel: UILabel!
    
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
        
        let titleWidth = calculateTitleLabelWidth()
        let titleX = iconImageView.frame.maxX + 8
        titleLabel.frame = CGRect(x: titleX,
                                  y: 0,
                                  width: titleWidth,
                                  height: contentHeight)
        
        frame.size = CGSize(width: titleLabel.frame.maxX, height: contentHeight)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        iconImageView.layer.borderColor = UIColor.borderSubtle.cgColor
    }
    
}

// MARK: - Open methods
extension ChatTitleView {
    func setTitleOfType(_ titleType: TitleType) {
        switch titleType {
        case .domain(let domain):
            setWithDomain(domain)
        }
        setNeedsLayout()
        layoutIfNeeded()
    }
}

// MARK: - Private methods
private extension ChatTitleView {
    func calculateTitleLabelWidth() -> CGFloat {
        guard let font = titleLabel.font else { return 0 }
        
        let title = titleLabel.attributedString.string
        return title.width(withConstrainedHeight: .greatestFiniteMagnitude, font: font)
    }
    
    func setWithDomain(_ domain: DomainDisplayInfo) {
        Task {
            iconImageView.image = await appContext.imageLoadingService.loadImage(from: .domainItemOrInitials(domain,
                                                                                                             size: .default),
                                                                                 downsampleDescription: nil)
        }
        titleLabel.setAttributedTextWith(text: domain.name,
                                         font: .currentFont(withSize: 16, weight: .semibold),
                                         textColor: .foregroundDefault)
    }
}

// MARK: - Setup methods
private extension ChatTitleView {
    func setup() {
        setupImageView()
        setupTitleLabel()
    }
    
    func setupImageView() {
        iconImageView = UIImageView(frame: .init(origin: .zero,
                                                 size: .square(size: iconSize)))
        iconImageView.layer.cornerRadius = iconSize / 2
        iconImageView.layer.borderWidth = 1
        iconImageView.layer.borderColor = UIColor.borderSubtle.cgColor
        iconImageView.clipsToBounds = true 
        addSubview(iconImageView)
    }
    
    func setupTitleLabel() {
        titleLabel = UILabel()
        
        addSubview(titleLabel)
    }
}

// MARK: - Open methods
extension ChatTitleView {
    enum TitleType {
        case domain(_ domain: DomainDisplayInfo)
    }
}
