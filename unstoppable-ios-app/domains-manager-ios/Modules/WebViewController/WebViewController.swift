//
//  WebViewController.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 19.04.2022.
//

import UIKit
import WebKit

class WebViewController: BaseViewController {
    
    private(set) var webView: WKWebView!
    private var moveBackItem: UIBarButtonItem!
    private var moveForwardItem: UIBarButtonItem!
    private static var authChallengeState = AuthChallengeState()
    var url: URL?
    override var analyticsName: Analytics.ViewName { .webView }
    
    static func show(in viewController: UIViewController, withURL url: URL) {
        let vc = WebViewController()
        vc.url = url
        
        let nav = UINavigationController(rootViewController: vc)
        nav.isModalInPresentation = true
        viewController.present(nav, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        loadURL(self.url)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "canGoBack" || keyPath == "canGoForward" {
            updateMoveButtons()
        } else if keyPath == "URL",
                  let url = change?[.newKey] as? URL {
            didNavigateToURL(url)
        }
    }
}

// MARK: - WKNavigationDelegate
extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
        updateMoveButtons()
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if User.instance.getSettings().isTestnetUsed {
            if let credentials = WebViewController.authChallengeState.credentials,
               challenge.previousFailureCount == WebViewController.authChallengeState.failureAttempts {
                completionHandler(.useCredential, credentials)
            } else {
                let alert = UIAlertController(title: "Authroization", message: nil, preferredStyle: .alert)
                alert.addTextField { textField in
                    textField.placeholder = "Login"
                    if let login = WebViewController.authChallengeState.credentials?.user {
                        textField.text = login
                    }
                }
                alert.addTextField { textField in
                    textField.placeholder = "Password"
                    textField.isSecureTextEntry = true 
                }
                
                alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: {  _ in
                    let login = alert.textFields![0].text ?? ""
                    let password = alert.textFields![1].text ?? ""
                    let credentials = URLCredential(user: login,
                                                    password: password,
                                                    persistence: .none)
                    WebViewController.authChallengeState.credentials = credentials
                    WebViewController.authChallengeState.failureAttempts = challenge.previousFailureCount
                    completionHandler(.useCredential, credentials)
                }))
                
                present(alert, animated: true)
            }
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

// MARK: - Open methods
extension WebViewController {
    @objc func doneButtonPressed() {
        logButtonPressedAnalyticEvents(button: .done)
        UDVibration.buttonTap.vibrate()
        dismiss(animated: true)
    }
    
    @objc func didNavigateToURL(_ url: URL) {
        
    }
}

// MARK: - Actions
private extension WebViewController {
    @objc func refreshButtonPressed() {
        logButtonPressedAnalyticEvents(button: .refreshPage)
        UDVibration.buttonTap.vibrate()
        loadURL(webView.url)
    }
    
    @objc func browserButtonPressed() {
        logButtonPressedAnalyticEvents(button: .openBrowser)
        UDVibration.buttonTap.vibrate()
        guard let url = self.webView?.url, UIApplication.shared.canOpenURL(url) else { return }

        UIApplication.shared.open(url, options: [:])
    }
    
    @objc func shareButtonPressed() {
        logButtonPressedAnalyticEvents(button: .shareLink)
        UDVibration.buttonTap.vibrate()
        guard let url = self.webView?.url else { return }

        let ac = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(ac, animated: true)
    }
    
    @objc func moveBackButtonPressed() {
        logButtonPressedAnalyticEvents(button: .moveBack)
        UDVibration.buttonTap.vibrate()
        webView.goBack()
    }
    
    @objc func moveForwardButtonPressed() {
        logButtonPressedAnalyticEvents(button: .moveForward)
        UDVibration.buttonTap.vibrate()
        webView.goForward()
    }
}

// MARK: - Private methods
private extension WebViewController {
    func loadURL(_ url: URL?) {
        guard let url = url else { return }
        
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 0)
        webView.load(request)
    }
    
    func updateMoveButtons() {
        moveBackItem.isEnabled = webView.canGoBack
        moveForwardItem.isEnabled = webView.canGoForward
    }
    
    func clearCookies() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
    }
}

// MARK: - Setup methods
private extension WebViewController {
    func setup() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        setupWebView()
        setupToolbar()
        updateMoveButtons()
        setupNavBar()
    }
    
    func setupWebView() {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.applicationNameForUserAgent = "Version/8.0.2 Safari/600.2.5"

        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        let navBarHeight = navigationController?.navigationBar.frame.height ?? 0
        let toolbarHeight = navigationController?.toolbar.bounds.height ?? 0
        let safeAreaBottomInset = SceneDelegate.shared?.window?.safeAreaInsets.bottom ?? 0
        webView.embedInSuperView(view, constraints: UIEdgeInsets(top: navBarHeight, left: 0, bottom: toolbarHeight + safeAreaBottomInset, right: 0))
        webView.navigationDelegate = self
   
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.canGoBack), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.canGoForward), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.url), options: .new, context: nil)
    }
    
    func setupToolbar() {
        navigationController?.isToolbarHidden = false
        
        let safariItem = UIBarButtonItem(image: .safari, style: .plain, target: self, action: #selector(browserButtonPressed))
        let shareItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareButtonPressed))
        moveBackItem = UIBarButtonItem(image: .chevronLeft, style: .plain, target: self, action: #selector(moveBackButtonPressed))
        moveForwardItem = UIBarButtonItem(image: .chevronRight, style: .plain, target: self, action: #selector(moveForwardButtonPressed))
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolbarItems = [moveBackItem, spacer, moveForwardItem, spacer, spacer, shareItem, spacer, safariItem]
    }
    
    func setupNavBar() {
        navigationController?.navigationBar.backgroundColor = .systemGroupedBackground
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed))
        navigationItem.leftBarButtonItem = doneButton
        
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshButtonPressed))
        navigationItem.rightBarButtonItem = refreshButton
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .foregroundDefault
        titleLabel.setAttributedTextWith(text: url?.host ?? "", font: .currentFont(withSize: 14, weight: .semibold))
        navigationItem.titleView = titleLabel
    }
}

// MARK: - Private methods
private extension WebViewController {
    struct AuthChallengeState {
        var credentials: URLCredential?
        var failureAttempts: Int = 0
    }
}
