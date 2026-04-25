// KeychainService.swift
// ReceiptSnap — Secure Keychain wrapper for passcode and session data.

import Foundation
import Security

final class KeychainService {

    static let shared = KeychainService()
    private init() {}

    // MARK: - Keys
    enum Key: String, CaseIterable {
        case passcode        = "rs.passcode"
        case lastLoggedEmail = "rs.lastEmail"
        case autoLoginToken  = "rs.autoLogin"
    }

    // MARK: - Save
    @discardableResult
    func save(_ value: String, for key: Key) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue,
            kSecValueData:   data
        ]
        SecItemDelete(query as CFDictionary)
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    // MARK: - Load
    func load(for key: Key) -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Delete
    @discardableResult
    func delete(for key: Key) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key.rawValue
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }

    // MARK: - Clear all app data
    func clearAll() {
        Key.allCases.forEach { delete(for: $0) }
    }

    // MARK: - Passcode helpers
    @discardableResult
    func savePasscode(_ code: String) -> Bool { save(code, for: .passcode) }

    func verifyPasscode(_ code: String) -> Bool {
        guard let saved = load(for: .passcode) else { return false }
        return saved == code
    }

    func hasPasscode() -> Bool { load(for: .passcode) != nil }
}
