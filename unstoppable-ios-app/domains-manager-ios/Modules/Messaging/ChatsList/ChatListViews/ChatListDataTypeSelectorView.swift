//
//  ChatListDataTypeSelectorView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.02.2024.
//

import SwiftUI

struct ChatListDataTypeSelectorView: View {
    
    @EnvironmentObject var viewModel: ChatListViewModel
    
    private let indicatorSize: CGFloat = 4
    
    var body: some View {
        UDSegmentedControlView(selection: $viewModel.selectedDataType,
                               items: ChatsList.DataType.allCases) { dataType in
            ZStack(alignment: .topTrailing) {
                Text(dataType.title ?? "")
                    .font(.currentFont(size: 14, weight: .semibold))
                    .foregroundStyle(dataType == viewModel.selectedDataType ? Color.black : Color.foregroundDefault)
                
                if viewModel.numberOfUnreadMessagesFor(dataType: dataType) > 0 {
                    Circle()
                        .squareFrame(indicatorSize)
                        .foregroundStyle(Color.foregroundAccent)
                        .offset(x: indicatorSize + 4)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    ChatListDataTypeSelectorView()
}
