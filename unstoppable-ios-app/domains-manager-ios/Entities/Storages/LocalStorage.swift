//
//  LocalStorage.swift
//  domains-manager-ios
//
//  Created by Roman Medvid on 16.12.2020.
//

import Foundation

public class LocalStorage<T: Codable> {
    
    enum Directory {
        case documents
        case caches
    }
    
    enum LSError: LocalizedError {
        case NoDirectory
        case WriteFailed(String)
        case FileNotFound(String)
        case DecodeFailed(String)
        case ReadFailed(String)
        
        public var errorDescription: String? {
            switch self {
            case .NoDirectory:
                return "No directory"
            case .WriteFailed(let string):
                return "Write failed: \(string)"
            case .FileNotFound(let string):
                return "File not found: \(string)"
            case .DecodeFailed(let string):
                return "Decode failed: \(string)"
            case .ReadFailed(let string):
                return "Read failed: \(string)"
            }
        }
    }
    
    /// Returns URL constructed from specified directory
    fileprivate func getURL(for directory: Directory) -> URL? {
        var searchPathDirectory: FileManager.SearchPathDirectory
        
        switch directory {
        case .documents:
            searchPathDirectory = .documentDirectory
        case .caches:
            searchPathDirectory = .cachesDirectory
        }
        return FileManager.default.urls(for: searchPathDirectory, in: .userDomainMask).first
    }
    
    fileprivate func getFullDir(directory: Directory,
                                       subdirectory: String? = nil,
                                       to fileName: String) -> Result<URL, LSError> {
        guard let baseUrl = getURL(for: directory) else {
            return Result.failure(.NoDirectory)
        }
        var fullDirPath: URL
        if let subDir = subdirectory {
            fullDirPath = baseUrl
                .appendingPathComponent(subDir, isDirectory: true)
                .appendingPathComponent(fileName, isDirectory: false)
        } else {
            fullDirPath = baseUrl.appendingPathComponent(fileName, isDirectory: false)
        }
        return Result.success(fullDirPath)
    }
    
    /// Store an encodable struct to the specified directory on disk
    ///
    /// - Parameters:
    ///   - object: the encodable struct to store
    ///   - directory: where to store the struct
    ///   - fileName: what to name the file where the struct data will be stored
    func store<T: Encodable>(_ object: T,
                                    to directory: Directory,
                                    subdirectory: String? = nil,
                                    to fileName: String) -> LSError? {
        let fullDirPathResult = getFullDir(directory: directory, subdirectory: subdirectory, to: fileName)
        var fullDirPath: URL
        switch fullDirPathResult {
            case .failure(let error):
                return error
            case .success(let url): fullDirPath = url
        }
        
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(object)
            if FileManager.default.fileExists(atPath: fullDirPath.path) {
                try data.write(to: fullDirPath, options: .atomic)
                Debugger.printInfo(topic: .FileSystem, "Written to file \(fullDirPath)")
                return nil
            }
            FileManager.default.createFile(atPath: fullDirPath.path, contents: data, attributes: nil)
            Debugger.printInfo(topic: .FileSystem, "🔶 Created new file \(fullDirPath)")
        } catch {
            return .WriteFailed(error.localizedDescription)
        }
        return nil
    }
    
    /// Retrieve and convert a struct from a file on disk
    ///
    /// - Parameters:
    ///   - fileName: name of the file where struct data is stored
    ///   - directory: directory where struct data is stored
    ///   - type: struct type (i.e. Message.self)
    /// - Returns: decoded struct model(s) of data
    func retrieve<T: Decodable>(_ fileName: String,
                                       from directory: Directory,
                                       subdirectory: String? = nil,
                                       as type: T.Type) -> Result<T, LSError> {
        guard let url = getURL(for: directory)?.appendingPathComponent(fileName, isDirectory: false) else {
            return Result.failure (.NoDirectory)
        }
        
        if !FileManager.default.fileExists(atPath: url.path) {
            return Result.failure(.FileNotFound(url.path))   // fatalError("File at path \(url.path) does not exist!")
        }
        
        if let data = FileManager.default.contents(atPath: url.path) {
            let decoder = JSONDecoder()
            do {
                let model = try decoder.decode(type, from: data)
                Debugger.printInfo(topic: .FileSystem, "Reading from file \(url.path)")
                return Result.success(model)
            } catch {
                return Result.failure(.DecodeFailed(error.localizedDescription))
            }
        } else {
            return Result.failure(.ReadFailed(url.path))
        }
    }
    
    /// Remove all files at specified directory
    func clear(_ directory: Directory) {
        guard let url = getURL(for: directory) else {
            return
        }
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])
            for fileUrl in contents {
                try FileManager.default.removeItem(at: fileUrl)
            }
        } catch {
            Debugger.printFailure ("clear files failed \(error.localizedDescription)")
        }
    }
    
    /// Remove specified file from specified directory
    func remove(_ fileName: String, from directory: Directory) {
        guard let url = getURL(for: directory)?.appendingPathComponent(fileName, isDirectory: false) else {
            return
        }
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                Debugger.printFailure ("removing a file failed \(error.localizedDescription)")
            }
        }
    }
    
    /// Returns BOOL indicating whether file exists at specified directory with specified file name
    func fileExists(_ fileName: String, in directory: Directory) -> Bool {
        guard let url = getURL(for: directory)?.appendingPathComponent(fileName, isDirectory: false) else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
}
