import Foundation

enum AuthRoute: Hashable {
    // Authentication
    case signUp
    case forgotPasswordEmail
    case verifyCode(email: String)
    case createNewPassword(email: String, otpCode: String)
    case passwordUpdated

    // Post-signup
    case accountCreated

    // Biometric setup
    case biometricSetup
    case faceIDScanning
    case biometricSuccess
    case passcodeSetup
    case passcodeSuccess
}
