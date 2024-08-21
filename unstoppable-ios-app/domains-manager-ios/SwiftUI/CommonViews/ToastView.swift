//
//  ToastView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 09.08.2024.
//

import SwiftUI

struct ToastView: View {
    
    let toast: Toast
    var action: ActionDescription? = nil
    
    private var style: Toast.Style { toast.style }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(uiImage: toast.image)
                .resizable()
                .squareFrame(20)
                .foregroundStyle(Color(style.tintColor))
            Text(toast.message)
                .textAttributes(color: Color(style.tintColor),
                                fontSize: 14,
                                fontWeight: .medium)
            
            if let action {
                LineView(direction: .vertical,
                         size: 1)
                .frame(height: 20)
                .scaleEffect(y: 2)
                .padding(.horizontal, 4)
                .foregroundStyle(Color.borderDefault)
                
                Button {
                    UDVibration.buttonTap.vibrate()
                    action.callback()
                } label: {
                    Text(action.title)
                        .textAttributes(color: .white.opacity(0.56),
                                        fontSize: 14,
                                        fontWeight: .medium)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
            }
        }
        .padding(8)
        .background(Color(style.color))
        .clipShape(.capsule)
    }
}

// MARK: - Open methods
extension ToastView {
    struct ActionDescription {
        let title: String
        let callback: EmptyCallback
    }
}

#Preview {
    ToastView(toast: .changesConfirmed,
              action: .init(title: "Undo", callback: { }))
}
