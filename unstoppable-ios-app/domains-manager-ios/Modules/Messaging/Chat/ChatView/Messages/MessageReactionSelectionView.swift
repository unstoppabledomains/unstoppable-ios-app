//
//  MessageReactionSelectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.02.2024.
//

import SwiftUI

struct MessageReactionSelectionView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let callback: (MessagingReactionType)->()
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(MessagingReactionType.allCases, id: \.self) { reactionType in
                    viewForReactionType(reactionType)
                }
            }
        }
    }
    
    @ViewBuilder
    func viewForReactionType(_ reactionType: MessagingReactionType) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            callback(reactionType)
            dismiss()
        } label: {
            Text(reactionType.rawValue)
                .padding()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MessageReactionSelectionView(callback: { _ in })
}
