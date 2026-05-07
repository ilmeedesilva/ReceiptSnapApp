import SwiftUI
import Combine
import CoreData

@MainActor
final class AppState: ObservableObject {

    @Published var isAuthenticated:            Bool
    @Published var currentUser:                AppUser?
    @Published var pendingUser:                AppUser?
    @Published var hasCompletedOnboarding:     Bool
    @Published var biometricEnabled:           Bool
    @Published var hasCompletedBiometricSetup: Bool

    var userId: String? { currentUser?.uid }

    private let kBiometric    = "rs_biometric_enabled"
    private let kBioSetupDone = "rs_bio_setup_done"

    init() {
        hasCompletedOnboarding     = false
        biometricEnabled           = UserDefaults.standard.bool(forKey: "rs_biometric_enabled")
        hasCompletedBiometricSetup = UserDefaults.standard.bool(forKey: "rs_bio_setup_done")
        isAuthenticated            = false
        currentUser                = nil
        pendingUser                = nil

        restoreSessionIfNeeded()
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    func signIn(user: AppUser) {
        currentUser     = user
        pendingUser     = nil
        isAuthenticated = true
        KeychainService.shared.save(user.email, for: .lastLoggedEmail)
    }

    func setPendingUser(_ user: AppUser) {
        pendingUser = user
    }

    func signOut() {
        currentUser     = nil
        pendingUser     = nil
        isAuthenticated = false
        hasCompletedOnboarding = false
        try? ServiceLocator.shared.authService.signOut()
    }

    func enableBiometric() {
        biometricEnabled           = true
        hasCompletedBiometricSetup = true
        UserDefaults.standard.set(true, forKey: kBiometric)
        UserDefaults.standard.set(true, forKey: kBioSetupDone)
    }

    func skipBiometricSetup() {
        hasCompletedBiometricSetup = true
        UserDefaults.standard.set(true, forKey: kBioSetupDone)
    }

    private func restoreSessionIfNeeded() {
        if let existingUser = ServiceLocator.shared.authService.getCurrentUser() {
            currentUser = existingUser
            isAuthenticated = true
        }
    }
}