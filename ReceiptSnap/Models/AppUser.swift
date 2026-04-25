import Foundation

struct AppUser: Equatable, Codable, Sendable {

    let uid: String
    var email: String
    var displayName: String?
    var gender: String?
    let createdAt: Date
    var biometricEnabled: Bool
    var profileImageURL: String?

    init(
        uid: String,
        email: String,
        displayName: String? = nil,
        gender: String?      = nil,
        createdAt: Date      = Date(),
        biometricEnabled: Bool = false,
        profileImageURL: String? = nil
    ) {
        self.uid             = uid
        self.email           = email
        self.displayName     = displayName
        self.gender          = gender
        self.createdAt       = createdAt
        self.biometricEnabled = biometricEnabled
        self.profileImageURL = profileImageURL
    }
    static func == (lhs: AppUser, rhs: AppUser) -> Bool { lhs.uid == rhs.uid }

    var firstName: String {
        displayName?.components(separatedBy: " ").first ?? email.components(separatedBy: "@").first ?? "User"
    }
}
