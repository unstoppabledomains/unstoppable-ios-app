//
//  FirebasePurchaseEntities.swift
//  UBTSharing
//
//  Created by Oleg Kuplin on 16.11.2023.
//

import Foundation

// MARK: - Cart entities
extension FirebasePurchaseDomainsService {
    struct UserCartResponse: Codable {
        @DecodeIgnoringFailed
        var cart: [UDProduct]
        
        @DecodeIgnoringFailed
        var removed: [DomainProductItem]
    }

    struct UserCartCalculationsResponse: Codable {
        static let empty = UserCartCalculationsResponse(preTaxAmountDue: 0, totalOrderValue: 0,
                                                        totalAmountDue: 0, promoCreditsUsed: 0,
                                                        storeCreditsUsed: 0, salesTax: 0,
                                                        taxRate: 0, discounts: [],
                                                        timestamp: 0, cartItems: DecodeIgnoringFailed<UDProduct>.init(value: []))
        
        let preTaxAmountDue: Int
        let totalOrderValue: Int
        let totalAmountDue: Int
        let promoCreditsUsed: Int
        let storeCreditsUsed: Int
        let salesTax: Int
        let taxRate: Double
        let discounts: [DiscountDetails] // Assuming discounts are represented as strings
        let timestamp: Int
        @DecodeIgnoringFailed
        var cartItems: [UDProduct]
        
        struct DiscountDetails: Codable {
            let amount: Int
        }
    }

    struct UDUserCart {
        static let empty: UDUserCart = .init(products: [],
                                             calculations: .empty,
                                             discountDetails: .init(storeCredits: 0, promoCredits: 0))
        
        var products: [UDProduct]
        var calculations: UserCartCalculationsResponse
        var discountDetails: DiscountDetails
        
        struct DiscountDetails {
            let storeCredits: Int
            let promoCredits: Int
        }
    }
}

// MARK: - Search entities
extension FirebasePurchaseDomainsService {
    struct SearchDomainsResponse: Codable {
        @DecodeHashableIgnoringFailed
        var exact: [DomainProductItem]
        let searchQuery: String
        let invalidCharacters: [String]
        let invalidReason: String?
    }
    
    struct SuggestDomainsResponse: Codable {
        @DecodeHashableIgnoringFailed
        var suggestions: [DomainProductItem]
    }
}

// MARK: - Product entities
extension FirebasePurchaseDomainsService {
    enum UDProductType: String {
        case domain = "DomainProduct"
        case domainParkOnlySubscription = "DomainParkOnlySubscriptionProduct"
        case ensDomainAutoRenewal = "EnsDomainAutoRenewalProduct"
    }
    
    enum UDProduct: Codable, Hashable, Identifiable {
        case domain(DomainProductItem)
        case parking(DomainProductParking)
        case ensAutoRenewal(DomainProductParking)
        
        var id: String {
            switch self {
            case .domain(let domainProductItem):
                return domainProductItem.id
            case .parking(let domainProductParking), .ensAutoRenewal(let domainProductParking):
                return domainProductParking.id
            }
        }
        
        var price: Int {
            switch self {
            case .domain(let domainProductItem):
                return domainProductItem.fullPrice
            case .parking(let domainProductParking), .ensAutoRenewal(let domainProductParking):
                return domainProductParking.price
            }
        }
        
        enum CodingKeys: CodingKey {
            case productType
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .domain(let product):
                try container.encode(product)
            case .parking(let product), .ensAutoRenewal(let product):
                try container.encode(product)
            }
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let productTypeStr = try container.decode(String.self, forKey: .productType)
            let productType = UDProductType(rawValue: productTypeStr)
            
            switch productType {
            case .domain:
                let domainProduct = try DomainProductItem(from: decoder)
                self = .domain(domainProduct)
            case .domainParkOnlySubscription:
                let parkingProduct = try DomainProductParking(from: decoder)
                self = .parking(parkingProduct)
            case .ensDomainAutoRenewal:
                let parkingProduct = try DomainProductParking(from: decoder)
                self = .ensAutoRenewal(parkingProduct)
            case .none:
                throw NSError()
            }
        }
        
     
    }
    
    struct DomainProductParking: Codable, Hashable, Identifiable {
        var id: String { domain.name + "\(productId ?? 0)" }
        
        let reservedForUserId: String?
        let availability: Bool
        let domain: DomainProductDetails
        let price: Int
        let productId: Int?
        let productType: String
        let productCode: String
        
        static func createENSRenewableProductDetails(for domain: DomainProductDetails) -> DomainProductParking {
            DomainProductParking(reservedForUserId: nil,
                                 availability: true,
                                 domain: domain,
                                 price: 399, // TODO: - Hardcoded
                                 productId: nil,
                                 productType: UDProductType.ensDomainAutoRenewal.rawValue,
                                 productCode: domain.name)
        }
    }
    
    struct DomainProductDetails: Codable, Hashable {
        let name: String
        let label: String
        let sld: String?
        let `extension`: String
    }
    struct ENSDomainProductStatusResponse: Codable, Hashable {
        let expiresAt: Date?
        let isAvailable: Bool
        let rentPrice: Int?
        let registrationFees: Int
    }
    
    struct DomainProductItem: Codable, Hashable, Identifiable {
        var id: String { domain.name + "\(productId ?? 0)" }
        
        let reservedForUserId: String?
        let availability: Bool
        let domain: DomainProductDetails
        let price: Int
        let productId: Int?
        let productType: String
        let productCode: String
        let status: String
        let tags: [String]
        @DecodeHashableIgnoringFailed
        var hiddenProducts: [UDProduct]
        
        
        init(from decoder: any Decoder) throws {
            let container: KeyedDecodingContainer<FirebasePurchaseDomainsService.DomainProductItem.CodingKeys> = try decoder.container(keyedBy: FirebasePurchaseDomainsService.DomainProductItem.CodingKeys.self)
            self.reservedForUserId = try container.decodeIfPresent(String.self, forKey: FirebasePurchaseDomainsService.DomainProductItem.CodingKeys.reservedForUserId)
            self.availability = try container.decode(Bool.self, forKey: FirebasePurchaseDomainsService.DomainProductItem.CodingKeys.availability)
            self.domain = try container.decode(FirebasePurchaseDomainsService.DomainProductDetails.self, forKey: FirebasePurchaseDomainsService.DomainProductItem.CodingKeys.domain)
            self.price = try container.decode(Int.self, forKey: FirebasePurchaseDomainsService.DomainProductItem.CodingKeys.price)
            self.productId = try container.decodeIfPresent(Int.self, forKey: FirebasePurchaseDomainsService.DomainProductItem.CodingKeys.productId)
            self.productType = try container.decode(String.self, forKey: FirebasePurchaseDomainsService.DomainProductItem.CodingKeys.productType)
            self.productCode = try container.decode(String.self, forKey: FirebasePurchaseDomainsService.DomainProductItem.CodingKeys.productCode)
            self.status = try container.decode(String.self, forKey: FirebasePurchaseDomainsService.DomainProductItem.CodingKeys.status)
            self.tags = try container.decode([String].self, forKey: FirebasePurchaseDomainsService.DomainProductItem.CodingKeys.tags)
            if let hiddenProducts = try? container.decode(DecodeHashableIgnoringFailed<FirebasePurchaseDomainsService.UDProduct>.self, forKey: FirebasePurchaseDomainsService.DomainProductItem.CodingKeys.hiddenProducts) {
                self._hiddenProducts = hiddenProducts
            } else {
                self._hiddenProducts = .init(value: [])
            }
        }
        
        // Custom field
        var availableProducts: [UDProduct]?
        var ensStatus: ENSDomainProductStatusResponse?
        
        var fullPrice: Int {
            let productsPrice = hiddenProducts.reduce(0, { $0 + $1.price })
            return price + productsPrice + (ensStatus?.registrationFees ?? 0)
        }
        var isENSDomain: Bool { domain.extension == Constants.ensDomainTLD }
        var isCOMDomain: Bool { domain.extension == Constants.comDomainTLD }
        var isAbleToPurchase: Bool { !isENSDomain && !isCOMDomain }
        
        var hasUDVEnabled: Bool {
            for product in hiddenProducts {
                if case .parking = product {
                    return true
                }
            }
            return false
        }
        
        var isENSRenewalAdded: Bool {
            for product in hiddenProducts {
                switch product {
                case .ensAutoRenewal:
                    return true
                default:
                    continue
                }
            }
            return false
        }
    }
}

// MARK: - Payment entities
extension FirebasePurchaseDomainsService {
    struct StripePaymentDetailsResponse: Codable {
        let clientSecret: String
        let orderId: Int
    }

    struct StripePaymentDetails: Codable {
        let amount: Int
        let clientSecret: String
        let orderId: Int
    }
}

// MARK: - Other
extension FirebasePurchaseDomainsService {
    struct UDUserProfileResponse: Codable {
        let promoCredits: Int
        let referralCode: String
        let storeCredits: Int
        let uid: String
    }
    
    struct UDUserAccountCryptWalletsResponse: Codable {
        @DecodeIgnoringFailed
        var wallets: [UDUserAccountCryptWallet]
    }
    
    struct UDUserAccountCryptWallet: Codable {
        let id: Int
        let address: String
    }
}

