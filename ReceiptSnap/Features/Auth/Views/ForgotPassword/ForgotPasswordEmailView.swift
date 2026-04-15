import SwiftUI

struct ForgotPasswordEmailView: View {

    @ObservedObject var viewModel: ForgotPasswordViewModel
    let onCodeSent: (String) -> Void
    let onBack:     () -> Void

    @State private var shakeError = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            BackButton(action: onBack)
                .padding(.top, 16)

            Spacer().frame(height: 28)

            Text("Confirm your email")
                .font(.system(size: AppTheme.Font.largeTitle, weight: .bold))
                .foregroundColor(.rsDeepGreen)

            Spacer().frame(height: 12)

            Text("Enter the email address associated with your account and we'll send a verification code to reset your password.")
                .font(.system(size: AppTheme.Font.body))
                .foregroundColor(.rsTextSecondary)
                .lineSpacing(5)

            Spacer().frame(height: 32)

            CustomTextField(
                placeholder: "Email",
                text: $viewModel.email,
                icon: "envelope",
                keyboardType: .emailAddress,
                contentType: .emailAddress,
                isError: viewModel.emailError != nil,
                errorMessage: viewModel.emailError
            )

            if let msg = viewModel.errorMessage {
                Text(msg)
                    .font(.system(size: AppTheme.Font.body))
                    .foregroundColor(.rsError)
                    .padding(.top, 8)
                    .rsShake(trigger: shakeError)
            }

            Spacer().frame(height: 24)

            PrimaryButton(
                title: "SEND VERIFICATION CODE",
                action: handleSend,
                isLoading: viewModel.isLoading,
                isDisabled: viewModel.email.isEmpty
            )

            Spacer().frame(height: 24)

            HStack(spacing: 4) {
                Text("Remember your password?")
                    .foregroundColor(.rsTextSecondary)
                Button(action: onBack) {
                    Text("Back to Login")
                        .foregroundColor(.rsForestGreen)
                        .fontWeight(.semibold)
                }
            }
            .font(.system(size: AppTheme.Font.body))
            .frame(maxWidth: .infinity)

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
        .dismissKeyboardOnTap()
        .loadingOverlay(isLoading: viewModel.isLoading, message: "Sending code…")
    }

    private func handleSend() {
        Task {
            if await viewModel.sendVerificationCode() {
                onCodeSent(viewModel.email)
            } else {
                withAnimation { shakeError.toggle() }
            }
        }
    }
}

#Preview {
    ForgotPasswordEmailView(viewModel: ForgotPasswordViewModel(), onCodeSent: { _ in }, onBack: {})
}
