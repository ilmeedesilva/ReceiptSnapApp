
import SwiftUI

struct RecentReceiptsListView: View {

    let receipts: [Receipt]
    let onSeeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {

            // Section header
            HStack {
                Text("Recent Receipts")
                    .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                    .foregroundColor(.rsTextPrimary)
                Spacer()
                Button(action: onSeeAll) {
                    Text("See All")
                        .font(.system(size: AppTheme.Font.body, weight: .medium))
                        .foregroundColor(.rsForestGreen)
                }
            }

            // Receipt rows inside a single card
            VStack(spacing: 0) {
                ForEach(Array(receipts.enumerated()), id: \.element.id) { index, receipt in
                    ReceiptRowView(receipt: receipt)

                    if index < receipts.count - 1 {
                        Divider()
                            .padding(.horizontal, AppTheme.Spacing.md)
                    }
                }
            }
            .background(Color.rsCardBackground)
            .cornerRadius(AppTheme.Radius.card)
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }
}


private struct ReceiptRowView: View {

    let receipt: Receipt

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {

            // Category icon — colored per category (same as Receipts tab)
            ZStack {
                Circle()
                    .fill(Color(hex: receipt.category.colorHex).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: receipt.category.icon)
                    .foregroundColor(Color(hex: receipt.category.colorHex))
                    .font(.system(size: 16))
            }

            // Title + meta
            VStack(alignment: .leading, spacing: 2) {
                Text(receipt.title)
                    .font(.system(size: AppTheme.Font.body, weight: .semibold))
                    .foregroundColor(.rsTextPrimary)
                Text("\(receipt.category.rawValue) • \(receipt.formattedDate)")
                    .font(.system(size: AppTheme.Font.caption))
                    .foregroundColor(.rsTextSecondary)
            }

            Spacer()

            // Amount
            Text(receipt.formattedAmount)
                .font(.system(size: AppTheme.Font.body, weight: .semibold))
                .foregroundColor(receipt.amount < 0 ? .rsTextPrimary : .rsForestGreen)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm + 4)
    }
}

#Preview {
    RecentReceiptsListView(receipts: Receipt.mockReceipts(), onSeeAll: {})
        .padding()
        .background(Color.rsBackgroundGreen)
}
