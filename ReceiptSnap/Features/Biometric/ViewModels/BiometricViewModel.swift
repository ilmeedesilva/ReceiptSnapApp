import SwiftUI
import LocalAuthentication
import Combine

@MainActor
final class BiometricViewModel: ObservableObject {

    @Published var isAuthenticating: Bool   = false
    @Published var authSuccess:      Bool   = false
    @Published var errorMessage:     String? = nil

    // MARK: - Passcode flow
    @Published var passcodeDigits:  String  = ""   // current step input
    @Published var passcodeConfirm: String  = ""   // confirmation step input
    @Published var passcodeStep:    PasscodeStep = .create
    @Published var passcodeError:   String? = nil
    @Published var passcodeSuccess: Bool    = false

    enum PasscodeStep { case create, confirm }

    // MARK: - Computed
    var biometricType:         BiometricType { biometricService.biometricType }
    var isBiometricAvailable:  Bool          { biometricService.isBiometricAvailable }

    // MARK: - Dependencies
    private let biometricService: BiometricServiceProtocol
    private let keychain: KeychainService

    init(
        biometricService: BiometricServiceProtocol = ServiceLocator.shared.biometricService,
        keychain: KeychainService = KeychainService.shared
    ) {
        self.biometricService = biometricService
        self.keychain         = keychain
    }

    // MARK: - Biometric Authentication

    /// Triggers the system Face ID / Touch ID prompt.
    func authenticateWithBiometrics() async -> Bool {
        isAuthenticating = true
        errorMessage     = nil

        do {
            let ok = try await biometricService.authenticate(
                reason: "Authenticate to access ReceiptSnap"
            )
            isAuthenticating = false
            authSuccess      = ok
            return ok
        } catch let err as BiometricError {
            errorMessage     = err.errorDescription
            isAuthenticating = false
            return false
        } catch {
            errorMessage     = "Authentication failed."
            isAuthenticating = false
            return false
        }
    }

    // MARK: - Passcode Setup

    func appendDigit(_ digit: String) {
        passcodeError = nil
        switch passcodeStep {
        case .create:
            guard passcodeDigits.count < 6 else { return }
            passcodeDigits.append(contentsOf: digit)
        case .confirm:
            guard passcodeConfirm.count < 6 else { return }
            passcodeConfirm.append(contentsOf: digit)
        }
    }

    func deleteDigit() {
        switch passcodeStep {
        case .create:  if !passcodeDigits.isEmpty  { passcodeDigits.removeLast() }
        case .confirm: if !passcodeConfirm.isEmpty { passcodeConfirm.removeLast() }
        }
    }

    /// Advances from create → confirm, or finalises passcode. Returns true when saved.
    @discardableResult
    func advancePasscode() -> Bool {
        switch passcodeStep {
        case .create:
            guard passcodeDigits.count == 6 else {
                passcodeError = "Enter a 6-digit passcode"
                return false
            }
            passcodeStep = .confirm
            return false

        case .confirm:
            guard passcodeConfirm == passcodeDigits else {
                passcodeError   = "Passcodes don't match. Try again."
                passcodeConfirm = ""
                return false
            }
            keychain.savePasscode(passcodeDigits)
            passcodeSuccess = true
            return true
        }
    }

    func resetPasscode() {
        passcodeDigits  = ""
        passcodeConfirm = ""
        passcodeStep    = .create
        passcodeError   = nil
        passcodeSuccess = false
    }

    func verifyPasscode(_ code: String) -> Bool {
        keychain.verifyPasscode(code)
    }
}

