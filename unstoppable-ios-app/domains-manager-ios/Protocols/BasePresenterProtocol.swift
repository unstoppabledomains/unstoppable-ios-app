//
//  BasePresenterProtocol.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 27.04.2022.
//

import Foundation

protocol BasePresenterProtocol: AnyObject {
    // System actions
    func viewDidLoad()
    func viewWillAppear()
    func viewDidAppear()
    func viewWillDisappear()
    func viewDidDisappear()
    func viewDeinit()
}

extension BasePresenterProtocol {
    func viewDidLoad() { }
    func viewWillAppear() { }
    func viewDidAppear() { }
    func viewWillDisappear() { }
    func viewDidDisappear() { }
    func viewDeinit() { }
}
