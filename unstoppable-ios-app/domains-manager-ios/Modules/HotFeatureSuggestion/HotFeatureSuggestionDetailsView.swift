//
//  HotFeatureSuggestionDetailsView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.12.2023.
//

import SwiftUI

struct HotFeatureSuggestionDetailsView: View, ViewAnalyticsLogger {
    
    @Environment(\.presentationMode) private var presentationMode

    let suggestion: HotFeatureSuggestion
    @State private var illustration: UIImage?
    @State private var scrollOffset: CGPoint = .zero
    var analyticsName: Analytics.ViewName { .hotFeatureDetails }
    // TODO: - Add additional analytic parameter for feature id
    var isTitleVisible: Bool { scrollOffset.y > 76 }
    
    
    var body: some View {
        NavigationView {
            OffsetObservingScrollView(offset: $scrollOffset) {
                contentView()
                    .sideInsets(16)
                UDButtonView(text: String.Constants.gotIt.localized(),
                             style: .large(.raisedTertiary)) {
                    logButtonPressedAnalyticEvents(button: .gotIt)
                    closeSuggestion()
                }
                             .padding()
            }
            .navigationBarTitle(Text(isTitleVisible ? title : ""), displayMode: .inline)
           
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseButtonView {
                        logButtonPressedAnalyticEvents(button: .close)
                        closeSuggestion()
                    }
                }
            }
        }
    }
}

// MARK: - Private methods
private extension HotFeatureSuggestionDetailsView {
    var title: String {
        switch suggestion.details {
        case .steps(let stepDetailsContent):
            return stepDetailsContent.title
        }
    }
    
    func closeSuggestion() {
        appContext.hotFeatureSuggestionsService.didViewHotFeatureSuggestion(suggestion)
        presentationMode.wrappedValue.dismiss()
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
