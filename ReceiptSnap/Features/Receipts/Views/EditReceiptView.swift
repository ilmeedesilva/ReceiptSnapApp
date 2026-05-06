import SwiftUI
import PhotosUI

struct EditReceiptView: View {

    let receipt:  Receipt
    let onSaved:  (Receipt, UIImage?) -> Void
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss


    @State private var merchantName:  String
    @State private var amountText:    String
    @State private var selectedDate:  Date
    @State private var category:      ReceiptCategory
    @State private var notes:         String
    @State private var isFavorite:    Bool

    @State private var splitEnabled:      Bool
    @State private var splitWithName:     String
    @State private var splitContact:      String
    @State private var splitType:         SplitType
    @State private var customAmountYou:   String
    @State private var customAmountOther: String

    @State private var selectedImage:  UIImage?       = nil
    @State private var photosItem:     PhotosPickerItem? = nil
    @State private var showCamera:     Bool           = false
    @State private var showDeleteConfirm = false
    @State private var showSavedToast    = false


    init(receipt: Receipt, onSaved: @escaping (Receipt, UIImage?) -> Void, onDelete: @escaping () -> Void) {
        self.receipt  = receipt
        self.onSaved  = onSaved
        self.onDelete = onDelete

        _merchantName = State(initialValue: receipt.title)
        _amountText   = State(initialValue: String(format: "%.2f", abs(receipt.amount)))
        _selectedDate = State(initialValue: receipt.date)
        _category     = State(initialValue: receipt.category)
        _notes        = State(initialValue: receipt.notes)
        _isFavorite   = State(initialValue: receipt.isFavorite)

        let split = receipt.splitDetail
        _splitEnabled      = State(initialValue: split?.isEnabled ?? false)
        _splitWithName     = State(initialValue: split?.splitWithName ?? "")
        _splitContact      = State(initialValue: split?.splitWithName ?? "")
        _splitType         = State(initialValue: split?.splitType ?? .equal)
        _customAmountYou   = State(initialValue: split?.yourAmount  != nil ? String(format: "%.2f", split!.yourAmount)  : "")
        _customAmountOther = State(initialValue: split?.otherAmount != nil ? String(format: "%.2f", split!.otherAmount) : "")
    }


    var parsedAmount:    Double { Double(amountText) ?? 0 }
    var splitAmountYou:  Double { splitType == .equal ? parsedAmount / 2 : (Double(customAmountYou)   ?? 0) }
    var splitAmountOther: Double { splitType == .equal ? parsedAmount / 2 : (Double(customAmountOther) ?? 0) }
    var canSave:         Bool   { !merchantName.isEmpty && parsedAmount > 0 }

    var contactDisplayName: String {
        if !splitContact.isEmpty   { return splitContact.components(separatedBy: " ").first ?? splitContact }
        if !splitWithName.isEmpty  { return splitWithName }
        return "Other"
    }


    var body: some View {
        ZStack(alignment: .top) {

            if showSavedToast {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.rsForestGreen)
                        Text("Changes Saved!")
                            .font(.system(size: AppTheme.Font.body, weight: .semibold))
                            .foregroundColor(.rsTextPrimary)
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.sm + 4)
                    .background(Color.white)
                    .cornerRadius(AppTheme.Radius.pill)
                    .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
                    Spacer()
                }
                .padding(.top, 70)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(20)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    Spacer().frame(height: 48)

                    photoSection
                    formSection
                    favoriteSplitSection
                    if splitEnabled { splitDetailsSection }
                    actionButtons

                    Spacer().frame(height: AppTheme.Spacing.sm)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }

            navBar
        }
        .rsScreenBackground()
        .navigationBarHidden(true)
        .dismissKeyboardOnTap()
        .confirmationDialog("Delete Receipt?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete Receipt", role: .destructive) { onDelete() }
            Button("Cancel",         role: .cancel) {}
        } message: {
            Text("This action cannot be undone. You will lose all data associated with this receipt.")
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView(image: $selectedImage) { showCamera = false }
        }
        .onChange(of: photosItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self) {
                    selectedImage = UIImage(data: data)
                }
                photosItem = nil
            }
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
            Text("Edit Receipt")
                .font(.system(size: AppTheme.Font.headline, weight: .bold))
                .foregroundColor(.rsTextPrimary)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .frame(height: 56)
        .background(Color.rsBackgroundGreen)
    }


    private var photoSection: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let img = selectedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else if let imageURL = receiptImageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .empty:
                            ZStack {
                                placeholderImage
                                ProgressView()
                            }
                        default:
                            placeholderImage
                        }
                    }
                } else {
                    placeholderImage
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))


            PhotosPicker(selection: $photosItem, matching: .images) {
                HStack(spacing: 4) {
                    Image(systemName: "camera")
                        .font(.system(size: 12))
                    Text("Change Photo")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.55))
                .cornerRadius(AppTheme.Radius.pill)
                .padding(AppTheme.Spacing.sm)
            }
        }
    }

    private var receiptImageURL: URL? {
        guard let imageURL = receipt.imageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              !imageURL.isEmpty else {
            return nil
        }
        return URL(string: imageURL)
    }

    private var placeholderImage: some View {
        RoundedRectangle(cornerRadius: AppTheme.Radius.card)
            .fill(Color.rsDivider)
            .overlay(
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.rsTextMuted)
            )
    }


    private var formSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            editField(label: "Title") {
                TextField("Lunch at Blue Bay", text: $merchantName)
                    .editInputStyle()
            }

            HStack(spacing: AppTheme.Spacing.md) {
                editField(label: "Amount") {
                    HStack {
                        Text("$").foregroundColor(.rsTextSecondary)
                        TextField("0.00", text: $amountText).keyboardType(.decimalPad)
                    }
                    .editInputStyle()
                }
                editField(label: "Date") {
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .frame(height: AppTheme.Height.input)
                        .background(Color.rsInputBackground)
                        .cornerRadius(AppTheme.Radius.md)
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(Color.rsBorder, lineWidth: 1))
                }
            }

            editField(label: "Category") {
                Menu {
                    ForEach(ReceiptCategory.allCases) { cat in
                        Button(cat.rawValue) { category = cat }
                    }
                } label: {
                    HStack {
                        Text(category.rawValue).foregroundColor(.rsTextPrimary)
                        Spacer()
                        Image(systemName: "chevron.down").foregroundColor(.rsTextSecondary).font(.system(size: 13))
                    }
                    .editInputStyle()
                }
            }

            editField(label: "Notes") {
                ZStack(alignment: .topLeading) {
                    if notes.isEmpty {
                        Text("Add additional details...")
                            .foregroundColor(.rsTextMuted)
                            .font(.system(size: AppTheme.Font.body))
                            .padding(.horizontal, AppTheme.Spacing.sm + 4)
                            .padding(.top, AppTheme.Spacing.sm + 2)
                    }
                    TextEditor(text: $notes)
                        .font(.system(size: AppTheme.Font.body))
                        .frame(height: 80)
                        .padding(.horizontal, AppTheme.Spacing.xs)
                        .scrollContentBackground(.hidden)
                }
                .background(Color.rsInputBackground)
                .cornerRadius(AppTheme.Radius.md)
                .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(Color.rsBorder, lineWidth: 1))
            }
        }
    }

    @ViewBuilder
    private func editField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
            content()
        }
    }



    private var favoriteSplitSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundColor(isFavorite ? .yellow : .rsTextSecondary)
                Text("Mark as Favorite")
                    .font(.system(size: AppTheme.Font.body, weight: .medium))
                    .foregroundColor(.rsTextPrimary)
                Spacer()
                Toggle("", isOn: $isFavorite).labelsHidden().tint(.rsForestGreen)
            }
            .rsCardStyle()

            HStack {
                ZStack {
                    Circle().fill(Color.rsLightGreen).frame(width: 36, height: 36)
                    Image(systemName: "person.2.fill").font(.system(size: 14)).foregroundColor(.rsForestGreen)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Split Expense").font(.system(size: AppTheme.Font.body, weight: .semibold)).foregroundColor(.rsTextPrimary)
                    Text("Divide cost with others").font(.system(size: AppTheme.Font.caption)).foregroundColor(.rsTextSecondary)
                }
                Spacer()
                Toggle("", isOn: $splitEnabled).labelsHidden().tint(.rsForestGreen)
            }
            .rsCardStyle()
        }
    }

    private var splitDetailsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            Text("SPLIT WITH")
                .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
                .tracking(0.5)

            Menu {
                ForEach(SplitDetail.mockContacts, id: \.self) { name in
                    Button(name) { splitContact = name }
                }
            } label: {
                HStack {
                    Text(splitContact.isEmpty ? "Select contact" : splitContact)
                        .foregroundColor(splitContact.isEmpty ? .rsTextMuted : .rsTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.down").font(.system(size: 13)).foregroundColor(.rsTextSecondary)
                }
                .editInputStyle()
            }

            Text("OR").font(.system(size: AppTheme.Font.caption, weight: .bold)).foregroundColor(.rsTextMuted).frame(maxWidth: .infinity)

            HStack {
                TextField("Enter name", text: $splitWithName)
                Image(systemName: "person.badge.plus").foregroundColor(.rsTextSecondary)
            }
            .editInputStyle()

            HStack(spacing: 0) {
                ForEach(SplitType.allCases) { type in
                    let sel = splitType == type
                    Button { splitType = type } label: {
                        Text(type.rawValue)
                            .font(.system(size: AppTheme.Font.body, weight: .semibold))
                            .foregroundColor(sel ? .rsDeepGreen : .rsTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(sel ? Color.white : Color.clear)
                            .cornerRadius(AppTheme.Radius.sm)
                    }
                }
            }
            .padding(3)
            .background(Color.rsDivider)
            .cornerRadius(AppTheme.Radius.sm + 2)

            HStack(spacing: AppTheme.Spacing.md) {
                splitAmountTile("You pay",                    splitAmountYou)
                splitAmountTile("\(contactDisplayName) pays", splitAmountOther)
            }
        }
        .rsCardStyle()
    }

    private func splitAmountTile(_ label: String, _ amount: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: AppTheme.Font.caption)).foregroundColor(.rsTextSecondary)
            Text("$\(String(format: "%.2f", amount))").font(.system(size: AppTheme.Font.headline, weight: .bold)).foregroundColor(.rsTextPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.sm)
        .background(Color.rsDivider)
        .cornerRadius(AppTheme.Radius.sm)
    }


    private var actionButtons: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Button {
                let name   = splitContact.isEmpty ? splitWithName : splitContact
                let split: SplitDetail? = splitEnabled ? SplitDetail(
                    isEnabled: true, splitWithName: name, splitType: splitType,
                    yourAmount: splitAmountYou, otherAmount: splitAmountOther
                ) : nil

                let updated = Receipt(
                    id: receipt.id,
                    userId: receipt.userId,
                    title: merchantName,
                    category: category,
                    date: selectedDate,
                    amount: -parsedAmount,
                    notes: notes,
                    isFavorite: isFavorite,
                    tags: receipt.tags,
                    imageURL: receipt.imageURL,
                    splitDetail: split,
                    createdAt: receipt.createdAt,
                    updatedAt: Date()
                )

                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { showSavedToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    onSaved(updated, selectedImage)
                }
            } label: {
                Text("Save Changes")
                    .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: AppTheme.Height.button)
                    .background(canSave ? Color.rsDeepGreen : Color.rsBorder)
                    .cornerRadius(AppTheme.Radius.button)
            }
            .disabled(!canSave)

            Button { dismiss() } label: {
                Text("Cancel")
                    .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                    .foregroundColor(.rsDeepGreen)
                    .frame(maxWidth: .infinity).frame(height: AppTheme.Height.button)
                    .background(Color.rsLightGreen)
                    .cornerRadius(AppTheme.Radius.button)
            }

            Button { showDeleteConfirm = true } label: {
                Text("Delete Receipt")
                    .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                    .foregroundColor(.rsError)
                    .frame(maxWidth: .infinity).frame(height: AppTheme.Height.button)
                    .background(Color.rsError.opacity(0.08))
                    .cornerRadius(AppTheme.Radius.button)
            }
        }
    }
}


private extension View {
    func editInputStyle() -> some View {
        self
            .font(.system(size: AppTheme.Font.body))
            .padding(.horizontal, AppTheme.Spacing.sm + 4)
            .frame(height: AppTheme.Height.input)
            .background(Color.rsInputBackground)
            .cornerRadius(AppTheme.Radius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                    .stroke(Color.rsBorder, lineWidth: 1)
            )
    }
}


#Preview {
    NavigationStack {
        EditReceiptView(
            receipt:  Receipt.mockReceipts().first!,
            onSaved:  { _, _ in },
            onDelete: {}
        )
    }
}