import SwiftUI

struct SelectEventsView: View {

    @StateObject private var vm = CalendarSettingsViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    Spacer().frame(height: 56)

                    eventsGroup
                    helperText

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
            Text("Select Events")
                .font(.system(size: AppTheme.Font.headline, weight: .bold))
                .foregroundColor(.rsTextPrimary)
            Spacer()
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: AppTheme.Font.body, weight: .semibold))
                    .foregroundColor(.rsForestGreen)
                    .frame(width: 60, height: 44)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .frame(height: 56)
        .background(Color.rsBackgroundGreen)
    }


    private var eventsGroup: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text("EVENT TYPES")
                .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
                .tracking(0.5)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(vm.availableEvents.enumerated()), id: \.element) { i, event in
                    if i > 0 { Divider().padding(.leading, AppTheme.Spacing.md) }

                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            if vm.selectedEvents.contains(event) {
                                vm.selectedEvents.remove(event)
                            } else {
                                vm.selectedEvents.insert(event)
                            }
                        }
                    } label: {
                        HStack(spacing: AppTheme.Spacing.md) {
                            eventIcon(for: event)

                            Text(event)
                                .font(.system(size: AppTheme.Font.body))
                                .foregroundColor(.rsTextPrimary)

                            Spacer()

                            checkmark(selected: vm.selectedEvents.contains(event))
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.sm + 4)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.white)
            .cornerRadius(AppTheme.Radius.card)
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }


    private var helperText: some View {
        Text("ReceiptSnap will send reminders after the selected event types to help you remember to log your expenses.")
            .font(.system(size: AppTheme.Font.caption))
            .foregroundColor(.rsTextSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppTheme.Spacing.md)
    }

    private func eventIcon(for event: String) -> some View {
        let (symbol, hex): (String, String) = {
            switch event {
            case "Dinner":       return ("fork.knife",         "F97316")
            case "Shopping":     return ("bag.fill",           "8B5CF6")
            case "Food Market":  return ("cart.fill",          "10B981")
            case "Coffee":       return ("cup.and.saucer.fill","6366F1")
            case "Grocery":      return ("basket.fill",        "3B82F6")
            default:             return ("calendar",           "6B7280")
            }
        }()
        return ZStack {
            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                .fill(Color(hex: hex))
                .frame(width: 34, height: 34)
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        }
    }

    private func checkmark(selected: Bool) -> some View {
        ZStack {
            Circle()
                .fill(selected ? Color.rsForestGreen : Color.rsDivider)
                .frame(width: 24, height: 24)
            if selected {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: selected)
    }
}

#Preview {
    NavigationStack {
        SelectEventsView()
    }
}
