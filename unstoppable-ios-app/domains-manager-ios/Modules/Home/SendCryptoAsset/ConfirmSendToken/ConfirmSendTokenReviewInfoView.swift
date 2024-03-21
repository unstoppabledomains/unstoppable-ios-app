//
//  ConfirmSendTokenReviewInfoView.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 21.03.2024.
//

import SwiftUI

struct ConfirmSendTokenReviewInfoView: View {
    
    private let lineWidth: CGFloat = 1
    private let sectionHeight: CGFloat = 48
    private let numberOfSections = 5

    var body: some View {
        ZStack {
            curveLine()
            infoSectionsView()
        }
    }
}

// MARK: - Private methods
private extension ConfirmSendTokenReviewInfoView {
    @ViewBuilder
    func infoSectionsView() -> some View {
        VStack(spacing: 0) {
            ForEach(getCurrentSections(), id: \.self) { section in
                viewForSection(section)
                    .frame(height: sectionHeight)
            }
        }
        .padding(.init(horizontal: 16))
        .offset(y: sectionHeight / 2)
    }
    
    @ViewBuilder
    func viewForSection(_ section: SectionType) -> some View {
        switch section {
        case .infoValue(let info):
            viewForInfoValueSection(info)
        case .info(let info):
            viewForInfoSection(info)
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
                    Text(info.value)
                        .font(.currentFont(size: 16, weight: .medium))
                        .foregroundStyle(info.valueColor)
                    if let subValue = info.subValue {
                        Text(subValue)
                            .font(.currentFont(size: 16, weight: .medium))
                            .foregroundStyle(Color.foregroundSecondary)
                    }
                }
                Spacer()
            }
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

// MARK: - Private methods
private extension ConfirmSendTokenReviewInfoView {
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
    }
    
    func getCurrentSections() -> [SectionType] {
        [.infoValue(.init(title: "From",
                          icon: .domainSharePlaceholder,
                          value: "dans.crypto")),
         .infoValue(.init(title: "Chain",
                          icon: .ethereumIcon,
                          value: "Ethereum")),
         .infoValue(.init(title: "Speed",
                          icon: .ethereumIcon,
                          iconColor: .foregroundSecondary,
                          value: "Fast",
                          valueColor: .foregroundWarning,
                          subValue: "~ 4 sec")),
         .infoValue(.init(title: "Fee estimate",
                          icon: .ethereumIcon,
                          value: "$4.20")),
         .info("Review the above before confirming.\nOnce made, your transaction is irreversible")]
    }
}

// MARK: - Private methods
private extension ConfirmSendTokenReviewInfoView {
    @ViewBuilder
    func curveLine() -> some View {
        ConnectCurve(radius: 24,
                     lineWidth: lineWidth,
                     sectionHeight: sectionHeight,
                     numberOfSections: numberOfSections)
        .stroke(lineWidth: lineWidth)
        .foregroundStyle(Color.white.opacity(0.08))
        .shadow(color: Color.foregroundOnEmphasis2,
                radius: 0, x: 0, y: -1)
        .frame(height: CGFloat(numberOfSections) * sectionHeight)
    }
}

// MARK: - Private methods
private extension ConfirmSendTokenReviewInfoView {
    struct ConnectCurve: Shape {
        let radius: CGFloat
        let lineWidth: CGFloat
        let padding: CGFloat = 16
        let sectionHeight: CGFloat
        let numberOfSections: Int
        
        func path(in rect: CGRect) -> Path {
            var path = Path()
            
            for section in 0..<numberOfSections {
                let sectionRect = getRectForSection(section, in: rect)
                if section % 2 == 0 {
                    let padding = section == 0 ? self.padding : 0.0
                    addCurveFromTopRightToBottomLeft(in: &path,
                                                     rect: sectionRect,
                                                     padding: padding)
                } else {
                    addCurveFromTopLeftToBottomRight(in: &path,
                                                     rect: sectionRect,
                                                     padding: 0)
                }
            }
            
            addFinalDot(in: &path, rect: rect)
            
            return path
        }
        
        func addFinalDot(in path: inout Path,
                         rect: CGRect) {
            let sectionRect = getRectForSection(numberOfSections - 1, in: rect)
            let minX = rect.minX + lineWidth

            let center = CGPoint(x: minX,
                    y: rect.maxY)
            
            var circlePath = Path()
            circlePath.move(to: center)
            
            for i in 1...2 {
                circlePath.addArc(center: center,
                                  radius: CGFloat(i),
                                  startAngle: .degrees(0),
                                  endAngle: .degrees(360),
                                  clockwise: true)
            }
            
            path.addPath(circlePath)
        }
        
        func getRectForSection(_ section: Int,
                               in rect: CGRect) -> CGRect {
            var rect = rect
            rect.size.height = sectionHeight
            rect.origin.y = CGFloat(section) * sectionHeight
            return rect
        }
        
        func addCurveFromTopLeftToBottomRight(in path: inout Path,
                                              rect: CGRect,
                                              padding: CGFloat) {
            let startPoint = CGPoint(x: rect.minX + padding + lineWidth,
                                     y: rect.minY)
            path.move(to: startPoint)
            
            path.addArc(tangent1End: CGPoint(x: startPoint.x,
                                             y: rect.midY),
                        tangent2End: CGPoint(x: rect.minX + radius + padding,
                                             y: rect.midY),
                        radius: radius,
                        transform: .identity)
            
            path.addLine(to: CGPoint(x: rect.maxX - radius - padding,
                                     y: rect.midY))
            
            let maxX = rect.maxX - lineWidth - padding
            path.addArc(tangent1End: CGPoint(x: maxX,
                                             y: rect.midY),
                        tangent2End: CGPoint(x: maxX,
                                             y: rect.maxY),
                        radius: radius,
                        transform: .identity)
        }
        
        func addCurveFromTopRightToBottomLeft(in path: inout Path,
                                              rect: CGRect,
                                              padding: CGFloat) {
            let startPoint = CGPoint(x: rect.maxX - padding - lineWidth,
                                     y: rect.minY)
            path.move(to: startPoint)
            
            path.addArc(tangent1End: CGPoint(x: startPoint.x,
                                             y: rect.midY),
                        tangent2End: CGPoint(x: rect.maxX - radius - padding,
                                             y: rect.midY),
                        radius: radius,
                        transform: .identity)
            
            path.addLine(to: CGPoint(x: rect.minX + radius + padding,
                                     y: rect.midY))
            
            let minX = rect.minX + lineWidth
            path.addArc(tangent1End: CGPoint(x: minX,
                                             y: rect.midY),
                        tangent2End: CGPoint(x: minX,
                                             y: rect.maxY),
                        radius: radius,
                        transform: .identity)
        }
        
    }
}

#Preview {
    ConfirmSendTokenReviewInfoView()
}
