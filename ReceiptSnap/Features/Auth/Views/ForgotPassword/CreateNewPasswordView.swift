import SwiftUI

struct CreateNewPasswordView: View {

    @ObservedObject var viewModel: ForgotPasswordViewModel
    let onPasswordReset: () -> Void
    let onBack:          () -> Void

    @State private var shakeError = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            BackButton(action: onBack)
                .padding(.top, 16)

            Spacer().frame(height: 28)

            Text("Create Your New\nPassword")
                .font(.system(size: AppTheme.Font.largeTitle, weight: .bold))
                .foregroundColor(.rsDeepGreen)

            Spacer().frame(height: 12)

            Text("Your new password must be different from your previous password.")
                .font(.system(size: AppTheme.Font.body))
                .foregroundColor(.rsTextSecondary)
                .lineSpacing(5)

            Spacer().frame(height: 32)

            VStack(spacing: AppTheme.Spacing.md) {
                PasswordTextField(
                    placeholder: "Password",
                    text: $viewModel.newPassword,
                    isError: viewModel.newPasswordError != nil,
                    errorMessage: viewModel.newPasswordError
                )

                PasswordTextField(
                    placeholder: "Confirm Password",
                    text: $viewModel.confirmNewPassword,
                    icon: "lock.rotation",
                    isError: viewModel.confirmPasswordError != nil,
                    errorMessage: viewModel.confirmPasswordError
                )

                VStack(alignment: .leading, spacing: 8) {
                    validationRow(
                        label: "Must not contain your name or email",
                        met: !viewModel.newPassword.isEmpty
                    )
                    validationRow(
                        label: "At least 8 characters",
                        met: viewModel.hasMinLength
                    )
                    validationRow(
                        label: "Contains a symbol or a number",
                        met: viewModel.hasSymbolOrNumber
                    )
                }
                .padding(.vertical, 4)

                if let msg = viewModel.errorMessage {
                    Text(msg)
                        .font(.system(size: AppTheme.Font.body))
                        .foregroundColor(.rsError)
                        .rsShake(trigger: shakeError)
                }

                PrimaryButton(
                    title: "RESET PASSWORD",
                    action: handleReset,
                    isLoading: viewModel.isLoading,
                    isDisabled: viewModel.newPassword.isEmpty || viewModel.confirmNewPassword.isEmpty
                )
            }

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
        .dismissKeyboardOnTap()
        .loadingOverlay(isLoading: viewModel.isLoading, message: "Resetting password…")
    }

    private func handleReset() {
        Task {
            if await viewModel.resetPassword() {
                onPasswordReset()
            } else {
                withAnimation { shakeError.toggle() }
            }
        }
    }

    private func validationRow(label: String, met: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundColor(met ? .rsMediumGreen : .rsTextMuted)
                .font(.system(size: 16))
            Text(label)
                .font(.system(size: AppTheme.Font.body))
                .foregroundColor(met ? .rsTextPrimary : .rsTextMuted)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(met ? "met" : "not met")")
    }
}

#Preview {
    CreateNewPasswordView(
        viewModel: ForgotPasswordViewModel(),
        onPasswordReset: {},
        onBack: {}
    )
}
