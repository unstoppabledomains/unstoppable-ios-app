//
//  StatusMessage.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2022.
//

import UIKit
import SwiftUI

final class StatusMessage: UIView {
    
    private var imageView: KeepingAnimationImageView!
    private var label: UILabel!
    private var component: Component?
    
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
extension StatusMessage {
    func setComponent(_ component: Component) {
        self.component = component
        setImage(component.icon, message: component.message, style: component.style)
        component.applyAdditionalBehaviour(on: imageView)
    }
    
    func setImage(_ image: UIImage, message: String, style: Style) {
        imageView.image = image
        imageView.tintColor = style.color
        label.setAttributedTextWith(text: message,
                                    font: .currentFont(withSize: 14, weight: .medium),
                                    textColor: style.color,
                                    lineHeight: 20)
    }
}

// MARK: - Setup methods
private extension StatusMessage {
    func setup() {
        backgroundColor = .clear
        createImageView()
        createLabel()
        createStack()
    }
    
    func createImageView() {
        imageView = KeepingAnimationImageView(frame: .zero)
        prepareView(imageView)
        imageView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor).isActive = true
    }
    
    func createLabel() {
        label = UILabel()
        prepareView(label)
    }
    
    func createStack() {
        let stack = UIStackView(arrangedSubviews: [imageView, label])
        prepareView(stack)
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.distribution = .fill
        stack.embedInSuperView(self)
    }
    
    func prepareView(_ view: UIView) {
        view.translatesAutoresizingMaskIntoConstraints = false
    }
}

extension StatusMessage {
    enum Style {
        case gray, success, warning
        case electricYellow, electricGreen, orange
        
        var color: UIColor {
            switch self {
            case .gray: return .foregroundSecondary
            case .success: return .foregroundSuccess
            case .warning: return .foregroundWarning
            case .electricYellow: return .brandElectricYellow
            case .electricGreen: return .brandElectricGreen
            case .orange: return .brandOrange
            }
        }
    }
    
    enum Component {
        case updatingRecords
        case bridgeDomainToPolygon
        case deprecated(tld: String)
        case electricMinting, electricUpdatingRecords, orangeDeprecated(tld: String)
        case transfer
        
        var icon: UIImage {
            switch self {
            case .updatingRecords, .electricUpdatingRecords, .electricMinting, .transfer:
                return .refreshIcon
            case .bridgeDomainToPolygon:
                return .warningIconLarge
            case .deprecated, .orangeDeprecated:
                return .warningIconLarge
            }
        }
        
        var message: String {
            switch self {
            case .updatingRecords, .electricUpdatingRecords:
                return String.Constants.updatingRecords.localized()
            case .bridgeDomainToPolygon:
                return String.Constants.bridgeDomainToPolygon.localized()
            case .deprecated(let tld), .orangeDeprecated(let tld):
                return String.Constants.tldHasBeenDeprecated.localized(tld)
            case .electricMinting:
                return String.Constants.mintingInProgressTitle.localized()
            case .transfer:
                return String.Constants.transferInProgress.localized()
            }
        }
        
        var style: Style {
            switch self {
            case .updatingRecords:
                return .gray
            case .bridgeDomainToPolygon, .deprecated:
                return .warning
            case .electricUpdatingRecords:
                return .electricYellow
            case .electricMinting, .transfer:
                return .electricGreen
            case .orangeDeprecated:
                return .orange
            }
        }
        
        func applyAdditionalBehaviour(on imageView: UIImageView) {
            switch self {
            case .updatingRecords, .electricUpdatingRecords, .electricMinting, .transfer:
                imageView.runUpdatingRecordsAnimation()
            case .bridgeDomainToPolygon, .deprecated, .orangeDeprecated:
                return
            }
        }
    }
}
