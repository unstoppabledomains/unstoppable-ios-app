//
//  UDSegmentedControlView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 29.02.2024.
//

import SwiftUI

struct UDSegmentedControlView<Selection: UDSegmentedControlItem>: View, ViewAnalyticsLogger {
    
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters

    @Binding var selection: Selection
    let items: [Selection]
    var customSegmentLabel: ((Selection) -> any View)? = nil
    
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                backgroundView()
                selectedBackgroundView(width: proxy.size.width / CGFloat(items.count))
                viewForItems(items)
            }
            .frame(height: 36)
            .animation(.easeInOut(duration: 0.25), value: selection)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Private methods
private extension UDSegmentedControlView {
    @ViewBuilder
    func backgroundView() -> some View {
        Color.white.opacity(0.1)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                Capsule()
                    .stroke(lineWidth: 1)
                    .foregroundColor(Color.borderSubtle)
            }
    }
    
    @ViewBuilder
    func selectedBackgroundView(width: CGFloat) -> some View {
        Color.white
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(width: width, height: 28)
            .offset(x: selectedIndexXOffset + selectedIndexOffset(width: width),
                    y: 0)
    }
    
    var selectedIndexXOffset: CGFloat {
        let selectedIndex = self.selectedIndex()
        if selectedIndex == 0 {
            return 4
        } else if selectedIndex == items.count - 1 {
            return -4
        }
        return 0
    }
    
    func selectedIndexOffset(width: CGFloat) -> CGFloat {
        CGFloat(selectedIndex()) * width
    }
    
    func selectedIndex() -> Int {
        items.firstIndex(of: selection) ?? 0
    }
    
    @ViewBuilder
    func viewForItems(_ items: [Selection]) -> some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                viewForSegmentWith(dataType: item)
            }
        }
    }
    
    @ViewBuilder
    func viewForSegmentWith(dataType: Selection) -> some View {
        Button {
            UDVibration.buttonTap.vibrate()
            logButtonPressedAnalyticEvents(button: dataType.analyticButton,
                                           parameters: [.value : dataType.rawValue])
            if self.selection != dataType {
                self.selection = dataType
            }
        } label: {
            if let customLabel = customSegmentLabel?(dataType) {
                AnyView(customLabel)
            } else {
                HStack {
                    if let icon = dataType.icon {
                        icon
                            .resizable()
                            .squareFrame(16)
                    }
                    Text(dataType.title)
                        .font(.currentFont(size: 14, weight: .semibold))
                }
                .foregroundStyle(dataType == self.selection ? Color.black : Color.foregroundDefault)
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
    }
}

protocol UDSegmentedControlItem: Hashable, RawRepresentable where RawValue == String {
    var title: String { get }
    var icon: Image? { get }
    var analyticButton: Analytics.Button { get }
}

extension UDSegmentedControlItem {
    var icon: Image? { nil }
}

#Preview {
    UDSegmentedControlView(selection: .constant(.chats), items: ChatsList.DataType.allCases)
}
