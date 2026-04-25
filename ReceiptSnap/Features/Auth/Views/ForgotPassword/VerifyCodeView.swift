import SwiftUI
import Combine

struct VerifyCodeView: View {

    @ObservedObject var viewModel: ForgotPasswordViewModel
    let email:      String
    let onVerified: (String) -> Void  
    let onBack:     () -> Void

    @State private var shakeError = false
    @State private var resendCooldown = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            BackButton(action: onBack)
                .padding(.top, 16)

            Spacer().frame(height: 28)

            Text("Verify code")
                .font(.system(size: AppTheme.Font.largeTitle, weight: .bold))
                .foregroundColor(.rsDeepGreen)

            Spacer().frame(height: 12)

            Text("We've sent a 6-digit code to **\(email)**")
                .font(.system(size: AppTheme.Font.body))
                .foregroundColor(.rsTextSecondary)

            Spacer().frame(height: 36)

            OTPInputField(otp: $viewModel.otpCode)
                .frame(maxWidth: .infinity)

            if let err = viewModel.otpError {
                Text(err)
                    .font(.system(size: AppTheme.Font.caption))
                    .foregroundColor(.rsError)
                    .padding(.top, 8)
                    .rsShake(trigger: shakeError)
            }

            Spacer().frame(height: 32)

            PrimaryButton(
                title: "VERIFY CODE",
                action: handleVerify,
                isLoading: viewModel.isLoading,
                isDisabled: viewModel.otpCode.count < 6
            )

            Spacer().frame(height: 24)

            HStack(spacing: 4) {
                Text("Didn't receive the code?")
                    .foregroundColor(.rsTextSecondary)
                if resendCooldown > 0 {
                    Text("Resend in \(resendCooldown)s")
                        .foregroundColor(.rsTextMuted)
                } else {
                    Button {
                        handleResend()
                    } label: {
                        Text("Resend code")
                            .foregroundColor(.rsForestGreen)
                            .fontWeight(.semibold)
                    }
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
        .loadingOverlay(isLoading: viewModel.isLoading, message: "Verifying…")
        .onReceive(timer) { _ in
            if resendCooldown > 0 { resendCooldown -= 1 }
        }
    }

    private func handleVerify() {
        Task {
            if await viewModel.verifyOTPCode() {
                onVerified(viewModel.otpCode)
            } else {
                withAnimation { shakeError.toggle() }
            }
        }
    }

    private func handleResend() {
        resendCooldown = 30
        Task { _ = await viewModel.resendCode() }
    }
}

#Preview {
    VerifyCodeView(
        viewModel: ForgotPasswordViewModel(),
        email: "user@example.com",
        onVerified: { _ in },
        onBack: {}
    )
}
