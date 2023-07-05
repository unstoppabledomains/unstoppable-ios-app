//
//  Base64DataTransformer.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 23.06.2023.
//

import Foundation

struct Base64DataTransformer {
    /// Doc: https://developer.mozilla.org/en-US/docs/Web/HTTP/Basics_of_HTTP/Data_URLs
    
    enum Mediatype: String {
        case imageJpeg = "image/jpeg"
    }
    
    static func removeDataFrom(string: String) -> String {
        guard string.count > 4 else { return string }
        
        let dataPrefix = "data"
        if String(string.prefix(dataPrefix.count)) == dataPrefix,
           let index = string.firstIndex(of: ",") {
            let nextIndex = string.index(after: index)
            
            let endIndex = string.endIndex
            guard nextIndex != endIndex else { return "" }
            
            return String(string[nextIndex..<endIndex])
        }
        
        return string
    }
    
    static func addingImageIdentifier(to string: String) -> String {
        addingFileMediaTypeIdentifier(.imageJpeg, to: string)
    }
    
    private static func addingFileMediaTypeIdentifier(_ mediaType: Mediatype, to string: String) -> String {
        "data:\(mediaType.rawValue);base64," + string
    }
}
