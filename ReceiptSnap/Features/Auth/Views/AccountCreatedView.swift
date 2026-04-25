import SwiftUI

struct AccountCreatedView: View {

    let onEnableFaceID:  () -> Void
    let onSetupPasscode: () -> Void
    let onSkip:          () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.rsLightGreen)
                    .frame(width: 120, height: 120)

                Text("🎉")
                    .font(.system(size: 56))
            }

            Spacer().frame(height: 28)

            Text("Account Created\nSuccessfully!")
                .font(.system(size: AppTheme.Font.largeTitle, weight: .bold))
                .foregroundColor(.rsDeepGreen)
                .multilineTextAlignment(.center)

            Spacer().frame(height: 16)

            Text("Welcome aboard! Your account is ready to go.\nNow, let's secure your data with biometric\nor passcode protection.")
                .font(.system(size: AppTheme.Font.body))
                .foregroundColor(.rsTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .padding(.horizontal, AppTheme.Spacing.xxl)

            Spacer()

            VStack(spacing: AppTheme.Spacing.sm) {
                PrimaryButton(title: "Enable Face ID Security", action: onEnableFaceID)

                SecondaryButton(title: "Set up Passcode instead", action: onSetupPasscode)

                Button(action: onSkip) {
                    Text("Skip for now")
                        .font(.system(size: AppTheme.Font.body, weight: .medium))
                        .foregroundColor(.rsForestGreen)
                        .padding(.vertical, 8)
                }
                .accessibilityLabel("Skip biometric setup")
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.bottom, 48)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

#Preview {
    AccountCreatedView(onEnableFaceID: {}, onSetupPasscode: {}, onSkip: {})
}
