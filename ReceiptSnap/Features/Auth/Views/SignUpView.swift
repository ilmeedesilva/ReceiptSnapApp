import SwiftUI

struct SignUpView: View {

    // MARK: - Dependencies
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: SignUpViewModel
    let onBack:        () -> Void
    let onSignUpSuccess: (AppUser) -> Void

    @State private var showGenderPicker = false
    @State private var shakeError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                BackButton(action: onBack)
                    .padding(.top, 16)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Sign up")
                        .font(.system(size: AppTheme.Font.largeTitle, weight: .bold))
                        .foregroundColor(.rsDeepGreen)
                    Text("Fill and sign up")
                        .font(.system(size: AppTheme.Font.body))
                        .foregroundColor(.rsTextSecondary)
                }
                .padding(.top, 8)
                .padding(.bottom, 28)

                VStack(spacing: AppTheme.Spacing.md) {
                    CustomTextField(
                        placeholder: "Name",
                        text: $viewModel.fullName,
                        icon: "person.fill",
                        contentType: .name,
                        autocapitalize: .words,
                        isError: viewModel.nameError != nil,
                        errorMessage: viewModel.nameError
                    )

                    CustomTextField(
                        placeholder: "Email",
                        text: $viewModel.email,
                        icon: "envelope.fill",
                        keyboardType: .emailAddress,
                        contentType: .emailAddress,
                        isError: viewModel.emailError != nil,
                        errorMessage: viewModel.emailError
                    )

                    Button {
                        showGenderPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.rsTextSecondary)
                                .frame(width: 20)
                            Text(viewModel.gender.isEmpty ? "Gender" : viewModel.gender)
                                .foregroundColor(viewModel.gender.isEmpty ? .rsTextMuted : .rsTextPrimary)
                                .font(.system(size: AppTheme.Font.bodyLg))
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.rsTextMuted)
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .frame(height: AppTheme.Height.input)
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                .stroke(Color.rsBorder, lineWidth: 1)
                        )
                        .cornerRadius(AppTheme.Radius.md)
                    }
                    .confirmationDialog("Select Gender", isPresented: $showGenderPicker) {
                        ForEach(viewModel.genderOptions, id: \.self) { option in
                            Button(option) { viewModel.gender = option }
                        }
                        Button("Cancel", role: .cancel) {}
                    }

                    PasswordTextField(
                        placeholder: "Password",
                        text: $viewModel.password,
                        isError: viewModel.passwordError != nil,
                        errorMessage: viewModel.passwordError
                    )

                    if !viewModel.password.isEmpty {
                        passwordStrengthRow
                    }

                    PasswordTextField(
                        placeholder: "Confirm password",
                        text: $viewModel.confirmPassword,
                        icon: "lock.rotation",
                        isError: viewModel.confirmPasswordError != nil,
                        errorMessage: viewModel.confirmPasswordError
                    )

                    if let msg = viewModel.errorMessage {
                        Text(msg)
                            .font(.system(size: AppTheme.Font.body))
                            .foregroundColor(.rsError)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .rsShake(trigger: shakeError)
                    }

                    termsRow

                    PrimaryButton(
                        title: "SIGN UP",
                        action: handleSignUp,
                        isLoading: viewModel.isLoading,
                        isDisabled: !viewModel.isSignUpEnabled
                    )

                    HStack(spacing: 12) {
                        Rectangle().fill(Color.rsBorder).frame(height: 1)
                        Text("OR SIGN UP WITH")
                            .font(.system(size: AppTheme.Font.caption, weight: .medium))
                            .foregroundColor(.rsTextMuted)
                            .fixedSize()
                        Rectangle().fill(Color.rsBorder).frame(height: 1)
                    }

                    HStack(spacing: 12) {
                        SocialLoginButton(title: "Google", icon: "globe") {
                            handleGoogleSignUp()
                        }
                        SocialLoginButton(title: "Apple", icon: "apple.logo") {
                        }
                    }

                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(.rsTextSecondary)
                        Button(action: onBack) {
                            Text("Log In")
                                .foregroundColor(.rsForestGreen)
                                .fontWeight(.semibold)
                        }
                    }
                    .font(.system(size: AppTheme.Font.body))
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 32)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
        .dismissKeyboardOnTap()
        .loadingOverlay(isLoading: viewModel.isLoading, message: "Creating account…")
    }

    // MARK: - Actions
    private func handleSignUp() {
        Task {
            if let user = await viewModel.signUp() {
                onSignUpSuccess(user)
            } else {
                withAnimation(.default) { shakeError.toggle() }
            }
        }
    }

    private func handleGoogleSignUp() {
        Task {
            if let user = await viewModel.signInWithGoogle() {
                onSignUpSuccess(user)
            }
        }
    }

    // MARK: - Password strength
    private var passwordStrengthRow: some View {
        VStack(spacing: 6) {
            strengthRule(met: viewModel.hasMinLength,      label: "At least 8 characters")
            strengthRule(met: viewModel.hasSymbolOrNumber, label: "Contains a number or symbol")
            if !viewModel.confirmPassword.isEmpty {
                strengthRule(met: viewModel.passwordsMatch, label: "Passwords match")
            }
        }
        .padding(.horizontal, 4)
    }

    private func strengthRule(met: Bool, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundColor(met ? .rsForestGreen : .rsTextMuted)
            Text(label)
                .font(.system(size: AppTheme.Font.caption))
                .foregroundColor(met ? .rsTextPrimary : .rsTextMuted)
            Spacer()
        }
    }

    // MARK: - Terms row
    private var termsRow: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                viewModel.agreedToTerms.toggle()
            } label: {
                Image(systemName: viewModel.agreedToTerms ? "checkmark.square.fill" : "square")
                    .foregroundColor(viewModel.agreedToTerms ? .rsForestGreen : .rsTextMuted)
                    .font(.system(size: 20))
            }
            .accessibilityLabel("Agree to terms")

            Text("By creating an account, you agree to our ")
                .foregroundColor(.rsTextSecondary)
            + Text("Terms of Service")
                .foregroundColor(.rsForestGreen)
                .underline()
            + Text(" and ")
                .foregroundColor(.rsTextSecondary)
            + Text("Privacy Policy")
                .foregroundColor(.rsForestGreen)
                .underline()
            + Text(".")
                .foregroundColor(.rsTextSecondary)
        }
        .font(.system(size: AppTheme.Font.caption))
    }
}

#Preview {
    SignUpView(viewModel: SignUpViewModel(), onBack: {}, onSignUpSuccess: { _ in })
        .environmentObject(AppState())
}
