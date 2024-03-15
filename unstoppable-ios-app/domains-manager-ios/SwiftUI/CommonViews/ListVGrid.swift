//
//  ListVGrid.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.02.2024.
//

import SwiftUI

struct ListVGrid<Element, Row: View>: View {
    
    let data: [Element]
    var numberOfColumns: Int = 2
    let verticalSpacing: CGFloat
    let horizontalSpacing: CGFloat
    
    @ViewBuilder var content: (Element) -> Row
    private let sideOffsets: CGFloat = 32
    private var numberOfColumnsForData: Int {
        (data.count / 2) + 1
    }
    var body: some View {
        ForEach(0..<numberOfColumnsForData, id: \.self) { column in
            rowView(column: column)
                .padding(EdgeInsets(top: column == 0 ? 0 : verticalSpacing, leading: 0, bottom: 0, trailing: 0))
        }
    }
    
    @ViewBuilder
    private func rowView(column: Int) -> some View {
        HStack(spacing: horizontalSpacing) {
            ForEach(0..<numberOfColumns, id: \.self) { row in
                if let element = findElement(column: column, row: row) {
                    content(element)
                        .frame(maxHeight: (UIScreen.main.bounds.width - sideOffsets - horizontalSpacing) / CGFloat(numberOfColumns))
                } else {
                    Spacer()
                }
            }
        }
    }
    
    private func findElement(column: Int, row: Int) -> Element? {
        let n = (column * 2) + row
        if n <= data.count - 1 {
            return data[n]
        }
        return nil
    }
    
}
