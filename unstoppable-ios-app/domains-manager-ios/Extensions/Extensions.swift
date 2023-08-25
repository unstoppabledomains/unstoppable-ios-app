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

extension HexAddress {
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
    
    var unicodeScalarToHex: String? {
        let codes = self.compactMap({$0.unicodeScalars.first?.value})
        guard self.count == codes.count else { return nil }
        return codes.map { String(format: "%02hhx", $0) }.joined()
    }
    
    var trimmed: String {
        self.trimmingCharacters(in: CharacterSet(charactersIn: "0123456789.abcdefghijklmnopqrstuvwxyz-").inverted)
    }
    
    var trimmedSpaces: String {
        self.trimmingCharacters(in: .whitespacesAndNewlines)
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
    
    func shake() {
        DispatchQueue.main.async {
            self.transform = CGAffineTransform(translationX: 12, y: 0)
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.15, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                self.transform = CGAffineTransform.identity
            }, completion: nil)
        }
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

extension Array {
  mutating func remove(at indexes: [Int]) {
    for index in indexes.sorted(by: >) {
      remove(at: index)
    }
  }
}

extension Array where Element: Equatable {
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
