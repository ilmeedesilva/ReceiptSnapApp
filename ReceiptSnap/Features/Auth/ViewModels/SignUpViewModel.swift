import SwiftUI
import Combine

@MainActor
final class SignUpViewModel: ObservableObject {
    

    // MARK: - Input
    @Published var fullName:         String = ""
    @Published var email:            String = ""
    @Published var gender:           String = ""
    @Published var password:         String = ""
    @Published var confirmPassword:  String = ""
    @Published var agreedToTerms:    Bool   = false

    // MARK: - State
    @Published var isLoading:            Bool    = false
    @Published var errorMessage:         String? = nil
    @Published var nameError:            String? = nil
    @Published var emailError:           String? = nil
    @Published var passwordError:        String? = nil
    @Published var confirmPasswordError: String? = nil

    // MARK: - Options
    let genderOptions = ["Male", "Female", "Non-binary", "Prefer not to say"]

    // MARK: - Computed
    var isSignUpEnabled: Bool {
        !fullName.isEmpty && !email.isEmpty && !password.isEmpty
            && !confirmPassword.isEmpty && agreedToTerms
    }

    var hasMinLength:      Bool { password.count >= 8 }
    var hasSymbolOrNumber: Bool { password.containsSymbolOrNumber }
    var passwordsMatch:    Bool { password == confirmPassword && !password.isEmpty }

    // MARK: - Dependencies
    private let authService: AuthServiceProtocol

    init(authService: AuthServiceProtocol? = nil) {
            self.authService = authService ?? ServiceLocator.shared.authService
        }

    // MARK: - Actions
    func signUp() async -> AppUser? {
        guard validate() else { return nil }

        isLoading    = true
        errorMessage = nil

        do {
            let user = try await authService.signUp(
                email:       email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                password:    password,
                displayName: fullName.trimmingCharacters(in: .whitespacesAndNewlines)
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

    /// Signs up with Google
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
        errorMessage         = nil
        nameError            = nil
        emailError           = nil
        passwordError        = nil
        confirmPasswordError = nil
    }

    // MARK: - Private
    private func validate() -> Bool {
        clearErrors()
        var valid = true

        if fullName.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 {
            nameError = "Please enter your full name"
            valid = false
        }

        if email.isEmpty || !email.isValidEmail {
            emailError = email.isEmpty ? "Email is required" : "Enter a valid email"
            valid = false
        }

        if password.count < 8 {
            passwordError = "Password must be at least 8 characters"
            valid = false
        }

        if password != confirmPassword {
            confirmPasswordError = "Passwords do not match"
            valid = false
        }

        if !agreedToTerms {
            errorMessage = "Please accept the Terms of Service to continue"
            valid = false
        }

        return valid
    }
}
