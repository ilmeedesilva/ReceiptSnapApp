// MockAuthService.swift
// ReceiptSnap — In-memory auth implementation used for development and unit tests.
// Replace with FirebaseAuthService in production (see ServiceLocator.swift).

import Foundation

final class MockAuthService: AuthServiceProtocol {

    // MARK: - Seed data
    private var users: [String: (password: String, user: AppUser)] = [
        "demo@receiptsnap.com": (
            password: "Demo@1234",
            user: AppUser(uid: "demo-uid-001",
                          email: "demo@receiptsnap.com",
                          displayName: "Demo User")
        )
    ]

    // MARK: - Test configuration flags
    var shouldFailNextSignIn  = false
    var shouldFailNextSignUp  = false
    var forcedSignInError: AuthError = .wrongPassword
    var forcedSignUpError: AuthError = .emailAlreadyInUse

    private var authListeners: [(AppUser?) -> Void] = []
    private var currentUser: AppUser?

    // MARK: - AuthServiceProtocol

    func signIn(email: String, password: String) async throws -> AppUser {
        try await simulateLatency()
        if shouldFailNextSignIn {
            shouldFailNextSignIn = false
            throw forcedSignInError
        }
        let key = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard let record = users[key] else { throw AuthError.userNotFound }
        guard record.password == password else { throw AuthError.wrongPassword }
        currentUser = record.user
        notifyListeners()
        return record.user
    }

    func signUp(email: String, password: String, displayName: String) async throws -> AppUser {
        try await simulateLatency()
        if shouldFailNextSignUp {
            shouldFailNextSignUp = false
            throw forcedSignUpError
        }
        let key = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if users[key] != nil { throw AuthError.emailAlreadyInUse }
        let user = AppUser(uid: UUID().uuidString, email: key, displayName: displayName)
        users[key] = (password: password, user: user)
        currentUser = user
        notifyListeners()
        return user
    }

    func signOut() throws {
        currentUser = nil
        notifyListeners()
    }

    func sendPasswordReset(email: String) async throws {
        try await simulateLatency(ms: 400)
        let key = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard users[key] != nil else { throw AuthError.userNotFound }
        // In mock: succeeds silently
    }

    func verifyPasswordResetCode(_ code: String) async throws -> String {
        try await simulateLatency(ms: 300)
        // Accept any 6-digit code except all-zeros
        if code == "000000" { throw AuthError.invalidOTPCode }
        return code
    }

    func confirmPasswordReset(code: String, newPassword: String) async throws {
        try await simulateLatency(ms: 300)
        // In mock: accept and simulate success
    }

    func getCurrentUser() -> AppUser? { currentUser }

    func addAuthStateListener(completion: @escaping (AppUser?) -> Void) {
        authListeners.append(completion)
    }

    @MainActor
    func signInWithGoogle() async throws -> AppUser {
        try await simulateLatency(ms: 800)
        let user = AppUser(uid: "google-mock-\(UUID().uuidString)", email: "google@test.com", displayName: "Google User")
        currentUser = user
        notifyListeners()
        return user
    }

    // MARK: - Helpers
    private func notifyListeners() {
        authListeners.forEach { $0(currentUser) }
    }

    private func simulateLatency(ms: UInt64 = 600) async throws {
        try await Task.sleep(nanoseconds: ms * 1_000_000)
    }
}
