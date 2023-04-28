//
//  MockDomainTransferService.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.04.2023.
//

import Foundation

final class MockDomainTransferService { }

extension MockDomainTransferService: DomainTransferServiceProtocol {
    func transferDomain(domain: DomainItem,
                        to receiverAddress: HexAddress,
                        configuration: TransferDomainConfiguration,
                        paymentConfirmationDelegate: PaymentConfirmationDelegate) async throws { }
}
