//
//  TxOperation.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 07.12.2023.
//

import Foundation

enum TxOperation: String, Codable {
    case bestowDomain = "BestowDomain"
    case transferDomain = "TransferDomain"
    case recordUpdate = "ResolverRecordsUpdate"
    case setDomainResolver = "SetDomainResolver"
    case deployResolver = "DeployResolver"
    case chainLink = "SetChainlinkOperator"
    case twitterVerification = "SetTwitterVerification"
    case txpAccountFunding = "TxpAccountFunding"
    case vestUserAccount = "VestUserAccount"
    case txpAccountClosing = "TxpAccountClosing"
    case geminiBestowDomain = "GeminiBestowDomain"
    case depositToPolygon = "DepositToPolygon"
    case mintOnDeposit = "MintOnDeposit"
    case mintDomain = "MintDomain"
    case setReverseResolution = "SetReverseResolution"
    case removeReverseResolution = "RemoveReverseResolution"
    case reverseResolutionBackfill = "ReverseResolutionBackfill"
    case mintOnWithdrawal = "MintOnWithdrawal"
    case trackPolygonCheckpoint = "TrackPolygonCheckpoint"
    case withdrawToEthereum = "WithdrawToEthereum"
    case ensRenew = "EnsRenew"
    case ensSetResolver = "ensSetResolver"
    case ensResolverRecordsUpdate = "ensResolverRecordsUpdate"
    
    case bulkIssue = "BulkIssue"
    case approvalForAll = "ApprovalForAll"
    case dotCoinReturn = "DotCoinReturn"
    case unknown = "Unknown"
    case legacy = "Legacy"
    
    // ENS transactions
    case ensCommit = "EnsCommit"
    case ensRegister = "EnsRegister"
    
    public init(from decoder: Decoder) throws {
        let operationRaw = try decoder.singleValueContainer().decode(RawValue.self)
        guard let txOp = TxOperation(rawValue: operationRaw) else {
            Debugger.printFailure("TxOperation has a deprecated or an unknown case: \(operationRaw)", critical: false)
            throw TransactionError.InvalidValue
        }
        self = txOp
    }
}
