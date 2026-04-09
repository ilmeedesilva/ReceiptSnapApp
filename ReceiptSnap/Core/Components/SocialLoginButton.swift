import SwiftUI

struct SocialLoginButton: View {

    let title:  String
    let icon:   String 
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text(title)
                    .font(.system(size: AppTheme.Font.body, weight: .medium))
            }
            .foregroundColor(.rsTextPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: AppTheme.Height.button)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.button)
                    .stroke(Color.rsBorder, lineWidth: 1)
            )
            .cornerRadius(AppTheme.Radius.button)
        }
        .accessibilityLabel(title)
    }
}

#Preview {
    HStack(spacing: 12) {
        SocialLoginButton(title: "Google", icon: "globe") {}
        SocialLoginButton(title: "Apple",  icon: "apple.logo") {}
    }
    .padding()
}
