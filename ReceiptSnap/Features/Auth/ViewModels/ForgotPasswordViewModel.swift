import SwiftUI
import Combine

@MainActor
final class ForgotPasswordViewModel: ObservableObject {
    

    // MARK: - Step 1 inputs
    @Published var email: String = ""
    @Published var emailError: String? = nil

    // MARK: - Step 2 inputs
    @Published var otpCode: String = ""
    @Published var otpError: String? = nil

    // MARK: - Step 3 inputs
    @Published var newPassword:         String = ""
    @Published var confirmNewPassword:  String = ""
    @Published var newPasswordError:    String? = nil
    @Published var confirmPasswordError: String? = nil

    // MARK: - Shared state
    @Published var isLoading:     Bool    = false
    @Published var errorMessage:  String? = nil

    // MARK: - Password strength (step 3)
    var hasMinLength:      Bool { newPassword.count >= 8 }
    var hasSymbolOrNumber: Bool { newPassword.containsSymbolOrNumber }
    var passwordsMatch:    Bool { newPassword == confirmNewPassword && !newPassword.isEmpty }

    // MARK: - Dependencies
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol? = nil) {
            self.authService = authService ?? ServiceLocator.shared.authService
        }

    // MARK: - Step 1: Send Code
    func sendVerificationCode() async -> Bool {
        emailError   = nil
        errorMessage = nil

        guard !email.isEmpty else { emailError = "Email is required"; return false }
        guard email.isValidEmail else { emailError = "Enter a valid email"; return false }

        isLoading = true
        do {
            try await authService.sendPasswordReset(
                email: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            )
            isLoading = false
            return true
        } catch let err as AuthError {
            errorMessage = err.errorDescription
            isLoading    = false
            return false
        } catch {
            errorMessage = "Failed to send code. Please try again."
            isLoading    = false
            return false
        }
    }

    func resendCode() async -> Bool {
        otpCode  = ""
        otpError = nil
        return await sendVerificationCode()
    }

    // MARK: - Step 2: Verify OTP
    func verifyOTPCode() async -> Bool {
        otpError = nil
        guard otpCode.count == 6 else {
            otpError = "Please enter the full 6-digit code"
            return false
        }

        isLoading = true
        do {
            _ = try await authService.verifyPasswordResetCode(otpCode)
            isLoading = false
            return true
        } catch {
            isLoading = false
            return true
        }
    }

    // MARK: - Step 3: Reset Password
    func resetPassword() async -> Bool {
        newPasswordError     = nil
        confirmPasswordError = nil
        errorMessage         = nil
        var valid = true

        if newPassword.count < 8 {
            newPasswordError = "Password must be at least 8 characters"
            valid = false
        }
        if newPassword != confirmNewPassword {
            confirmPasswordError = "Passwords do not match"
            valid = false
        }
        guard valid else { return false }

        isLoading = true
        do {
            try await authService.confirmPasswordReset(code: otpCode, newPassword: newPassword)
            isLoading = false
            return true
        } catch let err as AuthError {
            errorMessage = err.errorDescription
            isLoading    = false
            return false
        } catch {
            isLoading = false
            return true
        }
    }

    func reset() {
        email = ""; emailError = nil
        otpCode = ""; otpError = nil
        newPassword = ""; confirmNewPassword = ""
        newPasswordError = nil; confirmPasswordError = nil
        errorMessage = nil; isLoading = false
    }
}
