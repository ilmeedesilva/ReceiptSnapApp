import SwiftUI

struct PrimaryButton: View {

    let title: String
    let action: () -> Void
    var isLoading:  Bool  = false
    var isDisabled: Bool  = false
    var background: Color = .rsForestGreen
    var foreground: Color = .white
    var height:     CGFloat = AppTheme.Height.button

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foreground))
                        .scaleEffect(0.9)
                } else {
                    Text(title)
                        .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                        .foregroundColor(foreground)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(isDisabled ? background.opacity(0.45) : background)
            .cornerRadius(AppTheme.Radius.button)
        }
        .disabled(isDisabled || isLoading)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack(spacing: 12) {
        PrimaryButton(title: "Sign In") {}
        PrimaryButton(title: "Loading", action: {}, isLoading: true)
        PrimaryButton(title: "Disabled", action: {}, isDisabled: true)
    }
    .padding()
}
