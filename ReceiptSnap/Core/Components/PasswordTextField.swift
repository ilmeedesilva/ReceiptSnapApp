import SwiftUI

struct PasswordTextField: View {

    // MARK: - Parameters
    var label:           String?
    let placeholder:     String
    @Binding var text:   String
    var icon:            String?  = "lock.fill"
    var isError:         Bool     = false
    var errorMessage:    String?  = nil

    @State private var isSecure = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let label {
                Text(label)
                    .font(.system(size: AppTheme.Font.body, weight: .medium))
                    .foregroundColor(.rsTextSecondary)
            }

            HStack(spacing: 10) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundColor(.rsTextSecondary)
                        .frame(width: 20)
                        .accessibilityHidden(true)
                }

                Group {
                    if isSecure {
                        SecureField(placeholder, text: $text)
                    } else {
                        TextField(placeholder, text: $text)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                }
                .font(.system(size: AppTheme.Font.bodyLg))
                .accessibilityLabel(label ?? placeholder)

                Button {
                    isSecure.toggle()
                } label: {
                    Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.rsTextMuted)
                }
                .accessibilityLabel(isSecure ? "Show password" : "Hide password")
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .frame(height: AppTheme.Height.input)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .stroke(isError ? Color.rsError : Color.rsBorder, lineWidth: 1)
            )
            .cornerRadius(AppTheme.Radius.md)

            if isError, let msg = errorMessage {
                Text(msg)
                    .font(.system(size: AppTheme.Font.caption))
                    .foregroundColor(.rsError)
                    .padding(.leading, 4)
                    .accessibilityLabel("Error: \(msg)")
            }
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        PasswordTextField(label: "Password", placeholder: "Enter password", text: .constant("secret"))
        PasswordTextField(placeholder: "Confirm Password", text: .constant(""), isError: true, errorMessage: "Passwords do not match")
    }
    .padding()
}
