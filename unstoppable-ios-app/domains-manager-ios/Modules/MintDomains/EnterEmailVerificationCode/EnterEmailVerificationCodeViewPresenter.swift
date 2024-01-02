//
//  EnterEmailVerificationCodeViewPresenter.swift
//  domains-manager-ios
//
//  Created by Oleg Kuplin on 25.05.2022.
//

import UIKit

@MainActor
protocol EnterEmailVerificationCodeViewPresenterProtocol: BasePresenterProtocol {
    var numberOfCharactersToVerify: Int { get }
    var progress: Double? { get }
    func openEmailButtonPressed()
    func resendCodeButtonPressed()
    func didEnterVerificationCode(_ code: String)
}

@MainActor
class EnterEmailVerificationCodeViewPresenter {
    
    private(set) weak var view: EnterEmailVerificationCodeViewProtocol?
    private(set) var email: String
    private var preFilledCode: String?
    private var secondsLeftToResend = 0
    private var resendTimer: Timer?
    var resendInterval: TimeInterval { 10 }
    var numberOfCharactersToVerify: Int { 6 }
    var progress: Double? { nil }

    init(view: EnterEmailVerificationCodeViewProtocol,
         email: String,
         preFilledCode: String?) {
        self.view = view
        self.email = email
        self.preFilledCode = preFilledCode
    }
    
    func viewDidLoad() {
        Task {
            await MainActor.run {
                view?.setWith(email: email)
                
                if let preFilledCode = self.preFilledCode {
                    view?.setCode(preFilledCode)
                    secondsLeftToResend = -1
                    checkResendStatus()
                } else {
                    startResendTimer()
                }
            }
        }
    }
    
    func viewWillAppear() { }
    func viewDidAppear() { }
    func viewWillDisappear() { }
    func resendCodeAction() { }
    func validateCode(_ code: String) async throws { }
}

// MARK: - EnterEmailVerificationCodeViewPresenterProtocol
extension EnterEmailVerificationCodeViewPresenter: EnterEmailVerificationCodeViewPresenterProtocol {
    func openEmailButtonPressed() {
        view?.openMailApp()
    }
    
    func resendCodeButtonPressed() {
        resendCodeAction()
        startResendTimer()
    }
    
    func didEnterVerificationCode(_ code: String) {
        Task {
            do {
                view?.setLoading(true)
                try await validateCode(code)
            } catch {
                view?.setLoading(false)
                view?.setInvalidCode()
            }
        }
    }
}

// MARK: - Private functions
private extension EnterEmailVerificationCodeViewPresenter {
    @MainActor
    func startResendTimer() {
        stopResendTimer()
        secondsLeftToResend = Int(resendInterval)
        checkResendStatus()
        resendTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            
            self.secondsLeftToResend -= 1
            self.checkResendStatus()
        })
    }
    
    func checkResendStatus() {
        if secondsLeftToResend < 0 {
            view?.setResendCodeButton(enabled: true, secondsLeft: nil)
            stopResendTimer()
        } else {
            view?.setResendCodeButton(enabled: false, secondsLeft: secondsLeftToResend)
        }
    }
    
    func stopResendTimer() {
        resendTimer?.invalidate()
        resendTimer = nil
    }
}
