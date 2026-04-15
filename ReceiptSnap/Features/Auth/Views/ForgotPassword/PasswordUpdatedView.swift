import SwiftUI

struct PasswordUpdatedView: View {

    let onBackToLogin: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            Spacer()

            ZStack {
                Circle()
                    .fill(Color.rsLightGreen)
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 52))
                    .foregroundColor(.rsForestGreen)
            }

            Spacer().frame(height: 32)

            Text("Password updated!")
                .font(.system(size: AppTheme.Font.largeTitle, weight: .bold))
                .foregroundColor(.rsDeepGreen)

            Spacer().frame(height: 16)

            Text("Your new password has been set up\nsuccessfully.")
                .font(.system(size: AppTheme.Font.body))
                .foregroundColor(.rsTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(5)

            Spacer()

            PrimaryButton(title: "BACK TO LOGIN", action: onBackToLogin)
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.bottom, 52)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

#Preview {
    PasswordUpdatedView(onBackToLogin: {})
}
