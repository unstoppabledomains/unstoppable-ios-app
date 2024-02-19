//
//  ChatListDataTypeSelectorView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI

struct ChatListDataTypeSelectorView: View {
    
    @Binding var dataType: ChatListView.DataType
    
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                backgroundView()
                selectedBackgroundView(width: proxy.size.width / 3)
                viewForSegments(dataTypes: ChatListView.DataType.allCases)
            }
            .frame(height: 36)
            .frame(maxWidth: .infinity)
            .animation(.easeInOut(duration: 0.25), value: dataType)
        }
    }
}

// MARK: - Private methods
private extension ChatListDataTypeSelectorView {
    @ViewBuilder
    func backgroundView() -> some View {
        Color.backgroundSubtle
            .clipShape(Capsule())
    }
    
    @ViewBuilder
    func selectedBackgroundView(width: CGFloat) -> some View {
        Color.white
            .clipShape(Capsule())
            .frame(width: width, height: 28)
            .offset(x: selectedIndexXOffset + selectedIndexOffset(width: width),
                    y: 0)
    }
    
    var selectedIndexXOffset: CGFloat {
        let selectedIndex = self.selectedIndex()
        if selectedIndex == 0 {
            return 4
        } else if selectedIndex == ChatListView.DataType.allCases.count - 1 {
            return -4
        }
        return 0
    }
    
    func selectedIndexOffset(width: CGFloat) -> CGFloat {
        CGFloat(selectedIndex()) * width
    }
    
    func selectedIndex() -> Int {
        ChatListView.DataType.allCases.firstIndex(of: dataType) ?? 0
    }
    
    @ViewBuilder
    func viewForSegments(dataTypes: [ChatListView.DataType]) -> some View {
        HStack(spacing: 0) {
            ForEach(ChatListView.DataType.allCases, id: \.self) { dataType in
                viewForSegmentWith(dataType: dataType)
            }
        }
    }
    
    @ViewBuilder
    func viewForSegmentWith(dataType: ChatListView.DataType) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            if self.dataType != dataType {
                self.dataType = dataType
            }
        } label: {
            Text(dataType.title)
                .font(.currentFont(size: 14, weight: .semibold))
                .foregroundStyle(dataType == self.dataType ? Color.black : Color.foregroundDefault)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ChatListDataTypeSelectorView(dataType: .constant(.chats))
}
