//
//  HotFeatureSuggestionDetailsView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.12.2023.
//

import SwiftUI

struct HotFeatureSuggestionDetailsView: View, ViewAnalyticsLogger {
    
    let suggestion: HotFeatureSuggestion
    @State private var illustration: UIImage?
    var analyticsName: Analytics.ViewName { .hotFeatureDetails }
    // TODO: - Add additional analytic parameter for feature id 
    
    var body: some View {
        ScrollView {
            headerView()
            contentView()
                .sideInsets(16)
            UDButtonView(text: String.Constants.gotIt.localized(),
                         style: .large(.raisedTertiary)) {
                logButtonPressedAnalyticEvents(button: .gotIt)
                closeSuggestion()
            }
            .padding()
        }
    }
}

// MARK: - Private methods
private extension HotFeatureSuggestionDetailsView {
    func closeSuggestion() {
        appContext.hotFeatureSuggestionsService.didViewHotFeatureSuggestion(suggestion)
    }
}

// MARK: - Private methods
private extension HotFeatureSuggestionDetailsView {
    @ViewBuilder
    func headerView() -> some View {
        NavigationContentView {
            HStack {
                CloseButtonView {
                    logButtonPressedAnalyticEvents(button: .close)
                    closeSuggestion()
                }
                Spacer()
            }
        }
    }
    
    @ViewBuilder
    func contentView() -> some View {
        switch suggestion.details {
        case .steps(let stepDetailsContent):
            stepDetailsView(stepDetailsContent)
        }
    }
    
    @ViewBuilder
    func stepDetailsView(_ details: HotFeatureSuggestion.DetailsItem.StepDetailsContent) -> some View {
        HStack {
            VStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(details.title)
                        .titleText()
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(details.steps, id: \.self) { step in
                            Text("\u{2022} " + step)
                                .subtitleText()
                        }
                    }
                }
                
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .foregroundStyle(Color.backgroundSubtle)
                    if let illustration {
                        Image(uiImage: illustration)
                            .resizable()
                            .padding(EdgeInsets(top: 32, leading: 39, bottom: 0, trailing: 39))
                            .aspectRatio(contentMode: .fill)
                    } else {
                        ProgressView()
                    }
                }
            }
            Spacer()
        }
        .onAppear {
            loadIllustration(url: details.image)
        }
    }
    
    func loadIllustration(url: URL) {
        Task {
            illustration = await appContext.imageLoadingService.loadImage(from: .url(url, maxSize: nil), downsampleDescription: nil)
            #if DEBUG
            illustration = UIImage.Preview.previewPortrait
            #endif
        }
    }
}

@available(iOS 17, *)
#Preview {
    HotFeatureSuggestionDetailsView(suggestion: .mock())
}
