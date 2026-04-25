// AuthServiceProtocol.swift
// ReceiptSnap — Protocol that decouples auth logic from Firebase/any backend.
// ViewModels depend on this protocol; FirebaseAuthService or MockAuthService are injected.

import Foundation

// MARK: - Protocol
protocol AuthServiceProtocol: AnyObject {
    /// Sign in with email and password. Returns authenticated AppUser.
    func signIn(email: String, password: String) async throws -> AppUser

    /// Create a new account. Returns the newly created AppUser.
    func signUp(email: String, password: String, displayName: String) async throws -> AppUser

    /// Sign out the current user.
    func signOut() throws

    /// Send password-reset email.
    func sendPasswordReset(email: String) async throws

    /// Verify an OTP / action code (used in forgot-password flow).
    func verifyPasswordResetCode(_ code: String) async throws -> String

    /// Confirm password reset using the action code.
    func confirmPasswordReset(code: String, newPassword: String) async throws

    /// Return the currently signed-in user, if any.
    func getCurrentUser() -> AppUser?

    /// Listen for auth state changes.
    func addAuthStateListener(completion: @escaping (AppUser?) -> Void)

    /// Sign in (or sign up) with Google. Presents the Google sign-in sheet.
    @MainActor
    func signInWithGoogle() async throws -> AppUser
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case invalidEmail
    case wrongPassword
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case invalidOTPCode
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail:        return "Please enter a valid email address."
        case .wrongPassword:       return "Incorrect password. Please try again."
        case .userNotFound:        return "No account found with this email."
        case .emailAlreadyInUse:   return "An account with this email already exists."
        case .weakPassword:        return "Password must be at least 8 characters."
        case .networkError:        return "Network error. Check your connection."
        case .invalidOTPCode:      return "Invalid verification code. Please try again."
        case .unknown(let msg):    return msg
        }
    }
}
