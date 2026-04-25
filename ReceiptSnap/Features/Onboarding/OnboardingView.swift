
import SwiftUI

struct OnboardingView: View {

    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Logo ────────────────────────────────────────────────
                LogoView()
                    .padding(.top, 56)

                Spacer(minLength: 32)

                // ── Illustration ─────────────────────────────────────────
                IllustrationView()

                Spacer(minLength: 40)

                // ── Copy ─────────────────────────────────────────────────
                VStack(spacing: 12) {
                    Text("Easy to Track and Analyze")
                        .font(.system(size: AppTheme.Font.title, weight: .bold))
                        .foregroundColor(.rsDeepGreen)
                        .multilineTextAlignment(.center)

                    Text("Tracking your expenses helps make sure\nyou don't overspend")
                        .font(.system(size: AppTheme.Font.body))
                        .foregroundColor(.rsTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                }
                .padding(.horizontal, AppTheme.Spacing.xl)

                Spacer(minLength: 48)

                // ── CTA ──────────────────────────────────────────────────
                PrimaryButton(title: "LET'S GO") {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        appState.completeOnboarding()
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.bottom, 52)
            }
        }
    }
}

private struct LogoView: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.rsForestGreen)
            Text("ReceiptSnap")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.rsDeepGreen)
        }
    }
}

private struct IllustrationView: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.rsForestGreen)
                .frame(width: 270, height: 270)

            VStack(spacing: -12) {
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Color.white.opacity(0.3))

                Image(systemName: "figure.hiking")
                    .font(.system(size: 90))
                    .foregroundColor(.white)
            }
            .offset(y: 12)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
