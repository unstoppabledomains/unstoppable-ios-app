//
//  CustomSheet.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 28.08.2023.
//

import SwiftUI

struct AdaptiveSheet<T: View>: ViewModifier {
    let sheetContent: T
    @Binding var isPresented: Bool
    let detents : [UISheetPresentationController.Detent]
    let smallestUndimmedDetentIdentifier: UISheetPresentationController.Detent.Identifier?
    let prefersScrollingExpandsWhenScrolledToEdge: Bool
    let prefersEdgeAttachedInCompactHeight: Bool
    
    init(isPresented: Binding<Bool>,
         detents : [UISheetPresentationController.Detent] = [.medium(), .large()],
         smallestUndimmedDetentIdentifier: UISheetPresentationController.Detent.Identifier? = .medium,
         prefersScrollingExpandsWhenScrolledToEdge: Bool = false,
         prefersEdgeAttachedInCompactHeight: Bool = true,
         @ViewBuilder content: @escaping () -> T) {
        self.sheetContent = content()
        self.detents = detents
        self.smallestUndimmedDetentIdentifier = smallestUndimmedDetentIdentifier
        self.prefersEdgeAttachedInCompactHeight = prefersEdgeAttachedInCompactHeight
        self.prefersScrollingExpandsWhenScrolledToEdge = prefersScrollingExpandsWhenScrolledToEdge
        self._isPresented = isPresented
    }
    func body(content: Content) -> some View {
        ZStack{
            content
            if isPresented {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        isPresented = false
                    }
            }
            CustomSheet_UI(isPresented: $isPresented,
                           detents: detents,
                           smallestUndimmedDetentIdentifier: smallestUndimmedDetentIdentifier,
                           prefersScrollingExpandsWhenScrolledToEdge: prefersScrollingExpandsWhenScrolledToEdge,
                           prefersEdgeAttachedInCompactHeight: prefersEdgeAttachedInCompactHeight,
                           content: {sheetContent}).frame(width: 0, height: 0)
        }
        .animation(.default, value: UUID())
    }
}

extension View {
    func adaptiveSheet<T: View>(isPresented: Binding<Bool>,
                                detents : [UISheetPresentationController.Detent] = [.medium(), .large()],
                                smallestUndimmedDetentIdentifier: UISheetPresentationController.Detent.Identifier? = .medium,
                                prefersScrollingExpandsWhenScrolledToEdge: Bool = false,
                                prefersEdgeAttachedInCompactHeight: Bool = true,
                                @ViewBuilder content: @escaping () -> T)-> some View {
        modifier(AdaptiveSheet(isPresented: isPresented,
                               detents : detents,
                               smallestUndimmedDetentIdentifier: smallestUndimmedDetentIdentifier,
                               prefersScrollingExpandsWhenScrolledToEdge: prefersScrollingExpandsWhenScrolledToEdge,
                               prefersEdgeAttachedInCompactHeight: prefersEdgeAttachedInCompactHeight,
                               content: content))
    }
}

struct CustomSheet_UI<Content: View>: UIViewControllerRepresentable {
    
    let content: Content
    @Binding var isPresented: Bool
    let detents : [UISheetPresentationController.Detent]
    let smallestUndimmedDetentIdentifier: UISheetPresentationController.Detent.Identifier?
    let prefersScrollingExpandsWhenScrolledToEdge: Bool
    let prefersEdgeAttachedInCompactHeight: Bool
    
    init(isPresented: Binding<Bool>,
         detents : [UISheetPresentationController.Detent] = [.medium(), .large()],
         smallestUndimmedDetentIdentifier: UISheetPresentationController.Detent.Identifier? = .medium,
         prefersScrollingExpandsWhenScrolledToEdge: Bool = false,
         prefersEdgeAttachedInCompactHeight: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.content = content()
        self.detents = detents
        self.smallestUndimmedDetentIdentifier = smallestUndimmedDetentIdentifier
        self.prefersEdgeAttachedInCompactHeight = prefersEdgeAttachedInCompactHeight
        self.prefersScrollingExpandsWhenScrolledToEdge = prefersScrollingExpandsWhenScrolledToEdge
        self._isPresented = isPresented
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> CustomSheetViewController<Content> {
        let vc = CustomSheetViewController(coordinator: context.coordinator, detents : detents, smallestUndimmedDetentIdentifier: smallestUndimmedDetentIdentifier, prefersScrollingExpandsWhenScrolledToEdge:  prefersScrollingExpandsWhenScrolledToEdge, prefersEdgeAttachedInCompactHeight: prefersEdgeAttachedInCompactHeight, content: {content})
        return vc
    }
    
    func updateUIViewController(_ uiViewController: CustomSheetViewController<Content>, context: Context) {
        if isPresented {
            uiViewController.presentModalView()
        } else {
            uiViewController.dismissModalView()
        }
    }
    
    class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {
        var parent: CustomSheet_UI
        
        init(_ parent: CustomSheet_UI) {
            self.parent = parent
        }
        
        //Adjust the variable when the user dismisses with a swipe
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            if parent.isPresented {
                parent.isPresented = false
            }
        }
    }
}

class CustomSheetViewController<Content: View>: UIViewController {
    let content: Content
    let coordinator: CustomSheet_UI<Content>.Coordinator
    let detents : [UISheetPresentationController.Detent]
    let smallestUndimmedDetentIdentifier: UISheetPresentationController.Detent.Identifier?
    let prefersScrollingExpandsWhenScrolledToEdge: Bool
    let prefersEdgeAttachedInCompactHeight: Bool
    private var isLandscape: Bool = UIDevice.current.orientation.isLandscape

    init(coordinator: CustomSheet_UI<Content>.Coordinator,
         detents : [UISheetPresentationController.Detent] = [.medium(), .large()],
         smallestUndimmedDetentIdentifier: UISheetPresentationController.Detent.Identifier? = .medium,
         prefersScrollingExpandsWhenScrolledToEdge: Bool = false,
         prefersEdgeAttachedInCompactHeight: Bool = true,
         @ViewBuilder content: @escaping () -> Content) {
        self.content = content()
        self.coordinator = coordinator
        self.detents = detents
        self.smallestUndimmedDetentIdentifier = smallestUndimmedDetentIdentifier
        self.prefersEdgeAttachedInCompactHeight = prefersEdgeAttachedInCompactHeight
        self.prefersScrollingExpandsWhenScrolledToEdge = prefersScrollingExpandsWhenScrolledToEdge
        super.init(nibName: nil, bundle: .main)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func dismissModalView() {
        guard presentedViewController != nil,
            let presentingViewController else { return }
        
        let dismissTag = 666
        if presentingViewController.view.tag != dismissTag  {
            presentingViewController.view.tag = dismissTag
            dismiss(animated: true, completion: {
                presentingViewController.view.tag = 0
            })
        }
    }
    
    func presentModalView() {
        let hostingController = UIHostingController(rootView: content)
        
        hostingController.modalPresentationStyle = .popover
        hostingController.presentationController?.delegate = coordinator as UIAdaptivePresentationControllerDelegate
        hostingController.modalTransitionStyle = .coverVertical
        if let hostPopover = hostingController.popoverPresentationController {
            hostPopover.sourceView = super.view
            let sheet = hostPopover.adaptiveSheetPresentationController
            //As of 13 Beta 4 if .medium() is the only detent in landscape error occurs
            sheet.detents = (isLandscape ? [.large()] : detents)
            sheet.largestUndimmedDetentIdentifier = smallestUndimmedDetentIdentifier
            sheet.prefersScrollingExpandsWhenScrolledToEdge = prefersScrollingExpandsWhenScrolledToEdge
            sheet.prefersEdgeAttachedInCompactHeight = prefersEdgeAttachedInCompactHeight
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
        }
        
        if presentedViewController == nil {
            present(hostingController, animated: true, completion: nil)
        }
    }
    
    /// To compensate for orientation as of 13 Beta 4 only [.large()] works for landscape
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        if UIDevice.current.orientation.isLandscape {
            isLandscape = true
            self.presentedViewController?.popoverPresentationController?.adaptiveSheetPresentationController.detents = [.large()]
        } else {
            isLandscape = false
            self.presentedViewController?.popoverPresentationController?.adaptiveSheetPresentationController.detents = detents
        }
    }
}

/// Example
struct CustomSheetParentView: View {
    @State private var isPresented = false
    
    var body: some View {
        VStack{
            Button("present sheet", action: {
                isPresented.toggle()
            }).adaptiveSheet(isPresented: $isPresented, detents: [.medium()], smallestUndimmedDetentIdentifier: .large) {
                Rectangle()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .foregroundColor(.clear)
                    .border(Color.blue, width: 3)
                    .overlay(Text("Hello, World!").frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture {
                            isPresented.toggle()
                        }
                    )
            }
        }
    }
}

struct CustomSheetView_Previews: PreviewProvider {
    static var previews: some View {
        CustomSheetParentView()
    }
}
