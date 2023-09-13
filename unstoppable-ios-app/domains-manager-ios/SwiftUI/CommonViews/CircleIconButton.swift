//
//  CircleIconButton.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 21.08.2023.
//

import SwiftUI

struct CircleIconButton: View {
    
    let icon: Icon
    let size: Size
    let callback: EmptyCallback
    
    var body: some View {
        Button {
            UDVibration.buttonTap.vibrate()
            callback() 
        } label: {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .opacity(0.16)
                    .frame(width: size.backgroundSize,
                           height: size.backgroundSize)
                currentIcon()
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.white)
                    .frame(width: size.iconSize,
                           height: size.iconSize)
            }
        }
    }
}

// MARK: - Open methods
extension CircleIconButton {
    enum Icon {
        case named(String)
        case system(String)
        case uiImage(UIImage)
    }
    
    enum Size {
        case small, medium
        
        var backgroundSize: CGFloat {
            switch self {
            case .small:
                return 32
            case .medium:
                return 40
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small:
                return 16
            case .medium:
                return 20
            }
        }
    }
}

// MARK: - Private methods
private extension CircleIconButton {
    func currentIcon() -> Image {
        switch icon {
        case .named(let name):
            return Image(name)
        case .system(let systemName):
            return Image(systemName: systemName)
        case .uiImage(let uiImage):
            return Image(uiImage: uiImage)
        }
    }
}

struct CircleIconButton_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black
            CircleIconButton(icon: .named("messageCircleIcon24"),
                             size: .small,
                             callback: { })
        }
    }
}
