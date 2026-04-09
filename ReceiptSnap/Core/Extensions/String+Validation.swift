import Foundation

extension String {

    /// e-mail regex.
    var isValidEmail: Bool {
        let pattern = #"^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: self)
    }

    /// Minimum 8 characters.
    var isValidPassword: Bool { count >= 8 }

    /// At least 8 characters.
    var hasMinLength: Bool { count >= 8 }

    /// Contains at least one digit or common symbol.
    var containsSymbolOrNumber: Bool {
        let pattern = ".*[0-9!@#$%^&*()_+=\\[\\]{};':\"\\\\|,.<>/?\\-].*"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: self)
    }

    /// Contains at least one uppercase letter.
    var containsUppercase: Bool { contains(where: { $0.isUppercase }) }

    /// At least 2 non-whitespace characters.
    var isValidName: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }

    /// Exactly 6 decimal digits.
    var isValidOTP: Bool {
        count == 6 && allSatisfy({ $0.isNumber })
    }

    /// Exactly 6 decimal digits (passcode).
    var isValidPasscode: Bool {
        count == 6 && allSatisfy({ $0.isNumber })
    }
}
