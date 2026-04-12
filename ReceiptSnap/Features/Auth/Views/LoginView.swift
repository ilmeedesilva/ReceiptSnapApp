import SwiftUI

struct LoginView: View {

    // MARK: - Dependencies
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: LoginViewModel
    let onNavigate: (AuthRoute) -> Void

    // MARK: - Local state
    @State private var shakeError = false
    @State private var shakeBiometricError = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.rsForestGreen)

                    Text("ReceiptSnap")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color.rsDeepGreen)

                    Text("Unlock your digital wallet")
                        .font(.system(size: AppTheme.Font.body))
                        .foregroundColor(Color.rsTextSecondary)
                }
                .padding(.top, 52)
                .padding(.bottom, 32)

                VStack(spacing: 8) {
                    PrimaryButton(
                        title: "Unlock with Face ID",
                        action: handleFaceIDLogin,
                        isLoading: viewModel.isLoading,
                        background: .rsDeepGreen
                    )
                    .padding(.horizontal, AppTheme.Spacing.xl)

                    if let msg = viewModel.errorMessage, !viewModel.isLoading,
                       msg.contains("Face ID") || msg.contains("account") || msg.contains("saved") {
                        Text(msg)
                            .font(.system(size: AppTheme.Font.caption))
                            .foregroundColor(.rsError)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.xl)
                            .rsShake(trigger: shakeBiometricError)
                    }

                    if !appState.biometricEnabled {
                        Button {
                            onNavigate(.biometricSetup)
                        } label: {
                            Text("Face ID not enabled? ")
                                .foregroundColor(.rsTextSecondary)
                            + Text("Set it up now")
                                .foregroundColor(.rsForestGreen)
                                .underline()
                        }
                        .font(.system(size: AppTheme.Font.body))
                    }
                }

                divider("OR CONTINUE WITH")

                VStack(spacing: AppTheme.Spacing.md) {
                    CustomTextField(
                        label: "Email Address",
                        placeholder: "name@example.com",
                        text: $viewModel.email,
                        icon: "envelope",
                        keyboardType: .emailAddress,
                        contentType: .emailAddress,
                        isError: viewModel.emailError != nil,
                        errorMessage: viewModel.emailError
                    )

                    PasswordTextField(
                        label: "Password",
                        placeholder: "••••••••",
                        text: $viewModel.password,
                        isError: viewModel.passwordError != nil,
                        errorMessage: viewModel.passwordError
                    )

                    if let msg = viewModel.errorMessage,
                       !msg.contains("Face ID") && !msg.contains("saved") {
                        Text(msg)
                            .font(.system(size: AppTheme.Font.body))
                            .foregroundColor(.rsError)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .rsShake(trigger: shakeError)
                    }

                    PrimaryButton(
                        title: "Sign In",
                        action: handleSignIn,
                        isLoading: viewModel.isLoading,
                        isDisabled: !viewModel.isSignInEnabled
                    )

                    Button {
                        onNavigate(.forgotPasswordEmail)
                    } label: {
                        Text("FORGOT PASSWORD")
                            .font(.system(size: AppTheme.Font.body, weight: .semibold))
                            .foregroundColor(.rsForestGreen)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, AppTheme.Spacing.xl)

                divider("OR CONTINUE WITH")

                HStack(spacing: 12) {
                    SocialLoginButton(title: "Google", icon: "globe") {
                        handleGoogleSignIn()
                    }
                    SocialLoginButton(title: "Apple", icon: "apple.logo") {
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xl)

                signUpLink
                    .padding(.top, 24)

                #if DEBUG
                Button {
                    appState.signIn(user: AppUser(
                        uid:         "dev-preview",
                        email:       "dev@receiptsnap.com",
                        displayName: "Dev User"
                    ))
                } label: {
                    Text("Skip to Dashboard (Dev)")
                        .font(.system(size: AppTheme.Font.caption, weight: .medium))
                        .foregroundColor(.rsTextMuted)
                        .underline()
                }
                .padding(.top, 4)
                #endif

                Spacer().frame(height: 40)
            }
        }
        .rsScreenBackground()
        .navigationBarHidden(true)
        .dismissKeyboardOnTap()
        .loadingOverlay(isLoading: viewModel.isLoading, message: "Signing in…")
    }

    // MARK: - Actions
    private func handleSignIn() {
        Task {
            if let user = await viewModel.signIn() {
                appState.signIn(user: user)
            } else {
                withAnimation(.default) { shakeError.toggle() }
            }
        }
    }

    private func handleFaceIDLogin() {
        Task {
            if let user = await viewModel.biometricAutoLogin() {
                appState.signIn(user: user)
            } else if viewModel.errorMessage != nil {
                withAnimation(.default) { shakeBiometricError.toggle() }
            }
        }
    }

    private func handleGoogleSignIn() {
        Task {
            if let user = await viewModel.signInWithGoogle() {
                appState.signIn(user: user)
            }
        }
    }

    // MARK: - Sub-views
    private func divider(_ label: String) -> some View {
        HStack(spacing: 12) {
            Rectangle().fill(Color.rsBorder).frame(height: 1)
            Text(label)
                .font(.system(size: AppTheme.Font.caption, weight: .medium))
                .foregroundColor(.rsTextMuted)
                .fixedSize()
            Rectangle().fill(Color.rsBorder).frame(height: 1)
        }
        .padding(.horizontal, AppTheme.Spacing.xl)
        .padding(.vertical, AppTheme.Spacing.lg)
    }

    private var signUpLink: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .foregroundColor(.rsTextSecondary)
            Button {
                onNavigate(.signUp)
            } label: {
                Text("Create an account")
                    .foregroundColor(.rsForestGreen)
                    .fontWeight(.semibold)
            }
        }
        .font(.system(size: AppTheme.Font.body))
    }
}

#Preview {
    LoginView(viewModel: LoginViewModel(), onNavigate: { _ in })
        .environmentObject(AppState())
}
