import SwiftUI

extension View {

    // MARK: - Keyboard
    func dismissKeyboardOnTap() -> some View {
        onTapGesture {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
        }
    }

    // MARK: - Backgrounds
    func rsScreenBackground() -> some View {
        background(Color.rsBackgroundGreen.ignoresSafeArea())
    }

    // MARK: - Card style
    func rsCardStyle(padding: CGFloat = AppTheme.Spacing.md) -> some View {
        self
            .padding(padding)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(AppTheme.Radius.card)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }

    // MARK: - Error shake animation
    func rsShake(trigger: Bool) -> some View {
        modifier(ShakeModifier(animatableData: trigger ? 1 : 0))
    }
}

// MARK: - Shake Modifier
struct ShakeModifier: AnimatableModifier {
    var animatableData: CGFloat

    func body(content: Content) -> some View {
        content.offset(x: sin(animatableData * .pi * 6) * 8)
    }
}
