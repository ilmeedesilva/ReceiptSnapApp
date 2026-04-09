import SwiftUI

struct CustomTextField: View {

    // MARK: - Parameters
    var label:           String?
    let placeholder:     String
    @Binding var text:   String
    var icon:            String?              = nil
    var keyboardType:    UIKeyboardType       = .default
    var contentType:     UITextContentType?   = nil
    var autocapitalize:  UITextAutocapitalizationType = .none
    var isError:         Bool                 = false
    var errorMessage:    String?              = nil

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

                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textContentType(contentType)
                    .font(.system(size: AppTheme.Font.bodyLg))
                    .autocapitalization(autocapitalize)
                    .disableAutocorrection(true)
                    .accessibilityLabel(label ?? placeholder)
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
        CustomTextField(label: "Email Address", placeholder: "name@example.com", text: .constant(""), icon: "envelope")
        CustomTextField(placeholder: "Name", text: .constant(""), isError: true, errorMessage: "Name is required")
    }
    .padding()
    .rsScreenBackground()
}
