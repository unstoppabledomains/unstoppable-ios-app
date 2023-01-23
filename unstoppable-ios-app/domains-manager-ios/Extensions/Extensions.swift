//
//  Extensions.swift
//  domains-manager-ios
//
//  Created by Roman on 03.10.2020.
//

import Foundation
import UIKit

typealias Wei = UInt64
typealias Gwei = Double
extension String {
    
    var hash: Int {
        var hasher = Hasher()
        hasher.combine(self)
        return abs(hasher.finalize())
    }
    
}

typealias HexAddress = String

extension HexAddress {
    var normalized: String {
        let cleanAddress = self.droppedHexPrefix.lowercased()
        if cleanAddress.count == 64 {
            return String.hexPrefix + cleanAddress.dropFirst(24)
        }
        return String.hexPrefix + cleanAddress
    }
    
    var normalized32: String {
        let cleanAddress = self.droppedHexPrefix.lowercased()
        if cleanAddress.count < 64 {
            let zeroCharacter: Character = "0"
            let arr = Array(repeating: zeroCharacter, count: 64 - cleanAddress.count)
            let zeros = String(arr)

            return String.hexPrefix + zeros + cleanAddress
        }
        return String.hexPrefix + cleanAddress
    }
}

extension HexAddress {
    static var hexPrefix: String { "0x" }
    
    var hasHexPrefix: Bool {
        return self.hasPrefix(String.hexPrefix)
    }
    
    var hexToDec: UInt64? {
        return UInt64(self.droppedHexPrefix, radix: 16)
    }
    
    var hexToAscii: String? {
        let cleaned = self.droppedHexPrefix
        
        var result = ""

        for pairsCount in 0...(cleaned.count/2 - 1) {
            
            let start = cleaned.index(cleaned.startIndex, offsetBy: pairsCount * 2)
            let end = cleaned.index(start, offsetBy: 2)
            
            guard let code = UInt32(cleaned[start..<end], radix: 16) else { break }
            
            let symbol = code == 0 ? " " : String(Character(Unicode.Scalar(code)!))
            result += symbol
            
        }
        return result.trimmingCharacters(in: .whitespacesAndNewlines).trimmed
    }
    
    var asciiToHex: String? {
        let codes = self.compactMap({$0.asciiValue})
        guard self.count == codes.count else { return nil }
        return codes.map { String(format: "%02hhx", $0) }.joined()
    }
    
    var trimmed: String {
        self.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789.abcdefghijklmnopqrstuvwxyz-").inverted)
    }
    
    var trimmedSpaces: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var droppedHexPrefix: String {
        return self.hasHexPrefix ? String(self.dropFirst(String.hexPrefix.count)) : self
    }
    
    var bytesArray: [UInt8]? {
        let cleanNumber = self.droppedHexPrefix
        var raw = [UInt8]()
        for i in stride(from: 0, to: cleanNumber.count, by: 2) {
            let s = cleanNumber.index(cleanNumber.startIndex, offsetBy: i)
            let e = cleanNumber.index(cleanNumber.startIndex, offsetBy: i + 2)
            
            guard let b = UInt8(String(cleanNumber[s..<e]), radix: 16) else {
                return nil
            }
            raw.append(b)
        }
        return raw
    }
}

protocol UiUpdateable {}
extension UiUpdateable {
    func updateUI() {}
}

class UiUpdateableViewController: UIViewController, UiUpdateable {
}

class GenericViewController: UiUpdateableViewController, SelfNameable {
    
    override func viewWillAppear(_ animated: Bool) {
        setBackgroundLayer()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
        tapGesture.cancelsTouchesInView = false // fixes the need to tap with 2 fingers on other controls
        
        updateUI()
        
        super.viewWillAppear(animated)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        setBackgroundLayer()
    }
    
    private func setBackgroundLayer() {
        if let gradient = (self.view.layer.sublayers ?? []).first(where: { $0 is CAGradientLayer }) {
            gradient.removeFromSuperlayer()
        }
        
        let layer = CAGradientLayer()
        layer.frame = self.view.bounds
        layer.colors = [UIColor.UD.topGradient!.cgColor,
                        UIColor.UD.middleGradient!.cgColor,
                        UIColor.UD.bottomGradient!.cgColor]
        self.view.layer.insertSublayer(layer, at: 0)
    }
    
    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
}

@nonobjc extension UIViewController {
    func addChildViewController(_ childController: UIViewController, andEmbedToView containerView: UIView) {
        childController.willMove(toParent: self)
        addChild(childController)
        childController.view.frame = containerView.bounds
        childController.view.embedInSuperView(containerView)
        childController.didMove(toParent: self)
    }
    
    func add(_ child: UIViewController, frame: CGRect? = nil) {
        addChild(child)

        if let frame = frame {
            child.view.frame = frame
        }

        view.addSubview(child.view)
        child.didMove(toParent: self)
    }

    func remove() {
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
    
    func onMain(_ block: @escaping ()->Void) {
        if Thread.isMainThread {
            block()
        } else {
            DispatchQueue.main.async {
                block()
            }
        }
    }
}

protocol SecureSelectionHost where Self: GenericViewController { }

class RoundedCornersView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = 12
    }
}

class ShadowedView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        self.subviews.forEach {
            $0.layer.shadowColor = UIColor.label.cgColor
            $0.layer.shadowOpacity = 0.15
            $0.layer.shadowRadius = 16  
        }
    }
}

// UI Animations
extension UIView {
    func embedInSuperView(_ superView: UIView, constraints: UIEdgeInsets = .zero) {
        self.putInSuperview(superView)
        
        self.leadingAnchor.constraint(equalTo: superView.leadingAnchor, constant: constraints.left).isActive = true
        superView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: constraints.right).isActive = true
        self.topAnchor.constraint(equalTo: superView.topAnchor, constant: constraints.top).isActive = true
        superView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: constraints.bottom).isActive = true
    }
    
    func putInSuperview(_ view: UIView) {
        view.addSubview(self)
        self.clipsToBounds = true
        self.translatesAutoresizingMaskIntoConstraints = false
    }
    
    func growAndSqueeze() {
        let MAX_GROW: CGFloat = 1.08
        let MIN_GROW: CGFloat = 1.04
        let ONE_MOTION_PHASE_DURATION = 0.6
        UIView.animate(withDuration: ONE_MOTION_PHASE_DURATION) {
            self.transform = CGAffineTransform(scaleX: MAX_GROW, y: MAX_GROW)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + ONE_MOTION_PHASE_DURATION) {
            UIView.animate(withDuration: ONE_MOTION_PHASE_DURATION) {
                self.transform = CGAffineTransform(scaleX: MIN_GROW, y: MIN_GROW)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + ONE_MOTION_PHASE_DURATION * 4) {
            UIView.animate(withDuration: ONE_MOTION_PHASE_DURATION) {
                self.transform = CGAffineTransform.identity
            }
        }
    }
    
    func addwFlipping(to hostView: UIView,
                      via animationOption: UIView.AnimationOptions = .transitionFlipFromRight) {
        addwView(to: hostView, onTop: false, via: animationOption)
    }
    
    func addwView(to hostView: UIView,
                  onTop: Bool,
                  via animationOption: UIView.AnimationOptions,
                  over: UIView? = nil) {
        if !onTop {
            hostView.subviews.forEach{ $0.removeFromSuperview() }
        }
        hostView.subviews.forEach{ $0.isHidden = true }
        
        UIView.transition(with: hostView, duration: 0.3,
                          options: [animationOption, .curveEaseOut],
                          animations: {
                            if let overlay = over {
                                hostView.addSubview(overlay)
                            }
                            hostView.addSubview(self)
                            self.translatesAutoresizingMaskIntoConstraints = false
                            NSLayoutConstraint.activate([
                                self.topAnchor.constraint(equalTo: hostView.topAnchor),
                                self.bottomAnchor.constraint(equalTo: hostView.bottomAnchor),
                                self.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
                                self.trailingAnchor.constraint(equalTo: hostView.trailingAnchor)
                            ])
                          },
                          completion: nil)
    }
    
    func shake() {
        DispatchQueue.main.async {
            self.transform = CGAffineTransform(translationX: 12, y: 0)
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.15, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                self.transform = CGAffineTransform.identity
            }, completion: nil)
        }
    }
    
    func showAndHideAndRemove() {
        self.alpha = 0
        UIView.animate( withDuration: 0.2,
                        animations: { self.alpha = 1 }
                        )
        DispatchQueue.main
            .asyncAfter(deadline: .now() + 0.8,
                        execute: {
                            UIView.animate(withDuration: 0.3, animations: {
                                self.alpha = 0
                            },
                            completion: {_ in self.removeFromSuperview()})
                        })
    }
    
    func dismissUpperSubview(tag: Int? = nil) {
        let count = self.subviews.count
        guard count > 0 else { return }
        let toDismiss = self.subviews[count - 1]
        if let blurViewTag = tag {
            guard toDismiss.tag == blurViewTag else { return }
        }
        toDismiss.removeFromSuperview()
    }
    
    func removeSubviewWith(tag: Int? = nil) {
        for view in subviews where view.tag == tag {
            view.removeFromSuperview()
        }
    }
        
    func isTopSubviewTagged(with tag: Int) -> Bool {
        let count = self.subviews.count
        guard count > 0 else { return false }
        let toDismiss = self.subviews[count - 1]
        return toDismiss.tag == tag
    }
    
    func getUpperSubview() -> UIView? {
        return getUpperSubview(offset: 0)
    }
    
    func getUpperSubview(offset index: Int) -> UIView? {
        let count = self.subviews.count
        guard count > index else { return nil }
        return self.subviews[count - 1 - index]
    }
    
    func createBlurView(with alpha: CGFloat = 0) -> UIView {
        let blurEffect = UIBlurEffect(style: .dark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = self.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.alpha = alpha
        return blurEffectView
    }
    
    static func createCopiedLabel(frame: CGRect) -> UILabel {
        let copied = UILabel(frame: frame)
        copied.text = "Copied to Clipboard"
        copied.textAlignment = .center
        copied.backgroundColor = UIColor.secondarySystemBackground
        copied.layer.cornerRadius = 10
        copied.clipsToBounds = true
        return copied
    }
    
    static func createLabel(frame: CGRect, text: String) -> UILabel {
        let label = UILabel(frame: frame)
        label.text = text
        label.textAlignment = .center
        label.backgroundColor = UIColor.secondarySystemBackground
        label.textColor = UIColor.systemRed
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        return label
    }
    
    func displayCopiedMessage() {
        let copied = UIView.createCopiedLabel(frame: self.bounds)
        self.addSubview(copied)
        copied.showAndHideAndRemove()
    }
    
    func findTheSubview(by tag: Int) -> UIView? {
        self.subviews.filter({$0.tag == tag}).first
    }
    
    func displayMessage(_ message: String) {
        let messageView = UIView.createLabel(frame: self.bounds, text: message)
        self.addSubview(messageView)
        messageView.showAndHideAndRemove()
    }
}

extension UIViewController {
    func showSimpleAlert (title: String, body: String, handler: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: body, preferredStyle: .alert)
        let ok = UIAlertAction(title: String.Constants.ok.localized(), style: .default, handler: handler)
        alert.addAction(ok)
        self.present(alert, animated: true)
    }
    
    func showTemporaryAlert (title: String?,
                             body: String,
                             for time: TimeInterval = 4) {
        let alertController = UIAlertController(title: title, message: body, preferredStyle: .alert)
        self.present(alertController, animated: true, completion: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + time) {
            alertController.dismiss(animated: true, completion: nil)
        }
    }
}

extension UIColor {
    struct UD {
        static let mainAccent = UIColor(named: "MainBlue")
        static let mainAccentDesaturated = UIColor(named: "MainBlueDesat")
        
        // bckgrnd gradient
        static let topGradient = UIColor(named: "TopGradientPink")
        static let middleGradient = UIColor(named: "MiddleGradientBlue")
        static let bottomGradient = UIColor(named: "BottomGradientBlue")
        
        //Pending Indication
        static let pendingFont = UIColor(named: "PendingFont")
        static let pendingBackground = UIColor(named: "PendingBackground")
        
        //controls
        static let disabledBackground = UIColor(named: "DisabledBackground")
        static let disabledFont = UIColor(named: "DisabledFont")
        
        static let grayBorder = UIColor(named: "GrayBorder")
        static let redCritical = UIColor(named: "RedCritical")
        
        static let menuSelectionBorder = UIColor(named: "MenuSelectionBorder")
        
        static let neutralGray = UIColor(named: "NeutralGray")
    }
}

extension UIImage {
    static func makeMenuIcon() -> UIImage? {
        UIImage(named: "menu")
    }
}

extension Array {
  mutating func remove(at indexes: [Int]) {
    for index in indexes.sorted(by: >) {
      remove(at: index)
    }
  }
}

extension Array where Element: Equatable {
    enum ManagementError: Swift.Error {
        case failedToFindElement
    }

    mutating func update(newElement: Element) {
        if let index = self.firstIndex(of: newElement) {
            self[index] = newElement
        } else {
            self.append(newElement)
        }
    }
}

extension Set where Element == Int {
    func getLowestUnoccupiedInt() -> Int {
        let max = (self.max() ?? 0) + 1
        for index in 1...max {
            if !self.contains(index) { return index }
        }
        fatalError() // never reached
    }
}

extension Array where Element == String {
    public func getIndices(startingWith namePrefix: String) -> Set<Int> {
        Set(self.filter({$0.prefix(namePrefix.count) == namePrefix})
            .map({ String($0.dropFirst(namePrefix.count)).trimmedSpaces })
            .compactMap({Int($0)})
            )
    }
}

extension UITableView {
    func tweakForVersions() {
        // workaround for empty rows separators
        self.tableFooterView = UIView()
        
        // workaround for insets of separators
        if #available(iOS 9, *) {
            self.cellLayoutMarginsFollowReadableWidth = false
        }
    }
    
    // Must be called from the main thread
    func selectAllRows() {
        let totalRows = self.numberOfRows(inSection: 0)
        for row in 0..<totalRows {
            self.selectRow(at: IndexPath(row: row, section: 0), animated: true, scrollPosition: .none)
        }
    }
}

extension Data {
    public func dataToHexString() -> String {
        return bytes.toHexString()
    }
}

extension UIFont {
    static let fontName = "SFPro-Regular"
    static let fontBoldName = "SFPro-Bold"

    static func currentFont(withSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        interFont(ofSize: size, weight: weight)
    }
    
    static func interFont(ofSize fontSize: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let defaultFont: UIFont = .systemFont(ofSize: fontSize, weight: weight)
        
        switch weight {
        case .black:
            return UIFont(name: "Inter-Black", size: fontSize) ?? defaultFont
        case .bold:
            return UIFont(name: "Inter-Bold", size: fontSize) ?? defaultFont
        case .heavy:
            return UIFont(name: "Inter-ExtraBold", size: fontSize) ?? defaultFont
        case .ultraLight:
            return UIFont(name: "Inter-ExtraLight", size: fontSize) ?? defaultFont
        case .light:
            return UIFont(name: "Inter-Light", size: fontSize) ?? defaultFont
        case .regular:
            return UIFont(name: "Inter-Regular", size: fontSize) ?? defaultFont
        case .semibold:
            return UIFont(name: "Inter-SemiBold", size: fontSize) ?? defaultFont
        case .medium:
            return UIFont(name: "Inter-Medium", size: fontSize) ?? defaultFont
        case .thin:
            return UIFont(name: "Inter-Thin", size: fontSize) ?? defaultFont
        default:
            return .interFont(ofSize: fontSize, weight: .regular)
        }
    }
    
    static func helveticaNeueCustom(size: CGFloat) -> UIFont {
        UIFont(name: "HelveticaNeue-Custom", size: size) ?? .systemFont(ofSize: size, weight: .black)
    }
    
    static func getCurrentFont(withSize size: CGFloat) -> UIFont {
        var openSansFont: UIFont?
        let fontName: CFString = UIFont.fontName as CFString
        openSansFont = CTFontCreateWithName(fontName, size, nil)
        return openSansFont == nil ? UIFont.systemFont(ofSize: size) : openSansFont!
    }
    
    static func getCurrentBoldFont(withSize size: CGFloat) -> UIFont {
        var openSansFont: UIFont?
        let fontName: CFString = UIFont.fontBoldName as CFString
        openSansFont = CTFontCreateWithName(fontName, size, nil)
        return openSansFont == nil ? UIFont.systemFont(ofSize: size) : openSansFont!
    }

    func getWidth(of string: String) -> CGFloat {
        let nsString: NSString = string as NSString
        return nsString.size( withAttributes: [NSAttributedString.Key.font : self ]).width
    }
}

extension Array where Element: Hashable {
    /**
     * Reduces the array only to the elements contained in the set, keeping
     * the order of the original array
     */
    func squeeze(to set: Set<Element>) -> Array<Element> {
        return self.reduce(into: Array<Element>()) { res, el in
            if set.contains(el) { res.append(el) }
        }
    }
}

extension Int {
    var asHexString16: String {
        let forcedLength = 16
        let stringHex = String(self, radix: 16, uppercase: false)
        
        if stringHex.count < forcedLength {
            let zeroCharacter: Character = "0"
            let arr = Array(repeating: zeroCharacter, count: forcedLength - stringHex.count)
            let zeros = String(arr)
            
            return zeros + stringHex
        } else {
            return stringHex
        }
    }
}

extension UInt {
    var asHexString16: String {
        let forcedLength = 16
        let stringHex = String(self, radix: 16, uppercase: false)
        
        if stringHex.count < forcedLength {
            let zeroCharacter: Character = "0"
            let arr = Array(repeating: zeroCharacter, count: forcedLength - stringHex.count)
            let zeros = String(arr)
            
            return zeros + stringHex
        } else {
            return stringHex
        }
    }
}

extension URL? {
    var pathExtensionPng: Bool {
        guard let self = self else { return false }
        return self.pathExtensionPng
    }
}

extension URL {
    var pathExtensionPng: Bool {
        self.pathExtension == "png"
    }
}
