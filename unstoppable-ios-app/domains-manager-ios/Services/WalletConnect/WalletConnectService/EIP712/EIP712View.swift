//
//  EIP712View.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 21.05.2024.
//

import Foundation
import UIKit

class EIP712View: UIView, NibInstantiateable {
    @IBOutlet var containerView: UIView!
    
    @IBOutlet weak var domainLabel: UILabel!
    @IBOutlet weak var chainLabel: UILabel!
    @IBOutlet weak var contractLabel: UILabel!
    @IBOutlet weak var messageTextView: UITextView!
    
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonViewInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonViewInit()
    }
}
