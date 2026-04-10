import SwiftUI
import Combine
import CoreData

@MainActor
final class AppState: ObservableObject {

    // MARK: - Published state
    @Published var isAuthenticated:            Bool
    @Published var currentUser:                AppUser?
    @Published var pendingUser:                AppUser?
    @Published var hasCompletedOnboarding:     Bool
    @Published var biometricEnabled:           Bool
    @Published var hasCompletedBiometricSetup: Bool

    var userId: String? { currentUser?.uid }

    // MARK: - Keys
    private let kOnboarding   = "rs_onboarding_done"
    private let kBiometric    = "rs_biometric_enabled"
    private let kBioSetupDone = "rs_bio_setup_done"

    init() {
        hasCompletedOnboarding     = UserDefaults.standard.bool(forKey: "rs_onboarding_done")
        biometricEnabled           = UserDefaults.standard.bool(forKey: "rs_biometric_enabled")
        hasCompletedBiometricSetup = UserDefaults.standard.bool(forKey: "rs_bio_setup_done")
        isAuthenticated            = false
        currentUser                = nil
        pendingUser                = nil

        // bypasses login when biometric is enabled
        restoreSessionIfNeeded()
    }

    // MARK: - Onboarding
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: kOnboarding)
    }

    // MARK: - Auth actions
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
        try? ServiceLocator.shared.authService.signOut()
    }

    // MARK: - Biometric
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

    // MARK: - Private
    private func restoreSessionIfNeeded() {

    }
}
