//
//  Error.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 01.09.2023.
//

import Foundation

extension Error {
    
    var titleAndMessage: (title: String, message: String) {
        var message: String
        let title: String
        
        if self is TransactionError {
            title = String.Constants.transactionFailed.localized()
            message = String.Constants.pleaseTryAgain.localized()
        } else if let networkError = self as? NetworkLayerError,
                  case .notConnectedToInternet = networkError {
            title = String.Constants.connectionLost.localized()
            message = String.Constants.pleaseCheckInternetConnection.localized()
        } else if let jrpcError = self as? NetworkService.JRPCError {
            switch jrpcError {
            case .failedFetchInfuraGasPrices:
                title = String.Constants.gasFeeFailed.localized()
                message = String.Constants.pleaseTryAgain.localized()
            case .failedFetchNonce:
                title = String.Constants.nonceFailed.localized()
                message = String.Constants.pleaseTryAgain.localized()
            default: title = String.Constants.somethingWentWrong.localized()
                    message = String.Constants.pleaseTryAgain.localized()
            }
        } else if let mpcError = self as? MPCWalletError,
                  case .messageSignDisabled = mpcError {
            title = String.Constants.mpcWalletSigningUnavailableErrorMessage.localizedMPCProduct()
            message = String.Constants.tryAgainLater.localized()
        } else if let mpcError = self as? MPCWalletError,
                  case .maintenanceEnabled = mpcError {
            title = String.Constants.mpcMaintenanceMessageTitle.localizedMPCProduct()
            message = String.Constants.mpcMaintenanceMessageSubtitle.localized()
        } else {
            title = String.Constants.somethingWentWrong.localized()
            message = String.Constants.pleaseTryAgain.localized()
        }
        
#if DEBUG
        message = self.localizedDescription
#endif
        
        return (title, message)
    }
    
    func isNetworkError(withCode code: Int) -> Bool {
        if let networkError = self as? NetworkLayerError,
           case .badResponseOrStatusCode(let errorCode, _, _) = networkError,
           errorCode == code {
            return true
        }
        return false
    }
    
}
