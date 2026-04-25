import SwiftUI

struct ReceiptsListView: View {

    @EnvironmentObject private var receiptVM: ReceiptViewModel
    @EnvironmentObject private var appState:  AppState

    @State private var navPath       = NavigationPath()
    @State private var showFilter    = false

    var body: some View {
        NavigationStack(path: $navPath) {
            VStack(spacing: 0) {
                searchAndFilterBar
                categoryChips

                if receiptVM.filteredReceipts.isEmpty {
                    emptyState
                } else {
                    receiptsList
                }
            }
            .rsScreenBackground()
            .navigationTitle("Receipts")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: ReceiptRoute.self) { route in
                receiptDestination(for: route)
            }
            .task(id: appState.userId) { await receiptVM.loadReceipts(userId: appState.userId) }
            .onReceive(NotificationCenter.default.publisher(for: .receiptsChanged)) { _ in
                Task { await receiptVM.loadReceipts(userId: appState.userId) }
            }
            .sheet(isPresented: $showFilter) {
                ReceiptFilterSheet(
                    filter: $receiptVM.filter,
                    onApply: { showFilter = false }
                )
                .presentationDetents([.large])
            }
        }
    }

    private var searchAndFilterBar: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.rsTextMuted)
                TextField("Search receipts", text: $receiptVM.searchText)
                    .font(.system(size: AppTheme.Font.body))
                if !receiptVM.searchText.isEmpty {
                    Button { receiptVM.searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.rsTextMuted)
                    }
                }
            }
            .padding(.horizontal, AppTheme.Spacing.sm + 4)
            .frame(height: 42)
            .background(Color.rsInputBackground)
            .cornerRadius(AppTheme.Radius.pill)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.pill)
                    .stroke(Color.rsBorder, lineWidth: 1)
            )

            Button { showFilter = true } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 22))
                    .foregroundColor(receiptVM.filter.isActive ? .rsForestGreen : .rsTextSecondary)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.top, AppTheme.Spacing.sm)
        .padding(.bottom, AppTheme.Spacing.xs)
    }


    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.Spacing.sm) {
                categoryChip(label: "All", category: nil)
                ForEach(ReceiptCategory.allCases) { cat in
                    categoryChip(label: cat.rawValue, category: cat)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
        }
        .padding(.vertical, AppTheme.Spacing.xs)
    }

    private func categoryChip(label: String, category: ReceiptCategory?) -> some View {
        let isSelected = receiptVM.selectedCategory == category
        return Button { receiptVM.selectedCategory = category } label: {
            Text(label)
                .font(.system(size: AppTheme.Font.body, weight: .medium))
                .foregroundColor(isSelected ? .white : .rsTextPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Color.rsForestGreen : Color.rsInputBackground)
                .cornerRadius(AppTheme.Radius.pill)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.pill)
                        .stroke(isSelected ? Color.rsForestGreen : Color.rsBorder, lineWidth: 1)
                )
        }
    }


    private var receiptsList: some View {
        List {
            ForEach(receiptVM.groupedReceipts, id: \.label) { group in
                Section {
                    ForEach(group.items) { receipt in
                        ReceiptListRow(
                            receipt:        receipt,
                            onFavoriteTap:  { receiptVM.toggleFavorite(id: receipt.id) }
                        )
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .onTapGesture {
                            navPath.append(ReceiptRoute.detail(receiptID: receipt.id))
                        }
                    }
                } header: {
                    Text(group.label)
                        .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                        .foregroundColor(.rsTextSecondary)
                        .tracking(0.5)
                        .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.plain)
        .background(Color.rsBackgroundGreen)
        .scrollContentBackground(.hidden)
    }


    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.rsLightGreen)
            Text("No receipts found")
                .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                .foregroundColor(.rsDeepGreen)
            Text(receiptVM.searchText.isEmpty ? "Start by adding your first receipt." : "Try a different search term.")
                .font(.system(size: AppTheme.Font.body))
                .foregroundColor(.rsTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }


    @ViewBuilder
    private func receiptDestination(for route: ReceiptRoute) -> some View {
        switch route {
        case .detail(let id):
            if let receipt = receiptVM.receipt(for: id) {
                ReceiptDetailView(
                    receipt:  receipt,
                    onEdit:   { navPath.append(ReceiptRoute.edit(receiptID: id)) },
                    onDelete: { Task { await receiptVM.deleteReceipt(id: id); navPath.append(ReceiptRoute.deleteSuccess) } },
                    onFavoriteToggle: { receiptVM.toggleFavorite(id: id) }
                )
            }
        case .edit(let id):
            if let receipt = receiptVM.receipt(for: id) {
                EditReceiptView(
                    receipt:  receipt,
                    onSaved: { updated in
                        Task {
                            await receiptVM.updateReceipt(updated)
                            navPath.removeLast()
                        }
                    },
                    onDelete: { Task { await receiptVM.deleteReceipt(id: id); navPath.append(ReceiptRoute.deleteSuccess) } }
                )
            }
        case .deleteSuccess:
            ReceiptDeleteSuccessView {
                navPath = NavigationPath()
            }
        }
    }
}


struct ReceiptListRow: View {

    let receipt:       Receipt
    let onFavoriteTap: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color(hex: receipt.category.colorHex).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: receipt.category.icon)
                    .font(.system(size: 17))
                    .foregroundColor(Color(hex: receipt.category.colorHex))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(receipt.title)
                    .font(.system(size: AppTheme.Font.body, weight: .semibold))
                    .foregroundColor(.rsTextPrimary)
                Text(receipt.formattedDateTime)
                    .font(.system(size: AppTheme.Font.caption))
                    .foregroundColor(.rsTextSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(receipt.formattedAmount)
                    .font(.system(size: AppTheme.Font.body, weight: .semibold))
                    .foregroundColor(.rsTextPrimary)

                Button(action: onFavoriteTap) {
                    Image(systemName: receipt.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 14))
                        .foregroundColor(receipt.isFavorite ? .yellow : .rsTextMuted)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm + 4)
        .background(Color.rsCardBackground)
        .cornerRadius(AppTheme.Radius.card)
        .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, 4)
    }
}


private struct ReceiptFilterSheet: View {

    @Binding var filter: ReceiptFilter
    let onApply: () -> Void

    @State private var localCategories:  Set<ReceiptCategory> = []
    @State private var localStart:       Date?                 = nil
    @State private var localEnd:         Date?                 = nil
    @State private var localFavorites:   Bool                  = false
    @State private var localMinAmount:   String                = ""
    @State private var dateRangeOption:  DateRangeOption?      = nil

    enum DateRangeOption: String, CaseIterable {
        case thisMonth    = "This Month"
        case lastMonth    = "Last Month"
        case last3Months  = "Last 3 Months"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {

                    filterSection("CATEGORY") {
                        FlowRow(spacing: AppTheme.Spacing.sm) {
                            categoryChip("All", nil)
                            ForEach(ReceiptCategory.allCases) { cat in
                                categoryChip(cat.rawValue, cat)
                            }
                        }
                    }

                    filterSection("DATE RANGE") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.Spacing.sm) {
                            ForEach(DateRangeOption.allCases, id: \.rawValue) { option in
                                let isSelected = dateRangeOption == option
                                Button { applyDatePreset(option) } label: {
                                    Text(option.rawValue)
                                        .font(.system(size: AppTheme.Font.body, weight: .medium))
                                        .foregroundColor(isSelected ? .white : .rsTextPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(isSelected ? Color.rsForestGreen : Color.rsDivider)
                                        .cornerRadius(AppTheme.Radius.md)
                                }
                            }
                        }
                    }

                    filterSection("") {
                        HStack {
                            Image(systemName: localFavorites ? "star.fill" : "star")
                                .foregroundColor(localFavorites ? .yellow : .rsTextSecondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Favorites Only")
                                    .font(.system(size: AppTheme.Font.body, weight: .semibold))
                                    .foregroundColor(.rsTextPrimary)
                                Text("Show only starred receipts")
                                    .font(.system(size: AppTheme.Font.caption))
                                    .foregroundColor(.rsTextSecondary)
                            }
                            Spacer()
                            Toggle("", isOn: $localFavorites)
                                .labelsHidden()
                                .tint(.rsForestGreen)
                        }
                        .rsCardStyle()
                    }

                    filterSection("MIN AMOUNT") {
                        HStack {
                            Text("$")
                                .foregroundColor(.rsTextSecondary)
                            TextField("0.00", text: $localMinAmount)
                                .keyboardType(.decimalPad)
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .frame(height: AppTheme.Height.input)
                        .background(Color.rsInputBackground)
                        .cornerRadius(AppTheme.Radius.md)
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(Color.rsBorder, lineWidth: 1))
                    }

                    Button {
                        filter.categories    = localCategories
                        filter.startDate     = localStart
                        filter.endDate       = localEnd
                        filter.favoritesOnly = localFavorites
                        filter.minimumAmount = Double(localMinAmount) ?? 0
                        onApply()
                    } label: {
                        Text("Apply Filters")
                            .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: AppTheme.Height.button)
                            .background(Color.rsDeepGreen)
                            .cornerRadius(AppTheme.Radius.button)
                    }
                    .padding(.bottom, AppTheme.Spacing.md)
                }
                .padding(AppTheme.Spacing.md)
            }
            .navigationTitle("Filter Receipts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { onApply() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.rsTextSecondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Reset") {
                        localCategories  = []
                        localStart       = nil
                        localEnd         = nil
                        localFavorites   = false
                        localMinAmount   = ""
                        dateRangeOption  = nil
                        filter           = ReceiptFilter()
                    }
                    .foregroundColor(.rsForestGreen)
                }
            }
        }
        .presentationDragIndicator(.visible)
        .onAppear {
            localCategories  = filter.categories
            localStart       = filter.startDate
            localEnd         = filter.endDate
            localFavorites   = filter.favoritesOnly
            localMinAmount   = filter.minimumAmount > 0 ? String(format: "%.2f", filter.minimumAmount) : ""
        }
    }

    @ViewBuilder
    private func filterSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            if !title.isEmpty {
                Text(title)
                    .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                    .foregroundColor(.rsTextSecondary)
                    .tracking(0.5)
            }
            content()
        }
    }

    private func categoryChip(_ label: String, _ category: ReceiptCategory?) -> some View {
        let isSelected: Bool = {
            if let cat = category { return localCategories.contains(cat) }
            else                  { return localCategories.isEmpty }
        }()
        return Button {
            if let cat = category {
                if localCategories.contains(cat) { localCategories.remove(cat) }
                else                             { localCategories.insert(cat) }
            } else {
                localCategories = []
            }
        } label: {
            Text(label)
                .font(.system(size: AppTheme.Font.body, weight: .medium))
                .foregroundColor(isSelected ? .white : .rsTextPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.rsForestGreen : Color.rsDivider)
                .cornerRadius(AppTheme.Radius.pill)
        }
    }

    private func applyDatePreset(_ option: DateRangeOption) {
        let cal = Calendar.current
        let now = Date()
        dateRangeOption = option
        switch option {
        case .thisMonth:
            localStart = cal.date(from: cal.dateComponents([.year, .month], from: now))
            localEnd   = nil
        case .lastMonth:
            let startOfThisMonth = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
            localEnd   = cal.date(byAdding: .day, value: -1, to: startOfThisMonth)
            localStart = cal.date(byAdding: .month, value: -1, to: startOfThisMonth)
        case .last3Months:
            localStart = cal.date(byAdding: .month, value: -3, to: now)
            localEnd   = nil
        }
    }
}


private struct FlowRow<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) { content() }
        }
    }
}


#Preview {
    ReceiptsListView()
        .environmentObject(ReceiptViewModel())
}
