//
//  MessagingImageView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 02.08.2023.
//

import SwiftUI

struct MessagingImageView: View {
    
    @MainActor
    static func instantiate(mode: MessagingImageView.Mode,
                            image: UIImage) -> UIViewController {
        let vc = UIHostingController(rootView: MessagingImageView(mode: mode,
                                                                  image: image))
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve
        return vc
    }
    
    @Environment(\.presentationMode) private var presentationMode
    let mode: Mode
    let image: UIImage
    @State private var isImageSaved = false
    
    var body: some View {
        GeometryReader { proxy in
            NavigationView {
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    SwiftUIZoomableContainer {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            UDVibration.buttonTap.vibrate()
                            dismiss()
                        }) {
                            Text(String.Constants.cancel.localized())
                                .foregroundColor(.white)
                        }
                    }
                    
                    ToolbarItemGroup(placement: .bottomBar) {
                        Spacer()
                        switch mode {
                        case .confirmSending(let callback):
                            Button(action: {
                                UDVibration.buttonTap.vibrate()
                                dismiss()
                                callback()
                            }) {
                                ZStack {
                                    Circle()
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.blue)
                                    Image("arrowUp24")
                                        .foregroundColor(.white)
                                }
                            }
                        case .view(let saveCallback):
                            Button(action: {
                                UDVibration.buttonTap.vibrate()
                                imageSaved()
                                saveCallback()
                            }) {
                                Text(saveImageButtonTitle)
                                    .foregroundColor(.white)
                                    .opacity(isImageSaved ? 0.6 : 1)
                            }
                            .disabled(isImageSaved)
                        }
                    }
                }
            }
        }
    }
    
    private var saveImageButtonTitle: String {
        if isImageSaved {
            return String.Constants.saved.localized()
        }
        return String.Constants.save.localized()
    }
    
    private func imageSaved() {
        withAnimation {
            isImageSaved = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                isImageSaved = false
            }
        }
    }
    
    private func dismiss() {
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Open methods
extension MessagingImageView {
    enum Mode {
        case confirmSending(callback: ()->())
        case view(saveCallback: ()->())
    }
}

//struct MessagingImageView_Previews: PreviewProvider {
//    static var previews: some View {
//        MessagingImageView(mode: .view(saveCallback: { }), image: )
//    }
//}
