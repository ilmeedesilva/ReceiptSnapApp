import SwiftUI

struct LoadingOverlay: View {

    var message: String = "Please wait…"

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.md) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .rsForestGreen))
                    .scaleEffect(1.4)

                Text(message)
                    .font(.system(size: AppTheme.Font.body, weight: .medium))
                    .foregroundColor(.rsTextPrimary)
            }
            .padding(AppTheme.Spacing.xl)
            .background(Color.white)
            .cornerRadius(AppTheme.Radius.lg)
            .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 4)
        }
    }
}

// MARK: - View modifier for conditional overlay
extension View {
    func loadingOverlay(isLoading: Bool, message: String = "Please wait…") -> some View {
        overlay {
            if isLoading {
                LoadingOverlay(message: message)
            }
        }
    }
}

#Preview {
    LoadingOverlay(message: "Signing in…")
}
