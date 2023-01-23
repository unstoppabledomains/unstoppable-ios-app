//
//  BaseTableViewPresenterProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2022.
//

import UIKit

protocol BaseTableViewPresenterProtocol: BasePresenterProtocol {
    var numberOfSections: Int { get }
    func numberOfRowsInSection(_ section: Int) -> Int
    func heightForRowAtIndexPath(_ indexPath: IndexPath) -> CGFloat
    func estimatedHeightForRowAtIndexPath(_ indexPath: IndexPath) -> CGFloat
    func heightForHeaderIn(section: Int) -> CGFloat
    func heightForFooterIn(section: Int) -> CGFloat
}

extension BaseTableViewPresenterProtocol {
    var numberOfSections: Int { 1 }
    func estimatedHeightForRowAtIndexPath(_ indexPath: IndexPath) -> CGFloat { .leastNormalMagnitude }
    func heightForHeaderIn(section: Int) -> CGFloat { .leastNormalMagnitude }
    func heightForFooterIn(section: Int) -> CGFloat { .leastNormalMagnitude }
}
