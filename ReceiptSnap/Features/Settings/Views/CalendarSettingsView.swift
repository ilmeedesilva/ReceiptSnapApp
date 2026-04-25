import SwiftUI

struct CalendarSettingsView: View {

    let onSelectEvents: () -> Void

    @StateObject private var vm = CalendarSettingsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    Spacer().frame(height: 56)

                    reminderTypeSection
                    eventTypesSection
                    helperCard

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
            Text("Calendar Settings")
                .font(.system(size: AppTheme.Font.headline, weight: .bold))
                .foregroundColor(.rsTextPrimary)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .frame(height: 56)
        .background(Color.rsBackgroundGreen)
    }


    private var reminderTypeSection: some View {
        calGroup(header: "REMINDER TYPE") {
            ForEach(Array(ReminderTiming.allCases.enumerated()), id: \.element.id) { i, timing in
                if i > 0 { Divider().padding(.leading, AppTheme.Spacing.md) }

                Button { vm.reminderTiming = timing } label: {
                    HStack(spacing: AppTheme.Spacing.md) {
                        Text(timing.rawValue)
                            .font(.system(size: AppTheme.Font.body))
                            .foregroundColor(.rsTextPrimary)
                        Spacer()
                        radioIndicator(selected: vm.reminderTiming == timing)
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm + 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
    private var eventTypesSection: some View {
        calGroup(header: "EVENT TYPES") {
            ForEach(Array(EventFilter.allCases.enumerated()), id: \.element.id) { i, filter in
                if i > 0 { Divider().padding(.leading, AppTheme.Spacing.md) }

                Button { vm.eventFilter = filter } label: {
                    HStack(spacing: AppTheme.Spacing.md) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(filter.rawValue)
                                .font(.system(size: AppTheme.Font.body))
                                .foregroundColor(.rsTextPrimary)
                            if filter == .selectedOnly {
                                Text(vm.selectedEventsLabel)
                                    .font(.system(size: AppTheme.Font.caption))
                                    .foregroundColor(.rsTextSecondary)
                            }
                        }
                        Spacer()
                        radioIndicator(selected: vm.eventFilter == filter)
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm + 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            if vm.eventFilter == .selectedOnly {
                Divider().padding(.leading, AppTheme.Spacing.md)

                Button { onSelectEvents() } label: {
                    HStack(spacing: AppTheme.Spacing.md) {
                        Image(systemName: "list.bullet.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.rsForestGreen)
                        Text("Select Events")
                            .font(.system(size: AppTheme.Font.body))
                            .foregroundColor(.rsForestGreen)
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
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.2), value: vm.eventFilter)
            }
        }
    }


    private var helperCard: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 18))
                .foregroundColor(.rsForestGreen)
            VStack(alignment: .leading, spacing: 4) {
                Text("How it works")
                    .font(.system(size: AppTheme.Font.body, weight: .semibold))
                    .foregroundColor(.rsTextPrimary)
                Text("ReceiptSnap scans your calendar for relevant events and reminds you to log expenses at the selected time relative to each event.")
                    .font(.system(size: AppTheme.Font.caption))
                    .foregroundColor(.rsTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color.rsLightGreen.opacity(0.4))
        .cornerRadius(AppTheme.Radius.card)
    }


    private func radioIndicator(selected: Bool) -> some View {
        ZStack {
            Circle()
                .stroke(selected ? Color.rsForestGreen : Color.rsDivider, lineWidth: 2)
                .frame(width: 22, height: 22)
            if selected {
                Circle()
                    .fill(Color.rsForestGreen)
                    .frame(width: 12, height: 12)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: selected)
    }


    private func calGroup<Content: View>(
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
}

#Preview {
    NavigationStack {
        CalendarSettingsView(onSelectEvents: {})
    }
}
