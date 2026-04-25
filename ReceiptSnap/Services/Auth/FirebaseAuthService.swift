
import Foundation
import UIKit
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn

final class FirebaseAuthService: AuthServiceProtocol {

    private let auth = Auth.auth()
    private let db   = Firestore.firestore()

    // MARK: - Sign In
    func signIn(email: String, password: String) async throws -> AppUser {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            return try await fetchOrCreateUser(firebaseUser: result.user)
        } catch let err as NSError {
            throw map(err)
        }
    }

    // MARK: - Sign Up
    func signUp(email: String, password: String, displayName: String) async throws -> AppUser {
        do {
            let result = try await auth.createUser(withEmail: email, password: password)

            let req = result.user.createProfileChangeRequest()
            req.displayName = displayName
            try await req.commitChanges()

            let user = AppUser(uid: result.user.uid, email: email, displayName: displayName)
            try? await persist(user)   
            return user
        } catch let err as NSError {
            throw map(err)
        }
    }

    // MARK: - Google Sign-In
    @MainActor
    func signInWithGoogle() async throws -> AppUser {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.unknown("Firebase client ID not found.")
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            throw AuthError.unknown("Cannot find root view controller for Google Sign-In.")
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)

            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.unknown("Failed to retrieve Google ID token.")
            }

            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )

            let authResult = try await auth.signIn(with: credential)
            let appUser = try await fetchOrCreateUser(firebaseUser: authResult.user)

            // Persist/update display name from Google profile if not already stored
            if appUser.displayName == nil, let googleName = result.user.profile?.name {
                let req = authResult.user.createProfileChangeRequest()
                req.displayName = googleName
                try? await req.commitChanges()

                let updatedUser = AppUser(
                    uid:         appUser.uid,
                    email:       appUser.email,
                    displayName: googleName,
                    gender:      appUser.gender
                )
                try? await persist(updatedUser)
                return updatedUser
            }

            return appUser
        } catch let err as AuthError {
            throw err
        } catch {
            let nsErr = error as NSError
            // GIDSignInError domain = "com.google.GIDSignIn", code -5 = user cancelled
            if nsErr.domain == "com.google.GIDSignIn" && nsErr.code == -5 {
                throw AuthError.unknown("Google Sign-In was cancelled.")
            }
            throw AuthError.unknown(nsErr.localizedDescription)
        }
    }

    // MARK: - Sign Out
    func signOut() throws {
        GIDSignIn.sharedInstance.signOut()
        do { try auth.signOut() }
        catch { throw AuthError.unknown(error.localizedDescription) }
    }

    // MARK: - Password Reset
    func sendPasswordReset(email: String) async throws {
        do { try await auth.sendPasswordReset(withEmail: email) }
        catch let err as NSError { throw map(err) }
    }

    func verifyPasswordResetCode(_ code: String) async throws -> String {
        do { return try await auth.verifyPasswordResetCode(code) }
        catch let err as NSError { throw map(err) }
    }

    func confirmPasswordReset(code: String, newPassword: String) async throws {
        do { try await auth.confirmPasswordReset(withCode: code, newPassword: newPassword) }
        catch let err as NSError { throw map(err) }
    }

    // MARK: - Current User
    func getCurrentUser() -> AppUser? {
        guard let u = auth.currentUser else { return nil }
        return AppUser(uid: u.uid, email: u.email ?? "", displayName: u.displayName)
    }

    func addAuthStateListener(completion: @escaping (AppUser?) -> Void) {
        auth.addStateDidChangeListener { _, user in
            if let u = user {
                completion(AppUser(uid: u.uid, email: u.email ?? "", displayName: u.displayName))
            } else {
                completion(nil)
            }
        }
    }

    // MARK: - Private helpers

    private func fetchOrCreateUser(firebaseUser: User) async throws -> AppUser {
        let doc = try? await db.collection("users").document(firebaseUser.uid).getDocument()
        if let data = doc?.data() {
            return AppUser(
                uid:         firebaseUser.uid,
                email:       data["email"] as? String ?? firebaseUser.email ?? "",
                displayName: data["displayName"] as? String ?? firebaseUser.displayName,
                gender:      data["gender"] as? String
            )
        }
        // New user — create Firestore record
        let user = AppUser(
            uid:         firebaseUser.uid,
            email:       firebaseUser.email ?? "",
            displayName: firebaseUser.displayName
        )
        try? await persist(user)
        return user
    }

    private func persist(_ user: AppUser) async throws {
        let data: [String: Any] = [
            "uid":          user.uid,
            "email":        user.email,
            "displayName":  user.displayName ?? "",
            "createdAt":    Timestamp(date: user.createdAt),
            "biometricEnabled": user.biometricEnabled
        ]
        try await db.collection("users").document(user.uid).setData(data, merge: true)
    }

    // MARK: - Error mapping
    private func map(_ error: NSError) -> AuthError {
        switch error.code {
        case 17007: return .emailAlreadyInUse
        case 17004, 17009: return .wrongPassword  
        case 17011: return .userNotFound
        case 17026: return .weakPassword
        case 17008: return .invalidEmail
        case 17020: return .networkError
        default:    return .unknown(error.localizedDescription)
        }
    }
}
