import SwiftUI

struct SecondaryButton: View {

    let title: String
    let action: () -> Void
    var isDisabled:   Bool  = false
    var borderColor:  Color = .rsForestGreen
    var foreground:   Color = .rsForestGreen
    var height:       CGFloat = AppTheme.Height.button

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                .foregroundColor(isDisabled ? foreground.opacity(0.45) : foreground)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.button)
                        .stroke(isDisabled ? borderColor.opacity(0.45) : borderColor, lineWidth: 1.5)
                )
        }
        .disabled(isDisabled)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack(spacing: 12) {
        SecondaryButton(title: "Maybe Later") {}
        SecondaryButton(title: "Disabled", action: {}, isDisabled: true)
    }
    .padding()
}
