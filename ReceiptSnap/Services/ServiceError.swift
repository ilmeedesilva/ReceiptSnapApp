
import Foundation

enum ServiceError: LocalizedError {

    case networkError(String)
    case invalidInput(String)
    case notFound
    case permissionDenied
    case storageError(String)
    case ocrFailed
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let msg):  return "Network error: \(msg)"
        case .invalidInput(let msg):  return msg
        case .notFound:               return "The requested item could not be found."
        case .permissionDenied:       return "You don't have permission to perform this action."
        case .storageError(let msg):  return "Storage error: \(msg)"
        case .ocrFailed:              return "Could not read receipt text. Please enter details manually."
        case .unknown(let msg):       return msg
        }
    }
}
