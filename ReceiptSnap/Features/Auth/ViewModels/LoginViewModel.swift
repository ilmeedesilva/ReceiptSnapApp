import SwiftUI
import Combine

@MainActor
final class LoginViewModel: ObservableObject {

    // MARK: - Input
    @Published var email:    String = ""
    @Published var password: String = ""

    // MARK: - State
    @Published var isLoading:      Bool    = false
    @Published var errorMessage:   String? = nil
    @Published var emailError:     String? = nil
    @Published var passwordError:  String? = nil

    // MARK: - Computed
    var isSignInEnabled: Bool { !email.isEmpty && !password.isEmpty }

    // MARK: - Dependencies
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol = ServiceLocator.shared.authService) {
        self.authService = authService
    }

    // MARK: - Actions
    func signIn() async -> AppUser? {
        guard validate() else { return nil }

        isLoading    = true
        errorMessage = nil

        do {
            let user = try await authService.signIn(
                email:    email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            isLoading = false
            return user
        } catch let err as AuthError {
            errorMessage = err.errorDescription
            isLoading    = false
            return nil
        } catch {
            errorMessage = "An unexpected error occurred."
            isLoading    = false
            return nil
        }
    }

    /// Attempt biometric auto-login using stored email.
    func biometricAutoLogin() async -> AppUser? {
        let biometricService = ServiceLocator.shared.biometricService

        guard biometricService.isBiometricAvailable else {
            errorMessage = "Face ID is not available on this device."
            return nil
        }

        do {
            let authenticated = try await biometricService.authenticate(
                reason: "Authenticate to access ReceiptSnap"
            )
            guard authenticated else { return nil }

            guard let storedEmail = KeychainService.shared.load(for: .lastLoggedEmail) else {
                errorMessage = "No saved account found. Please sign in with email first to enable Face ID."
                return nil
            }

            if let existingUser = ServiceLocator.shared.authService.getCurrentUser() {
                return existingUser
            }

            return AppUser(uid: "biometric-session", email: storedEmail)
        } catch let err as BiometricError {
            if case .userCancelled = err { return nil } 
            errorMessage = err.errorDescription
            return nil
        } catch {
            return nil
        }
    }

    func signInWithGoogle() async -> AppUser? {
        isLoading    = true
        errorMessage = nil
        do {
            let user = try await authService.signInWithGoogle()
            isLoading = false
            return user
        } catch let err as AuthError {
            if case .unknown(let msg) = err, msg.contains("cancelled") {
                isLoading = false
                return nil
            }
            errorMessage = err.errorDescription
            isLoading    = false
            return nil
        } catch {
            errorMessage = "Google sign-in failed. Please try again."
            isLoading    = false
            return nil
        }
    }

    func clearErrors() {
        errorMessage  = nil
        emailError    = nil
        passwordError = nil
    }

    // MARK: - Private
    private func validate() -> Bool {
        emailError    = nil
        passwordError = nil
        var valid = true

        if email.isEmpty {
            emailError = "Email is required"
            valid = false
        } else if !email.isValidEmail {
            emailError = "Please enter a valid email"
            valid = false
        }

        if password.isEmpty {
            passwordError = "Password is required"
            valid = false
        }

        return valid
    }
}
