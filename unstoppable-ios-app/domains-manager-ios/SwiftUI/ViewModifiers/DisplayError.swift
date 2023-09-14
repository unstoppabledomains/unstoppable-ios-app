//
//  DisplayError.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.09.2023.
//

import SwiftUI

struct DisplayError<T: Error>: ViewModifier {
    
    @Binding var error: T?
    var isShowingError: Binding<Bool> {
        Binding {
            error != nil
        } set: { _ in
            error = nil
        }
    }
    
    func body(content: Content) -> some View {
        content
            .alert(isPresented: isShowingError) {
                let (title, message) = error?.displayTitleAndMessage() ?? (String.Constants.error.localized(), String.Constants.somethingWentWrong.localized())
                
                return Alert(title: Text(title),
                             message: Text(message),
                             dismissButton: .default(Text(String.Constants.ok.localized())))
            }
    }
}

extension View {
    func displayError<T: Error>(_ error: Binding<T?>) -> some View {
        self.modifier(DisplayError(error: error))
    }
}
