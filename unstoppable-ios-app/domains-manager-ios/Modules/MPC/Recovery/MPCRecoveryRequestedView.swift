//
//  MPCRecoveryRequestedView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 8.10.2024.
//

import SwiftUI

struct MPCRecoveryRequestedView: View, ViewAnalyticsLogger {
    
    @Environment(\.dismiss) var dismiss

    let email: String
    var closeCallback: EmptyCallback? = nil
    
    var analyticsName: Analytics.ViewName { .mpcRecoveryRequested }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                headerView()
                VStack(spacing: 16) {
                    infoSection()
                    hintsSection()
                }
                Spacer()
                VStack(spacing: 16) {
                    openMailButtonView()
                    doneButtonView()
                }
            }
            .padding(.horizontal, 16)
        }
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                CloseButtonView(closeCallback: closeButtonPressed)
            }
        }
    }
}

// MARK: - Private methods
private extension MPCRecoveryRequestedView {
    var subtitleAttributesList: [AttributedText.AttributesList] {
        let subtitleHighlights = String.Constants.mpcRecoveryRequestedSubtitleHighlights.localized()
        let stringsToUpdate = subtitleHighlights.components(separatedBy: "\n")
        let attributesList: [AttributedText.AttributesList] = stringsToUpdate.map {
            .init(text: $0,
                  font: .currentFont(withSize: 16,
                                     weight: .medium),
                  textColor: .foregroundDefault)
        }
        
        return attributesList
    }

    @ViewBuilder
    func headerView() -> some View {
        VStack(spacing: 20) {
            Image.checkCircle
                .resizable()
                .squareFrame(56)
                .foregroundStyle(Color.foregroundSuccess)
            VStack(spacing: 16) {
                Text(String.Constants.mpcRecoveryRequestedTitle.localized())
                    .titleText()
                
                AttributedText(attributesList: .init(text: String.Constants.mpcRecoveryRequestedSubtitle.localized(),
                                                     font: .currentFont(withSize: 16),
                                                     textColor: .foregroundSecondary,
                                                     alignment: .center),
                               updatedAttributesList: subtitleAttributesList)

            }
        }
    }
    
    @ViewBuilder
    func infoSection() -> some View {
        sectionWith(items: [.init(title: String.Constants.sentToN.localized(email),
                                  titleLineLimit: 1,
                                  icon: .invite)])
    }
    
    @ViewBuilder
    func hintsSection() -> some View {
        sectionWith(items: [.init(title: String.Constants.mpcRecoveryRequestedHintNotShare.localized(),
                                  icon: .crossWhite),
                            .init(title: String.Constants.mpcRecoveryRequestedHintPreviousInactive.localized(),
                                  icon: .brokenHeart)])
    }
    
    @ViewBuilder
    func sectionWith(items: [SectionItem]) -> some View {
        UDCollectionSectionBackgroundView {
            VStack(alignment: .center, spacing: 0) {
                ForEach(items) { item in
                    listItemWith(sectionItem: item)
                }
            }
            .padding(4)
        }
    }
    
    @ViewBuilder
    func listItemWith(sectionItem: SectionItem) -> some View {
        UDListItemView(title: sectionItem.title,
                       titleLineLimit: sectionItem.titleLineLimit,
                       imageType: .image(sectionItem.icon),
                       imageStyle: .centred())
        .padding(.vertical, 4)
        .udListItemInCollectionButtonPadding()
    }
    
    @ViewBuilder
    func openMailButtonView() -> some View {
        UDButtonView(text: String.Constants.openEmailApp.localized(),
                     style: .large(.ghostPrimary),
                     callback: openMailButtonPressed)
    }
    
    @ViewBuilder
    func doneButtonView() -> some View {
        UDButtonView(text: String.Constants.doneButtonTitle.localized(),
                     style: .large(.raisedPrimary),
                     callback: doneButtonPressed)
    }
}

// MARK: - Private methods
private extension MPCRecoveryRequestedView {
    func closeButtonPressed() {
        logButtonPressedAnalyticEvents(button: .close)
        close()
    }
    
    @MainActor func openMailButtonPressed() {
        logButtonPressedAnalyticEvents(button: .openEmailApp)
        openMailApp()
    }
    
    func doneButtonPressed() {
        logButtonPressedAnalyticEvents(button: .done)
        close()
    }
    
    func close() {
        closeCallback?() ?? dismiss()
    }
}

// MARK: - Private methods
private extension MPCRecoveryRequestedView {
    struct SectionItem: Identifiable {
        let id = UUID()
        let title: String
        var titleLineLimit: Int? = nil
        let icon: Image
    }
}

#Preview {
    NavigationStack {
        MPCRecoveryRequestedView(email: "qwerty@example.com")
    }
}
