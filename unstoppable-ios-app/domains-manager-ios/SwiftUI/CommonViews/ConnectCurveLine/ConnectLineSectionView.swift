//
//  ConnectLineSectionView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.07.2024.
//

import SwiftUI

struct ConnectLineSectionView: View, ViewAnalyticsLogger {
    
    @Environment(\.analyticsViewName) var analyticsName
    @Environment(\.analyticsAdditionalProperties) var additionalAppearAnalyticParameters
    let section: SectionType
    
    var body: some View {
        switch section {
        case .infoValue(let info):
            actionableViewForInfoValueSection(info)
        case .info(let info):
            viewForInfoSection(info)
        }
    }
}

// MARK: - Private methods
private extension ConnectLineSectionView {
    @ViewBuilder
    func actionableViewForInfoValueSection(_ info: InfoWithValueDescription) -> some View {
        if info.actions.isEmpty {
            viewForInfoValueSection(info)
        } else {
            Menu {
                ForEach(info.actions, id: \.self) { action in
                    Button {
                        UDVibration.buttonTap.vibrate()
                        logButtonPressedAnalyticEvents(button: action.analyticName,
                                                       parameters: action.analyticParameters)
                        action.action()
                    } label: {
                        Label(
                            title: { Text(action.title) },
                            icon: { Image(systemName: action.iconName) }
                        )
                        Text(action.subtitle)
                    }
                }
            } label: {
                viewForInfoValueSection(info)
            }
            .onButtonTap {
                if let analyticName = info.analyticName {
                    logButtonPressedAnalyticEvents(button: analyticName)
                }
            }
        }
    }
    
    @ViewBuilder
    func viewForInfoValueSection(_ info: InfoWithValueDescription) -> some View {
        GeometryReader { geom in
            HStack(spacing: 16) {
                HStack {
                    Text(info.title)
                        .font(.currentFont(size: 16))
                        .foregroundStyle(Color.foregroundSecondary)
                    Spacer()
                }
                .frame(width: geom.size.width * 0.38)
                HStack(spacing: 8) {
                    UIImageBridgeView(image: info.icon,
                                      tintColor: info.iconColor)
                    .squareFrame(24)
                    .clipShape(Circle())
                    VStack(alignment: .leading,
                           spacing: -4) {
                        HStack(spacing: 8) {
                            Text(info.value)
                                .font(.currentFont(size: 16, weight: .medium))
                                .frame(height: 24)
                                .foregroundStyle(info.valueColor)
                            if let subValue = info.subValue {
                                Text(subValue)
                                    .font(.currentFont(size: 16, weight: .medium))
                                    .foregroundStyle(Color.foregroundSecondary)
                            }
                        }
                        if let errorMessage = info.errorMessage {
                            Text(errorMessage)
                                .font(.currentFont(size: 15, weight: .medium))
                                .foregroundStyle(Color.foregroundDanger)
                                .frame(height: 24)
                        }
                    }
                }
                Spacer()
            }
            .lineLimit(1)
            .frame(height: geom.size.height)
        }
    }
    
    @ViewBuilder
    func viewForInfoSection(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.currentFont(size: 13))
                .foregroundStyle(Color.foregroundMuted)
            Spacer()
        }
    }
}

// MARK: - Open methods
extension ConnectLineSectionView {
    enum SectionType: Hashable {
        case infoValue(InfoWithValueDescription)
        case info(String)
    }
    
    struct InfoWithValueDescription: Hashable {
        let title: String
        let icon: UIImage
        var iconColor: UIColor = .foregroundDefault
        let value: String
        var valueColor: Color = .foregroundDefault
        var subValue: String? = nil
        var errorMessage: String? = nil
        var actions: [InfoActionDescription] = []
        var analyticName: Analytics.Button? = nil
    }
    
    struct InfoActionDescription: Hashable {
        
        let title: String
        let subtitle: String
        let iconName: String
        let tintColor: UIColor
        var analyticName: Analytics.Button
        var analyticParameters: Analytics.EventParameters
        let action: EmptyCallback
        
        static func == (lhs: ConnectLineSectionView.InfoActionDescription,
                        rhs: ConnectLineSectionView.InfoActionDescription) -> Bool {
            lhs.title == rhs.title &&
            lhs.subtitle == rhs.subtitle &&
            lhs.iconName == rhs.iconName
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(title)
            hasher.combine(subtitle)
            hasher.combine(iconName)
        }
        
    }
}

#Preview {
    ConnectLineSectionView(section: .info("Hello"))
}
