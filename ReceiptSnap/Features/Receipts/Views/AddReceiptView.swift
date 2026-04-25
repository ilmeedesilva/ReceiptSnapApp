import SwiftUI
import PhotosUI

struct AddReceiptView: View {

    @EnvironmentObject private var receiptVM: ReceiptViewModel
    @EnvironmentObject private var appState:  AppState
    @Environment(\.dismiss) private var dismiss

    @State private var merchantName:   String           = ""
    @State private var amountText:     String           = ""
    @State private var selectedDate:   Date             = Date()
    @State private var category:       ReceiptCategory  = .food
    @State private var notes:          String           = ""
    @State private var isFavorite:     Bool             = false

    @State private var splitEnabled:       Bool       = false
    @State private var splitWithName:      String     = ""
    @State private var splitContact:       String     = ""
    @State private var splitType:          SplitType  = .equal
    @State private var customAmountYou:    String     = ""
    @State private var customAmountOther:  String     = ""

    @State private var selectedImage:   UIImage?       = nil
    @State private var photosItem:      PhotosPickerItem? = nil
    @State private var showCamera:      Bool           = false

    @State private var showScanning:      Bool = false
    @State private var showSavedSheet:    Bool = false
    @State private var showFullImage:     Bool = false
    @State private var postSaveDest:      PostSaveDestination? = nil

    private enum PostSaveDestination { case dashboard, receipts }

    var parsedAmount: Double { Double(amountText) ?? 0 }

    var splitAmountYou: Double {
        splitType == .equal ? parsedAmount / 2 : (Double(customAmountYou) ?? 0)
    }
    var splitAmountOther: Double {
        splitType == .equal ? parsedAmount / 2 : (Double(customAmountOther) ?? 0)
    }
    var customSplitDifference: Double {
        parsedAmount - splitAmountYou - splitAmountOther
    }
    var isCustomSplitValid: Bool { abs(customSplitDifference) < 0.01 }

    var canSave: Bool { !merchantName.isEmpty && parsedAmount > 0 }


    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        photoUploadSection
                        formSection
                        favoriteSplitSection
                        if splitEnabled { splitDetailsSection }
                        saveButton
                        Spacer().frame(height: AppTheme.Spacing.sm)
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.top, AppTheme.Spacing.sm)
                }
                .rsScreenBackground()
                .navigationTitle("Add Receipt")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.rsDeepGreen)
                        }
                    }
                }
                .dismissKeyboardOnTap()
            }

            if showScanning {
                ScanningOverlayView {
                    showScanning = false
                }
                .ignoresSafeArea()
                .zIndex(999)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showScanning)
        .sheet(isPresented: $showSavedSheet, onDismiss: {
            dismiss()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                switch postSaveDest {
                case .receipts:  NotificationCenter.default.post(name: .switchToReceipts,  object: nil)
                case .dashboard: NotificationCenter.default.post(name: .switchToDashboard, object: nil)
                case nil: break
                }
            }
        }) {
            ReceiptSavedSheet(
                merchantName: merchantName,
                amount: parsedAmount,
                onDashboard: { postSaveDest = .dashboard; showSavedSheet = false },
                onViewAll:   { postSaveDest = .receipts;  showSavedSheet = false }
            )
            .presentationDetents([.medium])
        }
        .onChange(of: photosItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let img  = UIImage(data: data) {
                    selectedImage = img
                    await runOCR(on: img)
                }
                photosItem = nil
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView(image: $selectedImage) {
                showCamera = false
                if let img = selectedImage { Task { await runOCR(on: img) } }
            }
        }
        .fullScreenCover(isPresented: $showFullImage) {
            if let img = selectedImage {
                ZStack(alignment: .topTrailing) {
                    Color.black.ignoresSafeArea()
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Button { showFullImage = false } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
            }
        }
    }


    @ViewBuilder
    private var photoUploadSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .fill(Color.rsDivider)
                    .frame(height: 160)

                if let img = selectedImage {
                    Button { showFullImage = true } label: {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
                            .overlay(
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(6)
                                    .background(Color.black.opacity(0.45))
                                    .clipShape(Circle())
                                    .padding(8),
                                alignment: .bottomTrailing
                            )
                    }
                    .buttonStyle(.plain)
                } else {
                    VStack(spacing: AppTheme.Spacing.sm) {
                        ZStack {
                            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                                .fill(Color.rsLightGreen)
                                .frame(width: 56, height: 56)
                            Image(systemName: "camera.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.rsForestGreen)
                        }
                        Text("Take Photo or Upload")
                            .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                            .foregroundColor(.rsTextPrimary)
                        Text("Snap a picture to auto-fill your expense details")
                            .font(.system(size: AppTheme.Font.caption))
                            .foregroundColor(.rsTextSecondary)
                            .multilineTextAlignment(.center)

                        HStack(spacing: AppTheme.Spacing.sm) {
                            Button {
                                showCamera = true
                            } label: {
                                Label("Camera", systemImage: "camera.fill")
                                    .font(.system(size: AppTheme.Font.body, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 9)
                                    .background(Color.rsDeepGreen)
                                    .cornerRadius(AppTheme.Radius.button)
                            }

                            PhotosPicker(selection: $photosItem, matching: .images) {
                                Text("Upload")
                                    .font(.system(size: AppTheme.Font.body, weight: .semibold))
                                    .foregroundColor(.rsDeepGreen)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 9)
                                    .background(Color.white)
                                    .cornerRadius(AppTheme.Radius.button)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.Radius.button)
                                            .stroke(Color.rsBorder, lineWidth: 1)
                                    )
                            }
                        }
                    }
                    .padding(AppTheme.Spacing.md)
                }
            }

            Text("RECEIPT DETAILS WILL BE DETECTED AUTOMATICALLY")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.orange)
                .tracking(0.4)
        }
    }


    private var formSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {

            VStack(alignment: .leading, spacing: 6) {
                Text("Merchant")
                    .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                    .foregroundColor(.rsTextSecondary)
                TextField("Lunch at Blue Bay", text: $merchantName)
                    .rsInputStyle()
            }

            HStack(spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Amount")
                        .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                        .foregroundColor(.rsTextSecondary)
                    HStack {
                        Text("$")
                            .foregroundColor(.rsTextSecondary)
                            .font(.system(size: AppTheme.Font.body))
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                    }
                    .rsInputStyle()
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Date")
                        .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                        .foregroundColor(.rsTextSecondary)
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .frame(height: AppTheme.Height.input)
                        .background(Color.rsInputBackground)
                        .cornerRadius(AppTheme.Radius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                                .stroke(Color.rsBorder, lineWidth: 1)
                        )
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Category")
                    .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                    .foregroundColor(.rsTextSecondary)
                Menu {
                    ForEach(ReceiptCategory.allCases) { cat in
                        Button(cat.rawValue) { category = cat }
                    }
                } label: {
                    HStack {
                        Text(category.rawValue)
                            .font(.system(size: AppTheme.Font.body))
                            .foregroundColor(.rsTextPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 13))
                            .foregroundColor(.rsTextSecondary)
                    }
                    .rsInputStyle()
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Notes")
                    .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                    .foregroundColor(.rsTextSecondary)
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
                        .foregroundColor(.rsTextPrimary)
                        .frame(height: 90)
                        .padding(.horizontal, AppTheme.Spacing.xs)
                        .scrollContentBackground(.hidden)
                }
                .background(Color.rsInputBackground)
                .cornerRadius(AppTheme.Radius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.md)
                        .stroke(Color.rsBorder, lineWidth: 1)
                )
            }
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
                Toggle("", isOn: $isFavorite)
                    .labelsHidden()
                    .tint(Color.rsForestGreen)
            }
            .rsCardStyle()

            HStack {
                ZStack {
                    Circle()
                        .fill(Color.rsLightGreen)
                        .frame(width: 36, height: 36)
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.rsForestGreen)
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text("Split Expense")
                        .font(.system(size: AppTheme.Font.body, weight: .semibold))
                        .foregroundColor(.rsTextPrimary)
                    Text("Divide cost with others")
                        .font(.system(size: AppTheme.Font.caption))
                        .foregroundColor(.rsTextSecondary)
                }
                Spacer()
                Toggle("", isOn: $splitEnabled)
                    .labelsHidden()
                    .tint(Color.rsForestGreen)
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
                        .font(.system(size: AppTheme.Font.body))
                        .foregroundColor(splitContact.isEmpty ? .rsTextMuted : .rsTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13))
                        .foregroundColor(.rsTextSecondary)
                }
                .rsInputStyle()
            }

            Text("OR")
                .font(.system(size: AppTheme.Font.caption, weight: .bold))
                .foregroundColor(.rsTextMuted)
                .frame(maxWidth: .infinity)

            HStack {
                TextField("Enter name", text: $splitWithName)
                    .font(.system(size: AppTheme.Font.body))
                Image(systemName: "person.badge.plus")
                    .foregroundColor(.rsTextSecondary)
            }
            .rsInputStyle()

            HStack(spacing: 0) {
                ForEach(SplitType.allCases) { type in
                    let isSelected = splitType == type
                    Button { splitType = type } label: {
                        Text(type.rawValue)
                            .font(.system(size: AppTheme.Font.body, weight: .semibold))
                            .foregroundColor(isSelected ? .rsDeepGreen : .rsTextSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(isSelected ? Color.white : Color.clear)
                            .cornerRadius(AppTheme.Radius.sm)
                    }
                }
            }
            .padding(3)
            .background(Color.rsDivider)
            .cornerRadius(AppTheme.Radius.sm + 2)

            if splitType == .custom {
                customSplitSection
            }

            splitPreviewCard
        }
        .rsCardStyle()
    }

    private var customSplitSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                Text("Custom Amounts")
                    .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                    .foregroundColor(.rsTextSecondary)
                    .tracking(0.5)
                Spacer()
                Text("EDITABLE")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.rsForestGreen)
                    .tracking(0.5)
            }

            HStack(spacing: AppTheme.Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("You pay")
                        .font(.system(size: AppTheme.Font.caption))
                        .foregroundColor(.rsTextSecondary)
                    HStack {
                        Text("$")
                            .foregroundColor(.rsTextSecondary)
                        TextField("0.00", text: $customAmountYou)
                            .keyboardType(.decimalPad)
                    }
                    .rsInputStyle()
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(splitContactDisplayName) pays")
                        .font(.system(size: AppTheme.Font.caption))
                        .foregroundColor(.rsTextSecondary)
                    HStack {
                        Text("$")
                            .foregroundColor(.rsTextSecondary)
                        TextField("0.00", text: $customAmountOther)
                            .keyboardType(.decimalPad)
                    }
                    .rsInputStyle()
                }
            }

            if !isCustomSplitValid && !customAmountYou.isEmpty && !customAmountOther.isEmpty {
                HStack {
                    Text("Total must equal receipt amount")
                        .font(.system(size: AppTheme.Font.caption))
                        .foregroundColor(.rsError)
                    Spacer()
                    Text("Difference: \(String(format: "-$%.2f", abs(customSplitDifference)))")
                        .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                        .foregroundColor(.rsError)
                }
            }
        }
    }

    private var splitPreviewCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Live Split Preview")
                    .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                    .foregroundColor(.rsTextSecondary)
                    .tracking(0.5)
                Spacer()
                Text(splitType == .equal ? "50/50 SPLIT" : "CUSTOM SPLIT")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.rsForestGreen)
                    .tracking(0.5)
            }

            HStack(spacing: AppTheme.Spacing.md) {
                splitShareCard(label: "You pay", amount: splitAmountYou)
                splitShareCard(label: "\(splitContactDisplayName) pays", amount: splitAmountOther)
            }
        }
    }

    private func splitShareCard(label: String, amount: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: AppTheme.Font.caption))
                .foregroundColor(.rsTextSecondary)
            Text("$\(String(format: "%.2f", amount))")
                .font(.system(size: AppTheme.Font.headline, weight: .bold))
                .foregroundColor(.rsTextPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.Spacing.sm)
        .background(Color.rsDivider)
        .cornerRadius(AppTheme.Radius.sm)
    }

    private var splitContactDisplayName: String {
        if !splitContact.isEmpty { return splitContact.components(separatedBy: " ").first ?? splitContact }
        if !splitWithName.isEmpty { return splitWithName }
        return "Other"
    }


    private var saveButton: some View {
        Button { handleSave() } label: {
            Text("Save Changes")
                .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                .foregroundColor(canSave ? .white : .rsTextMuted)
                .frame(maxWidth: .infinity)
                .frame(height: AppTheme.Height.button)
                .background(canSave ? Color.rsDeepGreen : Color.rsBorder)
                .cornerRadius(AppTheme.Radius.button)
        }
        .disabled(!canSave)
    }

    private func handleSave() {
        let name = splitContact.isEmpty ? splitWithName : splitContact
        let split: SplitDetail? = splitEnabled ? SplitDetail(
            isEnabled:     true,
            splitWithName: name,
            splitType:     splitType,
            yourAmount:    splitAmountYou,
            otherAmount:   splitAmountOther
        ) : nil

        let receipt = Receipt(
            userId:      appState.userId,
            title:       merchantName,
            category:    category,
            date:        selectedDate,
            amount:      -parsedAmount,
            notes:       notes,
            isFavorite:  isFavorite,
            splitDetail: split
        )

        Task {
            await receiptVM.addReceipt(receipt)
            showSavedSheet = true
        }
    }

    @MainActor
    private func runOCR(on image: UIImage) async {
        withAnimation { showScanning = true }
        let startTime = Date()
        let ocrService = ServiceLocator.shared.ocrService
        do {
            let result = try await ocrService.recognise(image: image)
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed < 3.0 {
                try? await Task.sleep(nanoseconds: UInt64((3.0 - elapsed) * 1_000_000_000))
            }
            withAnimation {
                if let name = result.merchantName, !name.isEmpty { merchantName = name }
                if let amt  = result.amount, amt > 0             { amountText   = String(format: "%.2f", amt) }
                if let date = result.date                         { selectedDate = date }
                showScanning = false
            }
        } catch {
            withAnimation { showScanning = false }
        }
    }
}

private extension View {
    func rsInputStyle() -> some View {
        self
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


private struct ScanningOverlayView: View {

    let onCancel: () -> Void

    @State private var rotationAngle: Double = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .fill(Color.white.opacity(0.08))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.top, 60)
                .padding(.bottom, 260)

            VStack(spacing: AppTheme.Spacing.lg) {
                Spacer()

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.rsForestGreen, lineWidth: 3)
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(rotationAngle))
                    .onAppear {
                        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                            rotationAngle = 360
                        }
                    }

                VStack(spacing: 6) {
                    Text("Scanning receipt...")
                        .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                        .foregroundColor(.white)
                    Text("Detecting amount, date and merchant")
                        .font(.system(size: AppTheme.Font.body))
                        .foregroundColor(Color.white.opacity(0.6))
                }

                HStack(spacing: AppTheme.Spacing.sm) {
                    chip("AI ANALYSIS")
                    chip("OCR ENGINE 2.0")
                }

                Spacer().frame(height: 20)

                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                        .foregroundColor(.rsDeepGreen)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppTheme.Height.button)
                        .background(Color.rsLightGreen)
                        .cornerRadius(AppTheme.Radius.button)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.xl)
            }
        }
    }

    private func chip(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.rsForestGreen)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.rsLightGreen.opacity(0.15))
            .cornerRadius(AppTheme.Radius.pill)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.pill)
                    .stroke(Color.rsLightGreen.opacity(0.5), lineWidth: 1)
            )
    }
}


private struct ReceiptSavedSheet: View {

    let merchantName: String
    let amount:       Double
    let onDashboard:  () -> Void
    let onViewAll:    () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.rsForestGreen.opacity(0.15))
                    .frame(width: 88, height: 88)
                Circle()
                    .fill(Color.rsLightGreen)
                    .frame(width: 64, height: 64)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.rsForestGreen)
            }
            .padding(.top, AppTheme.Spacing.md)

            VStack(spacing: 6) {
                Text("Receipt Saved\nSuccessfully!")
                    .font(.system(size: AppTheme.Font.title, weight: .bold))
                    .foregroundColor(.rsTextPrimary)
                    .multilineTextAlignment(.center)

                Text("Your expense from **\(merchantName)** for $\(String(format: "%.2f", amount)) has been added to your records.")
                    .font(.system(size: AppTheme.Font.body))
                    .foregroundColor(.rsTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.md)
            }

            VStack(spacing: AppTheme.Spacing.sm) {
                Button(action: onDashboard) {
                    Text("Go to Dashboard")
                        .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppTheme.Height.button)
                        .background(Color.rsDeepGreen)
                        .cornerRadius(AppTheme.Radius.button)
                }

                Button(action: onViewAll) {
                    Text("View All Receipts")
                        .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                        .foregroundColor(.rsDeepGreen)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppTheme.Height.button)
                        .background(Color.rsLightGreen)
                        .cornerRadius(AppTheme.Radius.button)
                }
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.bottom, AppTheme.Spacing.md)
        }
    }
}

struct CameraPickerView: UIViewControllerRepresentable {

    @Binding var image: UIImage?
    let onDismiss: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType  = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate    = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPickerView
        init(_ parent: CameraPickerView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.onDismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onDismiss()
        }
    }
}

#Preview {
    AddReceiptView()
        .environmentObject(ReceiptViewModel())
}
