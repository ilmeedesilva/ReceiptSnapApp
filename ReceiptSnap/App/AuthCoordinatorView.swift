import SwiftUI
import Combine

struct AuthCoordinatorView: View {

    @EnvironmentObject private var appState: AppState

    // MARK: - ViewModels
    @StateObject private var loginVM          = LoginViewModel()
    @StateObject private var signUpVM         = SignUpViewModel()
    @StateObject private var forgotPasswordVM = ForgotPasswordViewModel()
    @StateObject private var biometricVM      = BiometricViewModel()

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            LoginView(viewModel: loginVM, onNavigate: push)
                .navigationDestination(for: AuthRoute.self) { route in
                    destination(for: route)
                }
        }
    }

    // MARK: - Navigation helpers
    private func push(_ route: AuthRoute) {
        path.append(route)
    }

    private func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    private func popToRoot() {
        path.removeLast(path.count)
    }

    // MARK: - Route → View
    @ViewBuilder
    private func destination(for route: AuthRoute) -> some View {
        switch route {

        case .signUp:
            SignUpView(
                viewModel: signUpVM,
                onBack: pop,
                onSignUpSuccess: { user in
                    appState.setPendingUser(user)
                    push(.accountCreated)
                }
            )

        case .forgotPasswordEmail:
            ForgotPasswordEmailView(
                viewModel: forgotPasswordVM,
                onCodeSent: { email in push(.verifyCode(email: email)) },
                onBack: pop
            )

        case .verifyCode(let email):
            VerifyCodeView(
                viewModel: forgotPasswordVM,
                email: email,
                onVerified: { code in push(.createNewPassword(email: email, otpCode: code)) },
                onBack: pop
            )

        case .createNewPassword:
            CreateNewPasswordView(
                viewModel: forgotPasswordVM,
                onPasswordReset: { push(.passwordUpdated) },
                onBack: pop
            )

        case .passwordUpdated:
            PasswordUpdatedView(onBackToLogin: {
                forgotPasswordVM.reset()
                popToRoot()
            })

        case .accountCreated:
            AccountCreatedView(
                onEnableFaceID:  { push(.biometricSetup) },
                onSetupPasscode: { push(.passcodeSetup)  },
                onSkip: {
                    appState.skipBiometricSetup()
                    if let user = appState.pendingUser { appState.signIn(user: user) }
                }
            )

        case .biometricSetup:
            BiometricSetupView(
                viewModel: biometricVM,
                onEnableNow:  { push(.faceIDScanning) },
                onMaybeLater: {
                    appState.skipBiometricSetup()
                    if let user = appState.pendingUser { appState.signIn(user: user) }
                    else { appState.isAuthenticated = true }   // already signed in via login
                }
            )

        case .faceIDScanning:
            FaceIDScanningView(
                viewModel: biometricVM,
                onSuccess:       { push(.biometricSuccess) },
                onEnterPasscode: { push(.passcodeSetup)    },
                onCancel:        pop
            )

        case .biometricSuccess:
            BiometricSuccessView(onContinue: {
                appState.enableBiometric()
                if let user = appState.pendingUser { appState.signIn(user: user) }
                else { appState.isAuthenticated = true }
            })

        case .passcodeSetup:
            PasscodeSetupView(
                viewModel: biometricVM,
                onSuccess: { push(.passcodeSuccess) }
            )

        case .passcodeSuccess:
            PasscodeSuccessView(onContinue: {
                appState.skipBiometricSetup()  // passcode saved in Keychain
                if let user = appState.pendingUser { appState.signIn(user: user) }
                else { appState.isAuthenticated = true }
            })
        }
    }
}

#Preview {
    AuthCoordinatorView()
        .environmentObject(AppState())
}
