//
//  ExpandableTextEditor.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.02.2024.
//

import SwiftUI

struct ExpandableTextEditor: View {
    let text: Binding<String>
    let placeholder: String
    @State private var textSize: CGFloat = 0
    @State var textEditorHeight : CGFloat = 20
    private var font: Font { .currentFont(size: 16) }
    @FocusState.Binding var focused: Bool

    var body: some View {
        
        ZStack(alignment: .leading) {
            Text(text.wrappedValue)
                .font(font)
                .foregroundColor(.clear)
                .padding(EdgeInsets(top: 6, leading: 12,
                                    bottom: 6, trailing: 12))
                .background(GeometryReader {
                    Color.clear.preference(key: ViewHeightKey.self,
                                           value: $0.frame(in: .local).size.height)
                })
            
            TextEditor(text: text)
                .font(font)
                .foregroundStyle(Color.foregroundDefault)
                .frame(height: max(40, textEditorHeight))
                .scrollContentBackground(.hidden)
                .padding(EdgeInsets(top: 0, leading: 8,
                                    bottom: 0, trailing: 8))
                .background(focused ? Color.backgroundMuted : Color.backgroundSubtle)
                .tint(Color.foregroundAccent)
                .focused($focused)
            
            Text(placeholder)
                .opacity(text.wrappedValue.isEmpty ? 1 : 0)
                .font(.currentFont(size: 16))
                .foregroundStyle(Color.foregroundSecondary)
                .padding(.init(horizontal: 16))
        }
        .onPreferenceChange(ViewHeightKey.self) { textEditorHeight = $0 }
    }
    
    struct ViewHeightKey: PreferenceKey {
        static var defaultValue: CGFloat { 0 }
        static func reduce(value: inout Value, nextValue: () -> Value) {
            value = value + nextValue()
        }
    }
}

#Preview {
    
    struct Preview: View {
        @FocusState var focused: Bool

        var body: some View {
            ExpandableTextEditor(text: .constant(""),
                                 placeholder: "Hello",
                                 textEditorHeight: 40,
                                 focused: $focused)
        }
    }
    
    return Preview()
}
