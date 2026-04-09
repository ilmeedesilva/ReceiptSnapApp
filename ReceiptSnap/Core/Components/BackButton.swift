import SwiftUI

struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.rsDeepGreen)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.0))
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Back")
    }
}
