import SwiftUI

struct HomeView: View {

    @EnvironmentObject private var appState: AppState
    @State private var showSignOutConfirm = false

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.lg) {

            
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.rsLightGreen)
                            .frame(width: 100, height: 100)
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.rsForestGreen)
                    }

                    Text("Welcome, \(appState.currentUser?.firstName ?? "User")!")
                        .font(.system(size: AppTheme.Font.title, weight: .bold))
                        .foregroundColor(.rsDeepGreen)

                    Text("Your receipt dashboard is coming in Phase 2.")
                        .font(.system(size: AppTheme.Font.body))
                        .foregroundColor(.rsTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)

                VStack(spacing: 12) {
                    featureCard(
                        icon: "camera.fill",
                        title: "Scan Receipt",
                        subtitle: "Coming in Phase 2"
                    )
                    featureCard(
                        icon: "chart.bar.fill",
                        title: "Expense Analytics",
                        subtitle: "Coming in Phase 2"
                    )
                    featureCard(
                        icon: "folder.fill",
                        title: "Receipt History",
                        subtitle: "Coming in Phase 2"
                    )
                }
                .padding(.horizontal, AppTheme.Spacing.xl)

                Spacer()

                Button {
                    showSignOutConfirm = true
                } label: {
                    Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: AppTheme.Font.body, weight: .medium))
                        .foregroundColor(.rsError)
                }
                .padding(.bottom, 32)
            }
            .rsScreenBackground()
            .navigationTitle("ReceiptSnap")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Sign Out", isPresented: $showSignOutConfirm) {
                Button("Sign Out", role: .destructive) { appState.signOut() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }

    private func featureCard(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.rsForestGreen)
                .frame(width: 48, height: 48)
                .background(Color.rsLightGreen)
                .cornerRadius(AppTheme.Radius.md)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                    .foregroundColor(.rsDeepGreen)
                Text(subtitle)
                    .font(.system(size: AppTheme.Font.caption))
                    .foregroundColor(.rsTextMuted)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.rsTextMuted)
                .font(.system(size: 12))
        }
        .rsCardStyle()
    }
}

#Preview {
    HomeView()
        .environmentObject({
            let s = AppState()
            s.signIn(user: AppUser(uid: "preview", email: "user@demo.com", displayName: "Alex Smith"))
            return s
        }())
}
