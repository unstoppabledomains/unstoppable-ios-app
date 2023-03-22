//
//  UDTwitterSigner.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 16.03.2023.
//

import UIKit
import WebKit

final class UDTwitterSigner: NSObject {
        
    private var baseURL: String { NetworkConfig.migratedBaseUrl }
    
}

// MARK: - Open methods
extension UDTwitterSigner {
    func signIn(in viewController: UIViewController) async throws -> String {
        let twitterAuthVC = await showTwitterSignIn(in: viewController)
        
        let url = "\(baseURL)/api/user/twitter-login/auth"
        let requestURL = URL(string: url)!
        let token = try await twitterAuthVC.load(requestURL)
        
        return token
    }
}

// MARK: - Private methods
private extension UDTwitterSigner {
    @MainActor
    func showTwitterSignIn(in viewController: UIViewController) async -> TwitterAuthWebViewController {
        let twitterAuthVC = TwitterAuthWebViewController()
        let nav = UINavigationController(rootViewController: twitterAuthVC)
        nav.isModalInPresentation = true
        
        viewController.present(nav, animated: true)
        
        return twitterAuthVC
    }
}

private final class TwitterAuthWebViewController: UIViewController, WKNavigationDelegate {
    
    typealias TokenCompletionResult = Result<String, FirebaseAuthError>
    typealias TokenCompletionCallback = (TokenCompletionResult)->()
    
    private var webView: WKWebView?
    private var completion: TokenCompletionCallback?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let webView = WKWebView(frame: view.bounds)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        webView.navigationDelegate = self
        view.addSubview(webView)
        self.webView = webView
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelAction))
    }
    
    @objc private func cancelAction() {
        finishWithResult(.failure(FirebaseAuthError.userCancelled))
    }
    
    func load(_ requestURL: URL) async throws -> String {
        try await withCheckedThrowingContinuation({ continuation in
            self.load(requestURL: requestURL) { result in
                switch result {
                case .success(let token):
                    continuation.resume(returning: token)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        })
    }
    
    func load(requestURL: URL, completion: @escaping TokenCompletionCallback) {
        self.completion = completion
        webView?.load(URLRequest(url: requestURL))
    }
    
    private func finishWithResult(_ result: TokenCompletionResult) {
        completion?(result)
        completion = nil
        dismiss(animated: true)
    }
    
    // MARK: - WKNavigationDelegate
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url,
           url.pathComponents.contains("auth"),
           let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
           let queryItems = components.queryItems,
           let token = queryItems.first(where: { $0.name == "customToken" })?.value {
            finishWithResult(.success(token))
        }
        
        decisionHandler(.allow)
    }
}
