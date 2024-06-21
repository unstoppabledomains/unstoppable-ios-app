//
//  OnboardingStartOptionsView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.04.2024.
//

import SwiftUI

protocol OnboardingStartOption: Hashable {
    var type: OnboardingStartOptionType { get }
    var analyticsName: Analytics.Button { get }
}

enum OnboardingStartOptionType {
    case listItem(OnboardingStartOptionListItemDetails)
    case generic(OnboardingStartOptionViewBuilder)
}

struct OnboardingStartOptionListItemDetails {
    let icon: UIImage
    let title: String
    let subtitle: String?
    let subtitleType: UDListItemView.SubtitleStyle
    let imageStyle: UDListItemView.ImageStyle
}

protocol OnboardingStartOptionViewBuilder {
    @ViewBuilder
    func buildView() -> any View
}

struct OnboardingStartOptionsView<O: OnboardingStartOption>: View {
    
    let title: String
    let subtitle: String
    let icon: Image
    let options: [[O]]
    let selectionCallback: (O)->()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                headerView()
                sectionsView()
                Spacer()
            }
            .padding()
        }
        .scrollDisabled(true)
    }
}

// MARK: - Private methods
private extension OnboardingStartOptionsView {
    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 20) {
            icon
                .resizable()
                .foregroundStyle(Color.foregroundMuted)
                .squareFrame(56)
            VStack(spacing: 16) {
                Text(title)
                    .titleText()
                Text(subtitle)
                    .subtitleText()
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
    }
    
    @ViewBuilder
    func sectionsView() -> some View {
        VStack(spacing: 16) {
            ForEach(options, id: \.self) { optionsSection in
                sectionWithOptions(optionsSection)
            }
        }
    }
    
    @ViewBuilder
    func sectionWithOptions(_ options: [O]) -> some View {
        UDCollectionSectionBackgroundView {
            VStack(alignment: .center, spacing: 0) {
                ForEach(options, id: \.self) { option in
                    listViewFor(option: option)
                }
            }
        }
    }
    
    @ViewBuilder
    func listViewFor(option: O) -> some View {
        UDCollectionListRowButton(content: {
            optionContent(option)
            .udListItemInCollectionButtonPadding()
        }, callback: {
            UDVibration.buttonTap.vibrate()
            selectionCallback(option)
        })
        .padding(EdgeInsets(4))
    }
    
    @ViewBuilder
    func optionContent(_ option: O) -> some View {
        switch option.type {
        case .listItem(let option):
            UDListItemView(title: option.title,
                           subtitle: option.subtitle,
                           subtitleStyle: option.subtitleType,
                           imageType: .uiImage(option.icon),
                           imageStyle: option.imageStyle,
                           rightViewStyle: nil)
        case .generic(let viewBuilder):
            AnyView(viewBuilder.buildView())
        }
    }
}

#Preview {
    OnboardingStartOptionsView(title: "",
                               subtitle: "",
                               icon: .addWalletIcon,
                               options: [[RestoreWalletType.iCloud(value: "")], [.mpc, .recoveryPhrase]],
                               selectionCallback: { _ in })
}
