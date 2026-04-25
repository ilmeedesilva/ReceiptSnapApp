import SwiftUI

struct ReceiptDetailView: View {

    let receipt:          Receipt
    let onEdit:           () -> Void
    let onDelete:         () -> Void
    let onFavoriteToggle: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirm = false

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    Spacer().frame(height: 48)

                    receiptImageSection
                    formSection
                    favoriteRow
                    actionButtons

                    if let split = receipt.splitDetail, split.isEnabled {
                        splitDetailsCard(split)
                    }

                    Spacer().frame(height: AppTheme.Spacing.sm)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }

            navBar
        }
        .rsScreenBackground()
        .navigationBarHidden(true)
        .confirmationDialog("Delete Receipt?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Receipt", role: .destructive) { onDelete() }
            Button("Cancel",         role: .cancel)       {}
        } message: {
            Text("This action cannot be undone. You will lose all data associated with this receipt.")
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
            Text("Receipt Details")
                .font(.system(size: AppTheme.Font.headline, weight: .bold))
                .foregroundColor(.rsTextPrimary)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .frame(height: 56)
        .background(Color.rsBackgroundGreen)
    }


    private var receiptImageSection: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .fill(Color.rsDivider)
                .frame(height: 200)
                .overlay(
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.rsTextMuted)
                )

            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 32, height: 32)
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundColor(.rsDeepGreen)
            }
            .padding(AppTheme.Spacing.sm)
        }
    }


    private var formSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            readOnlyField(label: "Merchant", value: receipt.title)

            HStack(spacing: AppTheme.Spacing.md) {
                readOnlyField(label: "Amount", value: receipt.formattedAmount)
                readOnlyField(label: "Date",   value: receipt.formattedDate)
            }

            readOnlyField(label: "Category", value: receipt.category.rawValue)

            VStack(alignment: .leading, spacing: 6) {
                Text("Notes")
                    .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                    .foregroundColor(.rsTextSecondary)
                Text(receipt.notes.isEmpty ? "No additional notes" : receipt.notes)
                    .font(.system(size: AppTheme.Font.body))
                    .foregroundColor(receipt.notes.isEmpty ? .rsTextMuted : .rsTextPrimary)
                    .frame(maxWidth: .infinity, minHeight: 60, alignment: .topLeading)
                    .padding(AppTheme.Spacing.sm + 4)
                    .background(Color.rsInputBackground)
                    .cornerRadius(AppTheme.Radius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                            .stroke(Color.rsBorder, lineWidth: 1)
                    )
            }
        }
    }

    private func readOnlyField(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
            Text(value)
                .font(.system(size: AppTheme.Font.body))
                .foregroundColor(.rsTextPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppTheme.Spacing.md)
                .frame(height: AppTheme.Height.input)
                .background(Color.rsInputBackground)
                .cornerRadius(AppTheme.Radius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .stroke(Color.rsBorder, lineWidth: 1)
                )
        }
    }

    private var favoriteRow: some View {
        HStack {
            Image(systemName: receipt.isFavorite ? "star.fill" : "star")
                .foregroundColor(receipt.isFavorite ? .yellow : .rsTextSecondary)
            Text("Mark as Favorite")
                .font(.system(size: AppTheme.Font.body, weight: .medium))
                .foregroundColor(.rsTextPrimary)
            Spacer()
            Toggle("", isOn: .constant(receipt.isFavorite))
                .labelsHidden()
                .tint(Color.rsForestGreen)
                .disabled(true)
                .onTapGesture { onFavoriteToggle() }
        }
        .rsCardStyle()
    }

    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Button(action: onEdit) {
                Text("Edit Receipt")
                    .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.Height.button)
                    .background(Color.rsDeepGreen)
                    .cornerRadius(AppTheme.Radius.button)
            }

            Button { showDeleteConfirm = true } label: {
                Text("Delete Receipt")
                    .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                    .foregroundColor(.rsError)
                    .frame(maxWidth: .infinity)
                    .frame(height: AppTheme.Height.button)
                    .background(Color.rsError.opacity(0.08))
                    .cornerRadius(AppTheme.Radius.button)
            }
        }
    }


    private func splitDetailsCard(_ split: SplitDetail) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("SPLIT DETAILS")
                .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
                .tracking(0.5)

            VStack(alignment: .leading, spacing: 6) {
                Text("Split with \(split.splitWithName.isEmpty ? "someone" : split.splitWithName)")
                    .font(.system(size: AppTheme.Font.body, weight: .semibold))
                    .foregroundColor(.rsTextPrimary)
                Text(split.splitType == .equal ? "50/50 split applied" : "Custom split applied")
                    .font(.system(size: AppTheme.Font.caption))
                    .foregroundColor(.rsTextSecondary)
            }

            Divider()

            HStack {
                Text("You paid")
                    .font(.system(size: AppTheme.Font.body))
                    .foregroundColor(.rsTextSecondary)
                Spacer()
                Text("$\(String(format: "%.2f", split.yourAmount))")
                    .font(.system(size: AppTheme.Font.body, weight: .bold))
                    .foregroundColor(.rsTextPrimary)
            }

            HStack {
                Text("\(split.splitWithName.isEmpty ? "Other" : split.splitWithName) paid")
                    .font(.system(size: AppTheme.Font.body))
                    .foregroundColor(.rsTextSecondary)
                Spacer()
                Text("$\(String(format: "%.2f", split.otherAmount))")
                    .font(.system(size: AppTheme.Font.body, weight: .bold))
                    .foregroundColor(.rsTextPrimary)
            }
        }
        .rsCardStyle()
    }
}


#Preview {
    NavigationStack {
        ReceiptDetailView(
            receipt:          Receipt.mockReceipts().last!,
            onEdit:           {},
            onDelete:         {},
            onFavoriteToggle: {}
        )
    }
}
