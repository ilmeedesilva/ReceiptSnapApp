
import SwiftUI

struct NotificationsView: View {

    // Callbacks for cross-tab navigation triggered by notification taps.
    // MainTabView fills these in so the notification screen can push users to
    // the right destination without knowing about the tab structure itself.
    var onBudgetFeedbackTap: (() -> Void)? = nil
    var onBudgetAlertTap:    (() -> Void)? = nil
    var onWeeklyReportTap:   (() -> Void)? = nil
    var onReceiptTap:        (() -> Void)? = nil

    @StateObject private var viewModel = NotificationsViewModel()
    @State private var showClearConfirm = false

    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if viewModel.notifications.isEmpty {
                    emptyState
                } else {
                    notificationsList
                }
            }
            .safeAreaInset(edge: .top) { Color.clear.frame(height: 56) }

            navBar
        }
        .rsScreenBackground()
        .task { await viewModel.loadNotifications() }
        .confirmationDialog("Clear All Notifications?", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("Clear All", role: .destructive) { viewModel.clearAll() }
            Button("Cancel",    role: .cancel)      {}
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.notifications.count)
    }

    // MARK: - Nav bar

    private var navBar: some View {
        HStack {
            Spacer()
            Text("Notifications")
                .font(.system(size: AppTheme.Font.headline, weight: .bold))
                .foregroundColor(.rsTextPrimary)
            Spacer()

            if viewModel.hasUnread {
                Menu {
                    Button("Mark All as Read") { viewModel.markAllAsRead() }
                    Button("Clear All", role: .destructive) { showClearConfirm = true }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.rsDeepGreen)
                        .frame(width: 44, height: 44)
                }
            } else if !viewModel.notifications.isEmpty {
                Button { showClearConfirm = true } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 17))
                        .foregroundColor(.rsTextSecondary)
                        .frame(width: 44, height: 44)
                }
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .frame(height: 56)
        .background(Color.rsBackgroundGreen)
    }

    // MARK: - Notifications list

    private var notificationsList: some View {
        List {
            ForEach(viewModel.groupedNotifications, id: \.group.rawValue) { section in
                Section {
                    ForEach(section.items) { notification in
                        NotificationRow(notification: notification) {
                            handleTap(notification)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.delete(id: notification.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            if !notification.isRead {
                                Button {
                                    viewModel.markAsRead(id: notification.id)
                                } label: {
                                    Label("Read", systemImage: "envelope.open")
                                }
                                .tint(Color.rsForestGreen)
                            }
                        }
                    }
                } header: {
                    Text(section.group.rawValue)
                        .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                        .foregroundColor(.rsTextSecondary)
                        .tracking(0.5)
                        .padding(.top, 4)
                }
            }
        }
        .listStyle(.plain)
        .background(Color.rsBackgroundGreen)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 52))
                .foregroundColor(.rsLightGreen)
            Text("No Notifications")
                .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                .foregroundColor(.rsDeepGreen)
            Text("You're all caught up!")
                .font(.system(size: AppTheme.Font.body))
                .foregroundColor(.rsTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Tap handler

    private func handleTap(_ notification: AppNotification) {
        viewModel.markAsRead(id: notification.id)

        switch notification.type {
        case .budgetFeedback:
            onBudgetFeedbackTap?()
        case .budgetAlert:
            onBudgetAlertTap?()
        case .receiptReminder, .locationReminder:
            onReceiptTap?()
        case .weeklyReport:
            onWeeklyReportTap?()
        case .dailyReminder:
            break
        }
    }
}


private struct NotificationRow: View {

    let notification: AppNotification
    let onTap:        () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {

                // Icon
                ZStack {
                    Circle()
                        .fill(Color(hex: notification.type.colorHex).opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: notification.type.icon)
                        .font(.system(size: 17))
                        .foregroundColor(Color(hex: notification.type.colorHex))
                }
                .overlay(alignment: .topTrailing) {
                    if !notification.isRead {
                        Circle()
                            .fill(Color.rsForestGreen)
                            .frame(width: 9, height: 9)
                            .offset(x: 2, y: -2)
                    }
                }

                // Content
                VStack(alignment: .leading, spacing: 3) {
                    Text(notification.title)
                        .font(.system(size: AppTheme.Font.body,
                                      weight: notification.isRead ? .medium : .bold))
                        .foregroundColor(.rsTextPrimary)
                        .multilineTextAlignment(.leading)

                    Text(notification.message)
                        .font(.system(size: AppTheme.Font.caption))
                        .foregroundColor(.rsTextSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 4)

                // Relative time
                Text(notification.relativeTimeLabel())
                    .font(.system(size: AppTheme.Font.caption))
                    .foregroundColor(.rsTextMuted)
                    .lineLimit(1)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm + 4)
            .background(notification.isRead ? Color.white : Color.rsBackgroundGreen)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}


#Preview {
    NotificationsView()
}
