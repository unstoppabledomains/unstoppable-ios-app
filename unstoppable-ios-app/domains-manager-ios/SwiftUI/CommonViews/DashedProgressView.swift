//
//  DashedProgressView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 05.08.2024.
//

import SwiftUI

struct DashedProgressView: View {
    let configuration: DConfiguration
    let progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                dashesWithColor(color: configuration.notFilledColor,
                                width: geometry.size.width)
                dashesWithColor(color: configuration.filledColor,
                                width: geometry.size.width)
                .mask(
                    dashesMaskView(width: geometry.size.width)
                )
            }
        }
        .frame(width: 160.0, height: configuration.dashHeight)
        .animation(.default, value: progress)
    }
}

// MARK: - Private methods
private extension DashedProgressView {
    @ViewBuilder
    func dashesWithColor(color: UIColor,
                         width: CGFloat) -> some View {
        HStack(spacing: configuration.dashesSpacing) {
            ForEach(0..<configuration.numberOfDashes, id: \.self) { _ in
                RoundedRectangle(cornerRadius: configuration.dashHeight / 2)
                    .fill(Color(color))
                    .frame(width: dashWidth(in: width))
            }
        }
    }
    
    @ViewBuilder
    func dashesMaskView(width: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: configuration.dashHeight / 2)
            .frame(width: width * progress)
            .offset(x: -(width - width * progress) / 2)
    }
    
    func dashWidth(in totalWidth: CGFloat) -> CGFloat {
        let totalSpacing = CGFloat(configuration.numberOfDashes - 1) * configuration.dashesSpacing
        return (totalWidth - totalSpacing) / CGFloat(configuration.numberOfDashes)
    }
}

extension DashedProgressView {
    struct DConfiguration {
        var notFilledColor = UIColor.foregroundSubtle
        var filledColor = UIColor.foregroundAccent
        var numberOfDashes = 2
        var dashHeight: CGFloat = 4
        var dashesSpacing: CGFloat = 8
        
        static func white(numberOfDashes: Int) -> DConfiguration {
            DConfiguration(notFilledColor: .foregroundOnEmphasis.withAlphaComponent(0.32),
                           filledColor: .foregroundOnEmphasis,
                           numberOfDashes: numberOfDashes)
        }
    }
}

#Preview {
    DashedProgressView(
        configuration: .init(),
        progress: 0.2
    )
}
