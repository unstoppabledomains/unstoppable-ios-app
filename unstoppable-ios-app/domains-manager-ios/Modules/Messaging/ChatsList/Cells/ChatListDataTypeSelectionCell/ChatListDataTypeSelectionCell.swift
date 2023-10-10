//
//  ChatListDataTypeSelectionCell.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 06.06.2023.
//

import UIKit

final class ChatListDataTypeSelectionCell: UICollectionViewCell {

    @IBOutlet private weak var segmentedControl: UDSegmentedControl!
    
    private var dataTypeChangedCallback: ((ChatsListDataType)->())?
    private var dataTypes: [ChatsListDataType] = []
    private var badgeViewDetails: [Int: BadgeViewDetails] = [:]

    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        DispatchQueue.main.async {
            self.setupBadges()
        }
    }
}

// MARK: - Open methods
extension ChatListDataTypeSelectionCell {
    func setWith(configuration: ChatsListViewController.DataTypeSelectionUIConfiguration) {
        dataTypeChangedCallback = configuration.dataTypeChangedCallback
        
        dataTypes.removeAll()
        segmentedControl.removeAllSegments()
        
        for (i, dataTypeConfiguration) in configuration.dataTypesConfigurations.enumerated() {
            let dataType = dataTypeConfiguration.dataType
            dataTypes.append(dataType)
            segmentedControl.insertSegment(withTitle: dataType.title,
                                           at: i,
                                           animated: false)
            setBadgeValue(dataTypeConfiguration.badge,
                          forSegment: i)
        }
        
        segmentedControl.selectedSegmentIndex = dataTypes.firstIndex(of: configuration.selectedDataType) ?? 0
    }
}

// MARK: - Private methods
private extension ChatListDataTypeSelectionCell {
    func setBadgeValue(_ badge: Int, forSegment segment: Int) {
        if badge > 0 {
            if let badgeViewDetails = badgeViewDetails[segment] {
                badgeViewDetails.badgeView.setUnreadMessagesCount(badge)
            } else {
                let badgeView = UnreadMessagesBadgeView()
                badgeView.setConstraints(size: 4)
                badgeView.setUnreadMessagesCount(badge)
                badgeView.setCounterLabel(hidden: true)
                addSubview(badgeView)
                badgeView.centerYAnchor.constraint(equalTo: segmentedControl.centerYAnchor, constant: -5).isActive = true
                let leadingConstraint = badgeView.leadingAnchor.constraint(equalTo: leadingAnchor)
                leadingConstraint.isActive = true
                
                let badgeDetails = BadgeViewDetails(badgeView: badgeView,
                                                    leadingConstraint: leadingConstraint)
                self.badgeViewDetails[segment] = badgeDetails
            }
        } else {
            badgeViewDetails[segment]?.badgeView.removeFromSuperview()
        }
    }
    
    func setupBadges() {
        if !self.badgeViewDetails.isEmpty {
            let segmentWidth = segmentedControl.bounds.width / CGFloat(segmentedControl.numberOfSegments)
            for segment in 0..<segmentedControl.numberOfSegments {
                guard let title = segmentedControl.titleForSegment(at: segment) else { continue }
                
                let titleWidth = title.width(withConstrainedHeight: bounds.height,
                                             font: UDSegmentedControl.segmentFont)
                let maxX = (segmentWidth / 2) + (titleWidth / 2) + (segmentWidth * CGFloat(segment)) + 8
                
                badgeViewDetails[segment]?.leadingConstraint.constant = maxX - 4
                badgeViewDetails[segment]?.badgeView.setStyle(segment == segmentedControl.selectedSegmentIndex ? .blue : .black)
            }
        }
    }
}

// MARK: - Private methods
private extension ChatListDataTypeSelectionCell {
    struct BadgeViewDetails {
        let badgeView: UnreadMessagesBadgeView
        let leadingConstraint: NSLayoutConstraint
    }
}

// MARK: - Actions
private extension ChatListDataTypeSelectionCell {
    @IBAction func segmentedControlValueChanged(_ sender: Any) {
        let selectedDataType = dataTypes[segmentedControl.selectedSegmentIndex]
        dataTypeChangedCallback?(selectedDataType)
    }
}
