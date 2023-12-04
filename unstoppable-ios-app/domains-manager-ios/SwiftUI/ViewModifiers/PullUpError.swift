//
//  PullUpError.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 04.12.2023.
//

import SwiftUI

struct PullUpError: ViewModifier {

    @Binding var error: PullUpErrorConfiguration?
    var isShowingError: Binding<Bool> {
        Binding {
            error != nil
        } set: { _ in
            error = nil
        }
    }
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: isShowingError, content: {
                if #available(iOS 16.0, *) {
                    errorContentView()
                        .presentationDetents([.height(error?.height ?? 370)])
                } else {
                    errorContentView()
                }
            })
    }
    
    @ViewBuilder
    private func errorContentView() -> some View {
        if let error {
            VStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 2)
                    .frame(width: 40, height: 4)
                    .foregroundStyle(Color.foregroundSubtle)
                Image.infoIcon
                    .resizable()
                    .squareFrame(40)
                    .foregroundStyle(Color.foregroundDanger)
                    .padding(EdgeInsets(top: 8, leading: 0, bottom: 0, trailing: 0))
                VStack(spacing: 8) {
                    Text(error.title)
                        .font(.currentFont(size: 22, weight: .bold))
                        .foregroundStyle(Color.foregroundDefault)
                    Text(error.subtitle)
                        .font(.currentFont(size: 16))
                        .foregroundStyle(Color.foregroundSecondary)
                }
                .multilineTextAlignment(.center)
                
                UDButtonView(text: error.primaryAction.title,
                             style: .large(.raisedPrimary),
                             callback: { closeAndPassCallback(error.primaryAction.callback) })
                .padding(EdgeInsets(top: 14, leading: 0, bottom: 0, trailing: 0))
                
                if let secondaryAction = error.secondaryAction {
                    UDButtonView(text: secondaryAction.title,
                                 style: .large(.ghostPrimary),
                                 callback: { closeAndPassCallback(secondaryAction.callback) })
                }
                Spacer()
            }
            .padding()
        }
    }
    
    private func closeAndPassCallback(_ callback: @escaping EmptyCallback) {
        error = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            callback()
        }
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
    var height: CGFloat = 370
    
    struct ActionConfiguration {
        let title: String
        let callback: EmptyCallback
    }
}
