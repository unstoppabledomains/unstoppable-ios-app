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
                                    lineHeight: 20,
                                    lineBreakMode: .byTruncatingTail)
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
        case gray, success, warning, danger
        case electricYellow, electricGreen, orange
        
        var color: UIColor {
            switch self {
            case .gray: return .foregroundSecondary
            case .success: return .foregroundSuccess
            case .warning: return .foregroundWarning
            case .danger: return .foregroundDanger
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
        case parked(status: DomainParkingStatus)
        case electricMinting, electricUpdatingRecords, orangeDeprecated(tld: String)
        
        var icon: UIImage {
            switch self {
            case .updatingRecords, .electricUpdatingRecords, .electricMinting:
                return .refreshIcon
            case .bridgeDomainToPolygon:
                return .warningIconLarge
            case .deprecated, .orangeDeprecated:
                return .warningIconLarge
            case .parked:
                return .parkingIcon24
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
            case .parked(let status):
                return status.title ?? String.Constants.parkedDomain.localized()
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
            case .electricMinting:
                return .electricGreen
            case .orangeDeprecated:
                return .orange
            case .parked(let status):
                switch status {
                case .freeParking, .parked, .claimed:
                    return .gray
                case .parkingExpired:
                    return .danger
                case .parkingTrial, .parkedButExpiresSoon:
                    return .warning
                }
            }
        }
        
        func applyAdditionalBehaviour(on imageView: UIImageView) {
            switch self {
            case .updatingRecords, .electricUpdatingRecords, .electricMinting:
                imageView.runUpdatingRecordsAnimation()
            case .bridgeDomainToPolygon, .deprecated, .orangeDeprecated, .parked:
                return
            }
        }
    }
}
