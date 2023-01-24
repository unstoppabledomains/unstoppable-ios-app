//
//  BuyDomainsWebViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.07.2022.
//

import UIKit
import WebKit

typealias PurchasedDomainsDetailsCallback = (DomainsPurchasedDetails)->()

final class BuyDomainsWebViewController: WebViewController {
    
    private var purchasedDomainDetails: DomainsPurchasedDetails?
    var requireMintingCallback: PurchasedDomainsDetailsCallback?
    override var analyticsName: Analytics.ViewName { .buyDomainsWebView }
    
    override func loadView() {
        super.loadView()
        
        self.url = String.Links.buyDomain.url!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
    }
    
    override func doneButtonPressed() {
        if let details = purchasedDomainDetails {
            logButtonPressedAnalyticEvents(button: .done)
            UDVibration.buttonTap.vibrate()
            dismissAndRequireMinting(with: details)
        } else {
            super.doneButtonPressed()
        }
    }
    
    override func didNavigateToURL(_ url: URL) {
        let urlPathComponents = Set(url.pathComponents)
        let startMintingComponents = Set(NavigationStartMintingAnchor.allCases.map({ $0.rawValue }))
        
        if !(urlPathComponents.intersection(startMintingComponents).isEmpty) {
            let email = parseEmail(from: url)
            let details = DomainsPurchasedDetails(email: email)
            dismissAndRequireMinting(with: details)
            return
        }
        
        let domainPurchasedComponents = Set(NavigationDomainPurchasedAnchor.allCases.map({ $0.rawValue }))
        if !(urlPathComponents.intersection(domainPurchasedComponents).isEmpty) {
            let email = parseEmail(from: url)
            self.purchasedDomainDetails = DomainsPurchasedDetails(email: email)
        }
    }
}

// MARK: - WKNavigationDelegate
extension BuyDomainsWebViewController {
    override func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        super.webView(webView, decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
    }
}

// MARK: - Private methods
private extension BuyDomainsWebViewController {
    func dismissAndRequireMinting(with details: DomainsPurchasedDetails) {
        dismiss(animated: true, completion: { [weak self] in
            self?.requireMintingCallback?(details)
        })
    }
    
    func parseEmail(from url: URL) -> String? {
        let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true)
        let email = components?.queryItems?.first(where: { $0.name == "email" })?.value
        
        if email == nil {
            Debugger.printFailure("No email for url \(url)", critical: true)
        }
        
        return email
    }
}

// MARK: - Setup methods
private extension BuyDomainsWebViewController {
    func setup() {
        toolbarItems?.remove(at: [7,5])
    }
}

// MARK: - Entities
private extension BuyDomainsWebViewController {
    enum NavigationStartMintingAnchor: String, CaseIterable {
        case mobileAppRedirect = "mobile-app-page-redirect"
    }
    
    enum NavigationDomainPurchasedAnchor: String, CaseIterable {
        case thankYou = "thank-you"
    }
}


extension WKContentWorld {
    func describe() -> String {
        let name = self.name ?? "N/A"
        
        return "WKContentWorld: Name - \(name)"
    }
}

extension WKScriptMessage {
    func describe() -> String {
        let name = self.name
        let body: String
        if let num = self.body as? NSNumber {
            body = "Num: \(num.stringValue)"
        } else if let str = self.body as? String {
            body = "Str: \(str)"
        } else if let date = self.body as? Date {
            body = "Date: \(date)"
        } else if let array = self.body as? [Any] {
            body = "Array: \(array)"
        } else if let dict = self.body as? [String : Any] {
            body = "Dict: \(dict)"
        } else {
            body = "NULL/Unknown"
        }
        var world: String = ""
        world = self.world.describe()
        
        return "WKScriptMessage: Name - \(name). Body - \(body). World - \(world)"
    }
}
