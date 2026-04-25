
import SwiftUI

struct BiometricSuccessView: View {

    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            Spacer()

            // ── Illustration ─────────────────────────────────────────────
            ZStack {
                Circle()
                    .fill(Color.rsLightGreen)
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.rsMediumGreen)
            }

            Spacer().frame(height: 28)

            Text("Face ID Success")
                .font(.system(size: AppTheme.Font.title, weight: .bold))
                .foregroundColor(.rsDeepGreen)

            Spacer().frame(height: 12)

            Text("Identity verified successfully")
                .font(.system(size: AppTheme.Font.body))
                .foregroundColor(.rsTextSecondary)

            Spacer()

            PrimaryButton(title: "Continue", action: onContinue)
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.bottom, 52)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

#Preview { BiometricSuccessView(onContinue: {}) }
