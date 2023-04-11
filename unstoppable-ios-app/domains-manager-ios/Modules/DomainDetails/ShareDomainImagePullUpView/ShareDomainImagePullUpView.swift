//
//  ShareDomainImagePullUpView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 10.06.2022.
//

import UIKit

enum ShareDomainSelectionResult {
    case cancel
    case shareLink
    case saveAsImage
    case shareViaNFC
}

typealias ShareDomainSelectionCallback = (ShareDomainSelectionResult)->()

final class ShareDomainImagePullUpView: UIView, SelfNameable, NibInstantiateable {
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet private weak var domainSharingView: UDDomainSharingCardView!
    @IBOutlet private weak var shareLinkListItem: UIView!
    @IBOutlet private weak var shareNFCListItem: UIView!
    @IBOutlet private weak var saveAsImageListItem: UIView!
    private var saveAsImageCell: TableViewSelectionCell!
    
    var selectionCallback: ShareDomainSelectionCallback?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
  
}

// MARK: - Open methods
extension ShareDomainImagePullUpView {
    func setWithDomain(_ domainItem: DomainDisplayInfo, qrImage: UIImage) {
        domainSharingView.setWith(domain: domainItem, qrImage: qrImage)
    }
}

// MARK: - Private methods
private extension ShareDomainImagePullUpView {
    @objc func shareLinkItemPressed(_ sender: Any) {
        selectionCallback?(.shareLink)
    }
     
    @objc func saveAsImageItemPressed(_ sender: Any) {
        guard let vc = findViewController() else { return }
        
        appContext.permissionsService.askPermissionsFor(functionality: .photoLibrary(options: .addOnly),
                                                        in: vc,
                                                        shouldShowAlertIfNotGranted: true) { [weak self] granted in
            guard granted else { return }
            
            DispatchQueue.main.async {
                self?.selectionCallback?(.saveAsImage)
            }
        }
    }
    
    @objc func shareViaNFCPressed(_ sender: Any) {
        selectionCallback?(.shareViaNFC)
    }
}

// MARK: - Setup methods
private extension ShareDomainImagePullUpView {
    func setup() {
        commonViewInit()
        backgroundColor = .clear
        clipsToBounds = false
        
        let tv = UITableView()
        tv.registerCellNibOfType(TableViewSelectionCell.self)
        let shareLinkCell = tv.dequeueCellOfType(TableViewSelectionCell.self)
        add(cell: shareLinkCell, to: shareLinkListItem)
        shareLinkCell.setWith(icon: .chainIcon,
                              iconTintColor: .foregroundOnEmphasis,
                              iconStyle: .accent,
                              text: String.Constants.shareLink.localized(),
                              secondaryText: nil)
        shareLinkCell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(shareLinkItemPressed)))
        
        let saveAsImageCell = tv.dequeueCellOfType(TableViewSelectionCell.self)
        self.saveAsImageCell = saveAsImageCell
        add(cell: saveAsImageCell, to: saveAsImageListItem)
        saveAsImageCell.setWith(icon: .downloadIcon,
                                iconTintColor: .foregroundDefault,
                                iconStyle: .grey,
                                text: String.Constants.saveAsImage.localized(),
                                secondaryText: String.Constants.saveAsImageSubhead.localized())
        saveAsImageCell.setSecondaryTextStyle(.grey)

        saveAsImageCell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(saveAsImageItemPressed)))
        
        
        let shareNFCCell = tv.dequeueCellOfType(TableViewSelectionCell.self)
        add(cell: shareNFCCell, to: shareNFCListItem)
        shareNFCCell.setWith(icon: .nfcIcon20,
                             iconTintColor: .foregroundDefault,
                             iconStyle: .grey,
                             text: String.Constants.createNFCTag.localized(),
                             secondaryText: nil)
        
        shareNFCCell.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(shareViaNFCPressed)))
    }
    
    func add(cell: UIView, to superview: UIView) {
        cell.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        superview.addSubview(cell)
        cell.frame = superview.bounds
    }
}
