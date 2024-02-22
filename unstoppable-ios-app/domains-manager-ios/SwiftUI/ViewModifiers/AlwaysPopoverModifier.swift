//
//  AlwaysPopoverModifier.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.02.2024.
//

import SwiftUI

struct AlwaysPopoverModifier<PopoverContent>: ViewModifier where PopoverContent: View {
    
    let isPresented: Binding<Bool>
    let contentBlock: () -> PopoverContent
    
    private struct Store {
        var anchorView = UIView()
    }
    @State private var store = Store()
    
    func body(content: Content) -> some View {
        if #available(iOS 16.6, *) {
            return content
                .popover(isPresented: isPresented, content: {
                    contentBlock()
                        .presentationCompactAdaptation(.popover)
                })
        } else {
            // Fallback on earlier versions
            if isPresented.wrappedValue {
                presentPopover()
            }
            
            return content
                .background(InternalAnchorView(uiView: store.anchorView))
        }
    }
    
    private func presentPopover() {
        let contentController = ContentViewController(rootView: contentBlock().padding(), isPresented: isPresented)
        contentController.modalPresentationStyle = .popover
        
        let view = store.anchorView
        guard let popover = contentController.popoverPresentationController else { return }
        popover.sourceView = view
        popover.sourceRect = view.bounds
        popover.delegate = contentController
        
        guard let sourceVC = view.findViewController() else { return }
        if let presentedVC = sourceVC.presentedViewController {
            presentedVC.dismiss(animated: true) {
                sourceVC.present(contentController, animated: true)
            }
        } else {
            sourceVC.present(contentController, animated: true)
        }
    }
}

private struct InternalAnchorView: UIViewRepresentable {
    typealias UIViewType = UIView
    let uiView: UIView
    
    func makeUIView(context: Self.Context) -> Self.UIViewType {
        uiView
    }
    
    func updateUIView(_ uiView: Self.UIViewType, context: Self.Context) { }
}


private class ContentViewController<V>: UIHostingController<V>, UIPopoverPresentationControllerDelegate where V:View {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let size = sizeThatFits(in: UIView.layoutFittingExpandedSize)
        preferredContentSize = size
    }
    var isPresented: Binding<Bool>
    
    init(rootView: V, isPresented: Binding<Bool>) {
        self.isPresented = isPresented
        super.init(rootView: rootView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.isPresented.wrappedValue = false
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

extension View {
    public func alwaysPopover<Content>(isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content) -> some View where Content : View {
        self.modifier(AlwaysPopoverModifier(isPresented: isPresented, contentBlock: content))
    }
}
