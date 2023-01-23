//
//  BaseCollectionViewPresenterProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2022.
//

import UIKit

protocol BaseCollectionViewPresenterProtocol: BasePresenterProtocol {
    var numberOfSections: Int { get }
    func numberOfItemsInSection(_ section: Int) -> Int
}

extension BaseCollectionViewPresenterProtocol {
    var numberOfSections: Int { 1 }
}
