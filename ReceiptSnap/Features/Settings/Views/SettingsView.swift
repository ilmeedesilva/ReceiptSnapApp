import SwiftUI

struct SettingsView: View {

    @EnvironmentObject private var appState: AppState
    @StateObject private var vm             = SettingsViewModel()

    @State private var navPath              = NavigationPath()
    @State private var showLogoutConfirm    = false
    @State private var showProfile          = false

    var body: some View {
        NavigationStack(path: $navPath) {
            ZStack(alignment: .top) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        Spacer().frame(height: 56)

                        profileCard
                        securitySection
                        notificationSection
                        appearanceSection
                        logoutButton

                        Spacer().frame(height: AppTheme.Spacing.sm)
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                }
                .background(Color.rsBackgroundGreen)

                navBar
            }
            .navigationBarHidden(true)
            .navigationDestination(for: SettingsRoute.self) { route in
                settingsDestination(for: route)
            }
        }
        .sheet(isPresented: $showProfile) {
            UserProfileView()
        }
        .confirmationDialog("Are you sure you want to logout?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("Logout", role: .destructive) { appState.signOut() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will need to sign back in to access your data.")
        }
    }
    private var navBar: some View {
        HStack {
            Spacer()
            Text("Settings")
                .font(.system(size: AppTheme.Font.headline, weight: .bold))
                .foregroundColor(.rsTextPrimary)
            Spacer()
        }
        .frame(height: 56)
        .background(Color.rsBackgroundGreen)
    }

    private var profileCard: some View {
        Button { showProfile = true } label: {
            VStack(spacing: AppTheme.Spacing.sm) {
                ZStack(alignment: .bottomTrailing) {

                    ZStack {
                        Circle()
                            .fill(Color.rsLightGreen)
                            .frame(width: 88, height: 88)
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.rsForestGreen)
                    }

                    ZStack {
                        Circle()
                            .fill(Color.rsForestGreen)
                            .frame(width: 26, height: 26)
                        Image(systemName: "pencil")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                VStack(spacing: 3) {
                    Text(appState.currentUser?.displayName ?? "User")
                        .font(.system(size: AppTheme.Font.headline, weight: .bold))
                        .foregroundColor(.rsTextPrimary)
                    Text(appState.currentUser?.email ?? "—")
                        .font(.system(size: AppTheme.Font.body))
                        .foregroundColor(.rsTextSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(Color.rsCardBackground)
            .cornerRadius(AppTheme.Radius.card)
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }


    private var securitySection: some View {
        settingsGroup(header: "SECURITY & ACCESS") {
            settingsRow(
                icon: "faceid", iconColorHex: "3B82F6",
                label: "Enable FaceID"
            ) {
                navPath.append(SettingsRoute.security)
            }
            Divider().padding(.leading, 56)
            settingsRow(
                icon: "bell.fill", iconColorHex: "F97316",
                label: "Notifications"
            ) {
                navPath.append(SettingsRoute.notificationSettings)
            }
        }
    }


    private var notificationSection: some View {
        settingsGroup(header: "NOTIFICATION SETTINGS") {
            HStack(spacing: AppTheme.Spacing.md) {
                settingsIconBox(sfSymbol: "clock.fill", colorHex: "F97316")
                Text("Reminder Time")
                    .font(.system(size: AppTheme.Font.body))
                    .foregroundColor(.rsTextPrimary)
                Spacer()
                Button {
                    navPath.append(SettingsRoute.notificationSettings)
                } label: {
                    HStack(spacing: 4) {
                        Text(vm.reminderTimeLabel)
                            .font(.system(size: AppTheme.Font.body))
                            .foregroundColor(.rsTextSecondary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(.rsTextMuted)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm + 4)
        }
    }

    private var appearanceSection: some View {
        settingsGroup(header: "APPEARANCE") {
            HStack(spacing: AppTheme.Spacing.md) {
                settingsIconBox(sfSymbol: "moon.fill", colorHex: "8B5CF6")
                Text("Dark Mode")
                    .font(.system(size: AppTheme.Font.body))
                    .foregroundColor(.rsTextPrimary)
                Spacer()
                Toggle("", isOn: $vm.isDarkMode)
                    .labelsHidden()
                    .tint(.rsForestGreen)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm + 4)
        }
    }


    private var logoutButton: some View {
        Button { showLogoutConfirm = true } label: {
            Text("Log Out")
                .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                .foregroundColor(.rsError)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppTheme.Spacing.md)
                .background(Color.rsCardBackground)
                .cornerRadius(AppTheme.Radius.card)
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }


    @ViewBuilder
    private func settingsGroup<Content: View>(
        header: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(header)
                .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
                .tracking(0.5)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.rsCardBackground)
            .cornerRadius(AppTheme.Radius.card)
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }

    private func settingsRow(
        icon: String,
        iconColorHex: String,
        label: String,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.md) {
                settingsIconBox(sfSymbol: icon, colorHex: iconColorHex)
                Text(label)
                    .font(.system(size: AppTheme.Font.body))
                    .foregroundColor(.rsTextPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(.rsTextMuted)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm + 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func settingsIconBox(sfSymbol: String, colorHex: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                .fill(Color(hex: colorHex))
                .frame(width: 34, height: 34)
            Image(systemName: sfSymbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        }
    }


    @ViewBuilder
    private func settingsDestination(for route: SettingsRoute) -> some View {
        switch route {
        case .security:
            SecurityView()

        case .notificationSettings:
            NotificationSettingsView(
                onCalendarSettings: { navPath.append(SettingsRoute.calendarSettings) }
            )

        case .calendarSettings:
            CalendarSettingsView(
                onSelectEvents: { navPath.append(SettingsRoute.selectEvents) }
            )

        case .selectEvents:
            SelectEventsView()
        }
    }
}


#Preview {
    SettingsView()
        .environmentObject({
            let s = AppState()
            s.signIn(user: AppUser(uid: "p", email: "alex.rivera@example.com", displayName: "Alex Rivera"))
            return s
        }())
}
