import SwiftUI

struct NotificationSettingsView: View {

    let onCalendarSettings: () -> Void

    @StateObject private var vm = NotificationSettingsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    Spacer().frame(height: 56)

                    generalSection
                    notificationTypesSection
                    locationSection
                    calendarSection
                    proTipCard

                    Spacer().frame(height: AppTheme.Spacing.sm)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
            .background(Color.rsBackgroundGreen)

            navBar
        }
        .navigationBarHidden(true)
    }


    private var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.rsDeepGreen)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Text("Notifications")
                .font(.system(size: AppTheme.Font.headline, weight: .bold))
                .foregroundColor(.rsTextPrimary)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .frame(height: 56)
        .background(Color.rsBackgroundGreen)
    }

    private var generalSection: some View {
        notifGroup(header: "GENERAL PREFERENCES") {

            HStack(spacing: AppTheme.Spacing.md) {
                notifIconBox(sfSymbol: "bell.fill", colorHex: "F97316")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Daily Reminder")
                        .font(.system(size: AppTheme.Font.body))
                        .foregroundColor(.rsTextPrimary)
                    Text("Get reminded to log receipts")
                        .font(.system(size: AppTheme.Font.caption))
                        .foregroundColor(.rsTextSecondary)
                }
                Spacer()
                Toggle("", isOn: $vm.isDailyReminderEnabled)
                    .labelsHidden()
                    .tint(.rsForestGreen)
                    .onChange(of: vm.isDailyReminderEnabled) { _, enabled in
                        if enabled { vm.requestNotificationPermission() }
                    }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm + 4)

            if vm.isDailyReminderEnabled {
                Divider().padding(.leading, 56)

                VStack(spacing: 0) {
                    Button { withAnimation(.easeInOut(duration: 0.25)) { vm.showReminderPicker.toggle() } } label: {
                        HStack(spacing: AppTheme.Spacing.md) {
                            notifIconBox(sfSymbol: "clock.fill", colorHex: "F59E0B")
                            Text("Reminder Time")
                                .font(.system(size: AppTheme.Font.body))
                                .foregroundColor(.rsTextPrimary)
                            Spacer()
                            Text(vm.reminderTimeLabel)
                                .font(.system(size: AppTheme.Font.body))
                                .foregroundColor(.rsTextSecondary)
                            Image(systemName: vm.showReminderPicker ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12))
                                .foregroundColor(.rsTextMuted)
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.sm + 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if vm.showReminderPicker {
                        DatePicker(
                            "",
                            selection: Binding(
                                get: { vm.reminderTime },
                                set: { vm.reminderTime = $0 }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.bottom, AppTheme.Spacing.sm)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
        }
    }

    private var notificationTypesSection: some View {
        notifGroup(header: "NOTIFICATION TYPES") {

            notifToggleRow(
                sfSymbol: "sun.max.fill", colorHex: "F59E0B",
                title: "Daily Briefing",
                subtitle: "Morning summary of spending",
                binding: $vm.isDailyBriefingEnabled
            )

            Divider().padding(.leading, 56)

            notifToggleRow(
                sfSymbol: "chart.bar.fill", colorHex: "8B5CF6",
                title: "Weekly Summary",
                subtitle: "End-of-week spending recap",
                binding: $vm.isWeeklySummaryEnabled
            )
        }
    }


    private var locationSection: some View {
        notifGroup(header: "LOCATION BASED REMINDERS") {
            notifToggleRow(
                sfSymbol: "location.fill", colorHex: "10B981",
                title: "Enable Location Alerts",
                subtitle: "Remind when near a store",
                binding: $vm.isLocationAlertsEnabled,
                onChange: { enabled in if enabled { vm.requestLocationPermission() } }
            )

            Divider().padding(.leading, 56)

            Button { vm.openSystemSettings() } label: {
                HStack(spacing: AppTheme.Spacing.md) {
                    notifIconBox(sfSymbol: "gear", colorHex: "6B7280")
                    Text("Manage Settings")
                        .font(.system(size: AppTheme.Font.body))
                        .foregroundColor(.rsTextPrimary)
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 13))
                        .foregroundColor(.rsTextMuted)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm + 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }


    private var calendarSection: some View {
        notifGroup(header: "CALENDAR BASED REMINDERS") {
            notifToggleRow(
                sfSymbol: "calendar", colorHex: "3B82F6",
                title: "Auto-Sync Calendar",
                subtitle: "Sync spending with calendar events",
                binding: $vm.isCalendarSyncEnabled,
                onChange: { enabled in if enabled { vm.requestCalendarPermission() } }
            )

            Divider().padding(.leading, 56)

            Button { onCalendarSettings() } label: {
                HStack(spacing: AppTheme.Spacing.md) {
                    notifIconBox(sfSymbol: "slider.horizontal.3", colorHex: "6366F1")
                    Text("Manage Settings")
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
    }

    private var proTipCard: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 18))
                .foregroundColor(.rsForestGreen)
            VStack(alignment: .leading, spacing: 4) {
                Text("Pro Tip")
                    .font(.system(size: AppTheme.Font.body, weight: .semibold))
                    .foregroundColor(.rsTextPrimary)
                Text("Enable calendar sync to automatically get reminded to log expenses after meetings or events.")
                    .font(.system(size: AppTheme.Font.caption))
                    .foregroundColor(.rsTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color.rsLightGreen.opacity(0.4))
        .cornerRadius(AppTheme.Radius.card)
    }


    private func notifGroup<Content: View>(
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
            .background(Color.white)
            .cornerRadius(AppTheme.Radius.card)
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }

    private func notifToggleRow(
        sfSymbol: String,
        colorHex: String,
        title: String,
        subtitle: String,
        binding: Binding<Bool>,
        onChange: ((Bool) -> Void)? = nil
    ) -> some View {
        HStack(spacing: AppTheme.Spacing.md) {
            notifIconBox(sfSymbol: sfSymbol, colorHex: colorHex)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: AppTheme.Font.body))
                    .foregroundColor(.rsTextPrimary)
                Text(subtitle)
                    .font(.system(size: AppTheme.Font.caption))
                    .foregroundColor(.rsTextSecondary)
            }
            Spacer()
            Toggle("", isOn: binding)
                .labelsHidden()
                .tint(.rsForestGreen)
                .onChange(of: binding.wrappedValue) { _, newVal in
                    onChange?(newVal)
                }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm + 4)
    }

    private func notifIconBox(sfSymbol: String, colorHex: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                .fill(Color(hex: colorHex))
                .frame(width: 34, height: 34)
            Image(systemName: sfSymbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    NavigationStack {
        NotificationSettingsView(onCalendarSettings: {})
    }
}
