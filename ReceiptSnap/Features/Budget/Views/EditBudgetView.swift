
import SwiftUI

struct EditBudgetView: View {

    let budget: Budget
    let onSaved: () -> Void           // called after save — parent dismisses to overview
    let onDeleted: () -> Void         // called after delete — parent pushes delete success

    @EnvironmentObject private var budgetVM: BudgetViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    Spacer().frame(height: 48)

                    currentBudgetCard
                    amountInputSection
                    notificationSection
                    buttonsSection

                    Spacer().frame(height: AppTheme.Spacing.sm)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }

            navBar
        }
        .rsScreenBackground()
        .navigationBarHidden(true)
        .dismissKeyboardOnTap()
        .loadingOverlay(isLoading: budgetVM.isLoading, message: "Saving…")
        .confirmationDialog(
            "Delete Budget",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                Task {
                    await budgetVM.deleteBudget(id: budget.id, userId: appState.userId ?? "")
                    onDeleted()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this budget? This cannot be undone.")
        }
        .alert("Error", isPresented: .constant(budgetVM.errorMessage != nil)) {
            Button("OK") { budgetVM.errorMessage = nil }
        } message: {
            Text(budgetVM.errorMessage ?? "")
        }
        .onAppear { budgetVM.prefillForEdit(budget) }
    }

    // MARK: - Nav bar

    private var navBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.rsDeepGreen)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Text("Edit Budget")
                .font(.system(size: AppTheme.Font.headline, weight: .bold))
                .foregroundColor(.rsTextPrimary)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .frame(height: 56)
        .background(Color.rsBackgroundGreen)
    }

    // MARK: - Current budget summary card

    private var currentBudgetCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("MONTHLY BUDGET")
                .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
                .tracking(0.5)

            HStack(alignment: .center, spacing: 6) {
                Text("$")
                    .font(.system(size: AppTheme.Font.title, weight: .medium))
                    .foregroundColor(.rsTextMuted)
                Text("\(Int(budget.monthlyLimit))")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.rsTextPrimary)
            }

            // Progress indicating how much has been spent
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.rsBorder)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(budget.isOverBudget ? Color.rsError : Color.rsForestGreen)
                        .frame(width: geo.size.width * budget.percentConsumed, height: 6)
                }
            }
            .frame(height: 6)

            Text("You've spent $\(Int(budget.currentSpending)) of this budget so far.")
                .font(.system(size: AppTheme.Font.caption))
                .foregroundColor(.rsTextSecondary)
        }
        .rsCardStyle()
    }

    // MARK: - Amount input

    private var amountInputSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("BUDGET AMOUNT")
                .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
                .tracking(0.5)

            HStack {
                Text("$")
                    .font(.system(size: AppTheme.Font.bodyLg))
                    .foregroundColor(.rsTextSecondary)
                TextField("\(Int(budget.monthlyLimit))", text: $budgetVM.targetAmount)
                    .font(.system(size: AppTheme.Font.bodyLg))
                    .foregroundColor(.rsTextPrimary)
                    .keyboardType(.decimalPad)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .frame(height: AppTheme.Height.input)
            .background(Color.rsCardBackground)
            .cornerRadius(AppTheme.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .stroke(Color.rsBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Notification toggle

    private var notificationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("NOTIFICATIONS")
                .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
                .tracking(0.5)

            HStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                        .fill(Color.rsLightGreen)
                        .frame(width: 44, height: 44)
                    Image(systemName: "bell.badge")
                        .font(.system(size: 18))
                        .foregroundColor(.rsForestGreen)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Over-budget Alert")
                        .font(.system(size: AppTheme.Font.body, weight: .semibold))
                        .foregroundColor(.rsTextPrimary)
                    Text("Notify at 80% and 100%")
                        .font(.system(size: AppTheme.Font.caption))
                        .foregroundColor(.rsTextSecondary)
                }

                Spacer()

                Toggle("", isOn: $budgetVM.overBudgetAlertEnabled)
                    .labelsHidden()
                    .tint(Color.rsForestGreen)
            }
            .padding(AppTheme.Spacing.md)
            .background(Color.rsCardBackground)
            .cornerRadius(AppTheme.Radius.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .stroke(Color.rsBorder, lineWidth: 1)
            )
        }
    }

    // MARK: - Action buttons

    private var buttonsSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Button {
                Task {
                    await budgetVM.updateBudget(budget, userId: appState.userId ?? "")
                    if budgetVM.errorMessage == nil && !budgetVM.isLoading {
                        onSaved()
                    }
                }
            } label: {
                Text("Save Changes")
                    .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.Height.button)
                    .background(Color.rsDeepGreen)
                    .cornerRadius(AppTheme.Radius.button)
            }

            Button { dismiss() } label: {
                Text("Cancel")
                    .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                    .foregroundColor(.rsDeepGreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.Height.button)
                    .background(Color.rsLightGreen)
                    .cornerRadius(AppTheme.Radius.button)
            }

            Button { showDeleteConfirm = true } label: {
                Text("Delete Budget")
                    .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                    .foregroundColor(.rsError)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.Height.button)
                    .background(Color.rsError.opacity(0.08))
                    .cornerRadius(AppTheme.Radius.button)
            }
        }
    }
}


#Preview {
    NavigationStack {
        EditBudgetView(
            budget: Budget.mock(),
            onSaved: {},
            onDeleted: {}
        )
        .environmentObject(BudgetViewModel())
    }
}
