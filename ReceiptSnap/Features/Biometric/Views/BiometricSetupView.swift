
import SwiftUI

struct BiometricSetupView: View {

    @ObservedObject var viewModel: BiometricViewModel
    let onEnableNow:  () -> Void
    let onMaybeLater: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            // ── Illustration ─────────────────────────────────────────────
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Radius.lg)
                    .fill(Color.rsLightGreen)
                    .frame(width: 120, height: 120)

                Image(systemName: viewModel.biometricType.systemImage)
                    .font(.system(size: 52))
                    .foregroundColor(.rsForestGreen)
            }
            .padding(.top, 72)

            Spacer().frame(height: 28)

            Text("Enable \(viewModel.biometricType.displayName)")
                .font(.system(size: AppTheme.Font.largeTitle, weight: .bold))
                .foregroundColor(.rsDeepGreen)

            Spacer().frame(height: 12)

            Text("Use biometrics for faster, more secure\naccess to your receipts.")
                .font(.system(size: AppTheme.Font.body))
                .foregroundColor(.rsTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(5)

            Spacer()

            // ── Actions ───────────────────────────────────────────────────
            VStack(spacing: AppTheme.Spacing.sm) {
                PrimaryButton(title: "Enable Now",   action: onEnableNow)
                SecondaryButton(title: "Maybe Later", action: onMaybeLater)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)

            // ── Privacy note ──────────────────────────────────────────────
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.rsTextMuted)
                    .font(.system(size: 12))
                Text("Your biometric data is stored securely on your device.")
                    .font(.system(size: AppTheme.Font.caption))
                    .foregroundColor(.rsTextMuted)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.vertical, AppTheme.Spacing.lg)
            .padding(.bottom, 20)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

#Preview {
    BiometricSetupView(viewModel: BiometricViewModel(), onEnableNow: {}, onMaybeLater: {})
}
