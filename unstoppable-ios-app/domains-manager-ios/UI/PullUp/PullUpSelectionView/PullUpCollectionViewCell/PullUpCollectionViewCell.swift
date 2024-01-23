//
//  PullUpCollectionViewCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.05.2022.
//

import UIKit

enum PullUpDisclosureIndicatorStyle {
    case none
    case right
    case topRight
    case copyToClipboard
    case actionButton(title: String, callback: EmptyCallback)
    
    var icon: UIImage? {
        switch self {
        case .none, .actionButton:
            return nil
        case .right:
            return UIImage(named: "chevronRight")
        case .topRight:
            return UIImage(named: "chevronTopRight")
        case .copyToClipboard:
            return .copyToClipboardIcon
        }
    }
    
}

protocol PullUpCollectionViewCellItem: Sendable {
    var imageSize: ResizableRoundedImageView.Size { get }
    var imageStyle: ResizableRoundedImageView.Style { get}
    var title: String { get }
    var titleColor: UIColor { get }
    var subtitle: String? { get }
    var subtitleColor: UIColor { get }
    var subtitleIcon: UIImage? { get }
    var icon: UIImage { get async }
    var tintColor: UIColor { get }
    var backgroundColor: UIColor { get }
    var height: CGFloat { get }
    var disclosureIndicatorStyle: PullUpDisclosureIndicatorStyle { get }
    var isSelectable: Bool { get }
    var analyticsName: String { get }
}

extension PullUpCollectionViewCellItem {
    var imageSize: ResizableRoundedImageView.Size { .init(containerSize: 40, imageSize: 20) }
    var imageStyle: ResizableRoundedImageView.Style { .imageCentered }
    var titleColor: UIColor { .foregroundDefault }
    var tintColor: UIColor { .foregroundDefault }
    var subtitle: String? { nil }
    var subtitleColor: UIColor { .foregroundSecondary }
    var subtitleIcon: UIImage? { nil }
    var backgroundColor: UIColor { .backgroundMuted2 }
    var height: CGFloat { 70 }
    var disclosureIndicatorStyle: PullUpDisclosureIndicatorStyle { .none }
    var isSelectable: Bool { true }
}

final class PullUpCollectionViewCell: BaseListCollectionViewCell {
    
    static let Height: CGFloat = 70
    
    @IBOutlet private weak var iconContainerView: ResizableRoundedImageView!
    @IBOutlet private weak var chevronImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var subtitleImageView: UIImageView!
    @IBOutlet private weak var chevronContainerView: UIView!
    @IBOutlet private weak var containerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var actionButton: UDConfigurableButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        actionButton.setConfiguration(.mediumRaisedPrimaryButtonConfiguration)
        actionButton.customCornerRadius = 16
    }
    
}

// MARK: - Open methods
extension PullUpCollectionViewCell {
    func setWith(pullUpItem: PullUpCollectionViewCellItem) {
        accessibilityIdentifier = "Pull Up Collection View Cell \(pullUpItem.title)"
        titleLabel.setAttributedTextWith(text: pullUpItem.title,
                                         font: .currentFont(withSize: 16, weight: .medium),
                                         textColor: pullUpItem.titleColor,
                                         lineHeight: 24,
                                         lineBreakMode: .byTruncatingTail)
        containerHeightConstraint.constant = pullUpItem.height
        
        
        switch pullUpItem.disclosureIndicatorStyle {
        case .none:
            chevronContainerView.isHidden = true
            actionButton.isHidden = true
        case .actionButton(let title, let callback):
            chevronContainerView.isHidden = true
            actionButton.isHidden = false
            actionButton.setTitle(title, image: nil)
            actionButton.addAction(.init(handler: { _ in
                callback()
            }), for: .touchUpInside)
        default:
            chevronContainerView.isHidden = false
            actionButton.isHidden = true
            chevronImageView.image = pullUpItem.disclosureIndicatorStyle.icon
        }
        
        Task {
            iconContainerView.image = await pullUpItem.icon
        }
        iconContainerView.tintColor = pullUpItem.tintColor
        iconContainerView.backgroundColor = pullUpItem.backgroundColor
        iconContainerView.layer.borderWidth = pullUpItem.imageStyle == .imageCentered ? 1 : 0
        
        subtitleImageView.isHidden = pullUpItem.subtitleIcon == nil
        subtitleImageView.image = pullUpItem.subtitleIcon
        subtitleImageView.tintColor = pullUpItem.subtitleColor
        
        iconContainerView.setSize(pullUpItem.imageSize)
        iconContainerView.setStyle(pullUpItem.imageStyle)
        
        subtitleLabel.isHidden = pullUpItem.subtitle == nil
        subtitleLabel?.setAttributedTextWith(text: pullUpItem.subtitle ?? "",
                                             font: .currentFont(withSize: 14, weight: .regular),
                                             textColor: pullUpItem.subtitleColor,
                                             lineHeight: 20)
        
        self.isSelectable = pullUpItem.isSelectable
    }
}

// MARK: - Private methods
private extension PullUpCollectionViewCell {
    
}

@available(iOS 17, *)
#Preview {
    let collectionView = PreviewCollectionViewCell<PullUpCollectionViewCell>(cellSize: CGSize(width: 390, height: 68),
                                                                                    configureCellCallback: { cell in
        cell.setWith(pullUpItem: MessagingChatUserPullUpSelectionItem.init(userInfo: .init(wallet: "adasd"), isAdmin: false, isPending: false,
                                                                           unblockCallback:  { }))
    })
    
    return collectionView
}
