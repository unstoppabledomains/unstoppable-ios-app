//
//  OnboardingStartOptionsView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.04.2024.
//

import SwiftUI

protocol OnboardingStartOption: Hashable {
    var icon: UIImage { get }
    var title: String { get }
    var subtitle: String? { get }
    var subtitleType: UDListItemView.SubtitleStyle { get }
    var imageStyle: UDListItemView.ImageStyle { get }
    var analyticsName: Analytics.Button { get }
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
            UDListItemView(title: option.title,
                           subtitle: option.subtitle,
                           subtitleStyle: option.subtitleType,
                           imageType: .uiImage(option.icon),
                           imageStyle: option.imageStyle,
                           rightViewStyle: nil)
            .udListItemInCollectionButtonPadding()
        }, callback: {
            UDVibration.buttonTap.vibrate()
            selectionCallback(option)
        })
        .padding(EdgeInsets(4))
    }
}

#Preview {
    OnboardingStartOptionsView(title: "",
                               subtitle: "",
                               icon: .addWalletIcon,
                               options: [[RestoreWalletType.iCloud(value: "")], [.mpc, .recoveryPhrase]],
                               selectionCallback: { _ in })
}
