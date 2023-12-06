//
//  PullUpError.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.12.2023.
//

import SwiftUI

struct PullUpError: ViewModifier {

    @Binding var error: PullUpErrorConfiguration?
    var configuration: Binding<ViewPullUpConfiguration?> {
        Binding {
            if let error {
                return createPullUpConfigurationFor(error: error)
            }
            return nil
        } set: { _ in
            error = nil
        }
    }
    
    func body(content: Content) -> some View {
        content.viewPullUp(configuration)
    }
    
    private func createPullUpConfigurationFor(error: PullUpErrorConfiguration) -> ViewPullUpConfiguration {
        ViewPullUpConfiguration(icon: .init(icon: .infoIcon, size: .small,
                                            tintColor: .foregroundDanger),
                                title: .text(error.title),
                                subtitle: .label(.text(error.subtitle)),
                                actionButton: .main(content: .init(title: error.primaryAction.title,
                                                                   icon: nil,
                                                                   analyticsName: error.primaryAction.analyticsName,
                                                                   action: error.primaryAction.callback)),
                                extraButton: error.secondaryAction == nil ? nil : .secondary(content: .init(title: error.secondaryAction!.title,
                                                                                                            icon: nil,
                                                                                                            analyticsName: error.secondaryAction!.analyticsName,
                                                                                                            action: error.secondaryAction?.callback)),
                                dismissAble: error.dismissAble, 
                                analyticName: error.analyticsName)
    }
}

extension View {
    func pullUpError(_ error: Binding<PullUpErrorConfiguration?>) -> some View {
        self.modifier(PullUpError(error: error))
    }
}

struct PullUpErrorConfiguration {
    let title: String
    let subtitle: String
    let primaryAction: ActionConfiguration
    var secondaryAction: ActionConfiguration? = nil
    var dismissAble: Bool = true
    let analyticsName: Analytics.PullUp
    
    struct ActionConfiguration {
        let title: String
        let callback: EmptyCallback
        let analyticsName: Analytics.Button
    }
}
