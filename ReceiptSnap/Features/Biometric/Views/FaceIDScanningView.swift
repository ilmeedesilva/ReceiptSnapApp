
import SwiftUI

struct FaceIDScanningView: View {

    @ObservedObject var viewModel: BiometricViewModel
    let onSuccess:       () -> Void
    let onEnterPasscode: () -> Void
    let onCancel:        () -> Void

    @State private var scanAnimating = false
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {

            Spacer()

            // ── Face scan animation ───────────────────────────────────────
            ZStack {
                // Outer pulse ring
                Circle()
                    .stroke(Color.rsLightGreen, lineWidth: 2)
                    .frame(width: 160, height: 160)
                    .scaleEffect(scanAnimating ? 1.15 : 1.0)
                    .opacity(scanAnimating ? 0.4 : 0.8)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                               value: scanAnimating)

                Image(systemName: "faceid")
                    .font(.system(size: 100))
                    .foregroundColor(.rsDeepGreen)
            }

            Spacer().frame(height: 32)

            Text("Face ID")
                .font(.system(size: AppTheme.Font.title, weight: .bold))
                .foregroundColor(.rsDeepGreen)

            Text("Scanning…")
                .font(.system(size: AppTheme.Font.body))
                .foregroundColor(.rsTextSecondary)
                .padding(.top, 6)

            if viewModel.isBiometricSimulationEnabled {
                Text("Demo simulation in progress")
                    .font(.system(size: AppTheme.Font.caption, weight: .medium))
                    .foregroundColor(.rsForestGreen)
                    .padding(.top, 8)
            }

            if let err = viewModel.errorMessage {
                Text(err)
                    .font(.system(size: AppTheme.Font.body))
                    .foregroundColor(.rsError)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                    .padding(.horizontal, AppTheme.Spacing.xl)
            }

            Spacer()

            // ── Buttons ───────────────────────────────────────────────────
            VStack(spacing: AppTheme.Spacing.sm) {
                PrimaryButton(title: "Enter Passcode", action: onEnterPasscode)
                SecondaryButton(title: "Cancel", action: onCancel)
            }
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.bottom, 52)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            scanAnimating = true
            guard !appeared else { return }
            appeared = true
            Task {
                if await viewModel.authenticateWithBiometrics() {
                    onSuccess()
                }
            }
        }
    }
}

#Preview {
    FaceIDScanningView(
        viewModel: BiometricViewModel(),
        onSuccess: {},
        onEnterPasscode: {},
        onCancel: {}
    )
}
