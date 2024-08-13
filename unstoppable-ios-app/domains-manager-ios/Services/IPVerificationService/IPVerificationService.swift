//
//  IPVerificationService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 13.08.2024.
//

import Foundation

final class IPVerificationService { }

// MARK: - Open methods
extension IPVerificationService: IPVerificationServiceProtocol {
    func isUserInTheUS() async throws -> Bool {
        let countryName = try await getCountryNameForCurrentIP()
        let usCountryName = "United States"
        
        return countryName == usCountryName
    }
}

// MARK: - Private methods
private extension IPVerificationService {
    func getCountryNameForCurrentIP() async throws -> String {
        let ip = try await getCurrentIP()
        let countryName = try await getCountryNameFor(ip: ip)
        return countryName
    }
    
    func getCurrentIP() async throws -> String {
        struct Response: Codable {
            let ip: String
        }
        
        let url = "https://api.ipify.org/?format=json"
        let data = try await getDataFrom(url: url)
        let response: Response = try Response.objectFromDataThrowing(data)
        
        return response.ip
    }
    
    func getCountryNameFor(ip: String) async throws -> String {
        let url = "https://ipapi.co/\(ip)/country_name/"
        let data = try await getDataFrom(url: url)
        
        guard let countryName = String(data: data, encoding: .utf8) else { throw IPVerificationServiceError.failedToParseCountryName }
        
        return countryName
    }
    
    func getDataFrom(url: String) async throws -> Data {
        let url = URL(string: url)!
        let request = URLRequest(url: url)
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
    
    enum IPVerificationServiceError: String, LocalizedError {
        case failedToParseCountryName
        
        public var errorDescription: String? {
            return rawValue
        }
    }
}
