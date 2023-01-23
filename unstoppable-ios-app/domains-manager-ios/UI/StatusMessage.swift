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
        
        var color: UIColor {
            switch self {
            case .gray: return .foregroundSecondary
            case .success: return .foregroundSuccess
            case .warning: return .foregroundWarning
            }
        }
    }
    
    enum Component {
        case updatingRecords
        case bridgeDomainToPolygon
        case tapOnCardToSeeDetails
        case deprecated(tld: String)
        
        var icon: UIImage {
            switch self {
            case .updatingRecords:
                return .refreshIcon
            case .bridgeDomainToPolygon:
                return .warningIconLarge
            case .tapOnCardToSeeDetails:
                return .tapIcon
            case .deprecated:
                return .warningIconLarge
            }
        }
        
        var message: String {
            switch self {
            case .updatingRecords:
                return String.Constants.updatingRecords.localized()
            case .bridgeDomainToPolygon:
                return String.Constants.bridgeDomainToPolygon.localized()
            case .tapOnCardToSeeDetails:
                return String.Constants.tapDomainCardHint.localized()
            case .deprecated(let tld):
                return String.Constants.tldHasBeenDeprecated.localized(tld)
            }
        }
        
        var style: Style {
            switch self {
            case .updatingRecords, .tapOnCardToSeeDetails:
                return .gray
            case .bridgeDomainToPolygon, .deprecated:
                return .warning
            }
        }
        
        func applyAdditionalBehaviour(on imageView: UIImageView) {
            switch self {
            case .updatingRecords:
                imageView.runUpdatingRecordsAnimation()
            case .bridgeDomainToPolygon, .tapOnCardToSeeDetails, .deprecated:
                return
            }
        }
    }
}
