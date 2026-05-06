import SwiftUI

struct SetBudgetView: View {

    @EnvironmentObject private var budgetVM: BudgetViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let onSaved: () -> Void
    let onViewHistory: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {

                    Spacer().frame(height: 48)

                    headerSection

                    VStack(spacing: AppTheme.Spacing.md) {
                        monthPickerCard
                        amountCard
                    }

                    buttonsSection

                    Button { onViewHistory() } label: {
                        Text("View Budget Activity")
                            .font(.system(size: AppTheme.Font.body, weight: .medium))
                            .foregroundColor(.rsForestGreen)
                    }

                    Spacer().frame(height: AppTheme.Spacing.sm)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }

            navBar
        }
        .rsScreenBackground()
        .navigationBarHidden(true)
        .dismissKeyboardOnTap()
        .loadingOverlay(isLoading: budgetVM.isLoading, message: "Saving budget…")
        .alert("Error", isPresented: .constant(budgetVM.errorMessage != nil)) {
            Button("OK") { budgetVM.errorMessage = nil }
        } message: {
            Text(budgetVM.errorMessage ?? "")
        }
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
            Text("Set Budget")
                .font(.system(size: AppTheme.Font.headline, weight: .bold))
                .foregroundColor(.rsTextPrimary)
            Spacer()
            Color.clear.frame(width: 44, height: 44) 
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .frame(height: 56)
        .background(Color.rsBackgroundGreen)
    }


    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.rsLightGreen)
                    .frame(width: 72, height: 72)
                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.rsForestGreen)
            }
            Text("Define Your Limit")
                .font(.system(size: AppTheme.Font.title, weight: .bold))
                .foregroundColor(.rsTextPrimary)
            Text("Plan your spending for the upcoming month.")
                .font(.system(size: AppTheme.Font.body))
                .foregroundColor(.rsTextSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, AppTheme.Spacing.sm)
    }


    private var monthPickerCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("TARGET MONTH")
                .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
                .tracking(0.5)

            Menu {
                ForEach(budgetVM.availableMonths, id: \.self) { month in
                    Button(month) { budgetVM.selectedMonth = month }
                }
            } label: {
                HStack {
                    Text(budgetVM.selectedMonth)
                        .font(.system(size: AppTheme.Font.bodyLg))
                        .foregroundColor(.rsTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13))
                        .foregroundColor(.rsTextSecondary)
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
    }


    private var amountCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("TARGET AMOUNT")
                    .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                    .foregroundColor(.rsTextSecondary)
                    .tracking(0.5)

                HStack(alignment: .center, spacing: 6) {
                    Text("$")
                        .font(.system(size: AppTheme.Font.title, weight: .medium))
                        .foregroundColor(.rsTextMuted)
                    TextField("0", text: $budgetVM.targetAmount)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.rsTextPrimary)
                        .keyboardType(.decimalPad)
                }
                .padding(.top, AppTheme.Spacing.xs)

                Rectangle()
                    .fill(Color.rsBorder)
                    .frame(height: 1)
            }
            .padding(AppTheme.Spacing.md)
            .background(Color.rsCardBackground)
            .cornerRadius(AppTheme.Radius.card)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .stroke(Color.rsBorder, lineWidth: 1)
            )

            HStack(spacing: AppTheme.Spacing.sm) {
                ForEach([500, 1000, 2500, 5000], id: \.self) { preset in
                    let isSelected = budgetVM.targetAmount == "\(preset)"
                    Button { budgetVM.targetAmount = "\(preset)" } label: {
                        Text("\(preset)")
                            .font(.system(size: AppTheme.Font.body, weight: .medium))
                            .foregroundColor(isSelected ? .rsForestGreen : .rsTextSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color.rsLightGreen : Color.white)
                            .cornerRadius(AppTheme.Radius.pill)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.pill)
                                    .stroke(isSelected ? Color.rsForestGreen : Color.rsBorder, lineWidth: 1)
                            )
                    }
                }
            }
        }
    }


    private var buttonsSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Button {
                Task {
                    await budgetVM.saveBudget(userId: appState.userId ?? "")
                    if budgetVM.errorMessage == nil && !budgetVM.isLoading {
                        onSaved()
                    }
                }
            } label: {
                Text("Save Budget")
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
        }
    }
}


#Preview {
    NavigationStack {
        SetBudgetView(onSaved: {}, onViewHistory: {})
            .environmentObject(BudgetViewModel())
    }
}