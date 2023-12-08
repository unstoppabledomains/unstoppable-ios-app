//
//  SwiftUIFlowLayout.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 27.11.2023.
//

import SwiftUI

struct FlowLayoutView<Data, RowContent>: View where Data: RandomAccessCollection, RowContent: View, Data.Element: Identifiable, Data.Index: Hashable {
    @State private var height: CGFloat = .zero
    
    private var data: Data
    private var spacing: CGFloat
    private var rowContent: (Data.Element) -> RowContent
    
    public init(_ data: Data,
                spacing: CGFloat = 4,
                @ViewBuilder rowContent: @escaping (Data.Element) -> RowContent) {
        self.data = data
        self.spacing = spacing
        self.rowContent = rowContent
    }
    
    var body: some View {
        GeometryReader { geometry in
            content(in: geometry)
                .background(viewHeight(for: $height))
        }
        .frame(height: height)
    }
    
    private func content(in geometry: GeometryProxy) -> some View {
        var offset = CGSize.zero
        return ZStack {
            ForEach(data.indices, id: \.self) { index in
                rowContent(data[index])
                    .padding(.all, spacing)
                    .alignmentGuide(HorizontalAlignment.center) { dimension in
                        if offset.width + dimension.width > geometry.size.width {
                            offset.width = 0
                            offset.height += dimension.height
                        }
                        
                        let result = offset.width
                        offset.width += dimension.width
                        
                        if data.index(after: index) == data.endIndex {
                            offset.width = 0
                        }
                        
                        return -result
                    }
                    .alignmentGuide(VerticalAlignment.center) { dimension in
                        let result = offset.height
                        
                        if data.index(after: index) == data.endIndex {
                            offset.height = 0
                        }
                        
                        return -result
                    }
            }
        }
    }
    
    private func viewHeight(for binding: Binding<CGFloat>) -> some View {
        GeometryReader { geometry -> Color in
            let rect = geometry.frame(in: .local)
            
            DispatchQueue.main.async {
                binding.wrappedValue = rect.size.height
            }
            return .clear
        }
    }
}


#Preview {
    struct Tag: Identifiable, Hashable {
        var id: String { name }
        
        let name: String
    }
    
    return ScrollView {
        FlowLayoutView(["Some long item here", "And then some longer one",
                        "Short", "Items", "Here", "And", "A", "Few", "More",
                        "And then a very very very long one"].map { Tag(name: $0) }) { tag in
            Button(action: {
                
            }, label: {
                Text(tag.name)
                    .bold()
                    .foregroundColor(.black)
                    .padding()
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.gray, lineWidth: 1.5))
            })
        }
        .padding()
    }
    
}
