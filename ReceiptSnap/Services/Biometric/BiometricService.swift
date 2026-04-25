
import LocalAuthentication
import Foundation

enum BiometricType {
    case faceID, touchID, none

    var displayName: String {
        switch self {
        case .faceID:  return "Face ID"
        case .touchID: return "Touch ID"
        case .none:    return "Biometrics"
        }
    }

    var systemImage: String {
        switch self {
        case .faceID:  return "faceid"
        case .touchID: return "touchid"
        case .none:    return "lock.fill"
        }
    }
}

protocol BiometricServiceProtocol {
    var biometricType: BiometricType { get }
    var isBiometricAvailable: Bool   { get }
    func authenticate(reason: String) async throws -> Bool
}

enum BiometricError: LocalizedError {
    case notAvailable
    case notEnrolled
    case lockout
    case userCancelled
    case failed
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable:  return "Biometric authentication is not available on this device."
        case .notEnrolled:   return "No biometric data enrolled. Set up Face ID in Settings."
        case .lockout:       return "Too many attempts. Use your passcode."
        case .userCancelled: return "Authentication was cancelled."
        case .failed:        return "Authentication failed. Please try again."
        case .unknown(let m): return m
        }
    }
}

final class BiometricService: BiometricServiceProtocol {

    var biometricType: BiometricType {
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
            return .none
        }
        switch ctx.biometryType {
        case .faceID:  return .faceID
        case .touchID: return .touchID
        default:       return .none
        }
    }

    var isBiometricAvailable: Bool {
        var err: NSError?
        return LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err)
    }

    func authenticate(reason: String) async throws -> Bool {
        let ctx = LAContext()
        var err: NSError?
        guard ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) else {
            guard let err else { throw BiometricError.notAvailable }
            switch err.code {
            case LAError.biometryNotAvailable.rawValue: throw BiometricError.notAvailable
            case LAError.biometryNotEnrolled.rawValue:  throw BiometricError.notEnrolled
            default: throw BiometricError.unknown(err.localizedDescription)
            }
        }
        do {
            return try await ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics,
                                                localizedReason: reason)
        } catch let laErr as LAError {
            switch laErr.code {
            case .userCancel:     throw BiometricError.userCancelled
            case .biometryLockout: throw BiometricError.lockout
            default:              throw BiometricError.failed
            }
        }
    }
}

final class MockBiometricService: BiometricServiceProtocol {
    var biometricType: BiometricType = .faceID
    var isBiometricAvailable: Bool   = true
    var shouldSucceed = true
    var shouldThrow: BiometricError? = nil

    func authenticate(reason: String) async throws -> Bool {
        if let err = shouldThrow { throw err }
        return shouldSucceed
    }
}
