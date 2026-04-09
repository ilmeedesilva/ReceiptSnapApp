import SwiftUI

struct OTPInputField: View {

    @Binding var otp: String
    private let count = 6

    @State private var fields: [String] = Array(repeating: "", count: 6)
    @FocusState private var focused: Int?

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ForEach(0..<count, id: \.self) { idx in
                OTPCell(text: $fields[idx], isFocused: focused == idx)
                    .focused($focused, equals: idx)
                    .onChange(of: fields[idx]) { _, newVal in
                        handleChange(at: idx, value: newVal)
                    }
            }
        }
        .onChange(of: otp) { _, newVal in
            if newVal.isEmpty {
                fields = Array(repeating: "", count: count)
                focused = 0
            }
        }
        .onAppear { focused = 0 }
    }

    // MARK: - Input handling
    private func handleChange(at idx: Int, value: String) {
        let digits = value.filter { $0.isNumber }

        if digits.count > 1 {
            let chars = Array(digits.prefix(count))
            for i in 0..<count {
                fields[i] = i < chars.count ? String(chars[i]) : ""
            }
            focused = min(chars.count, count - 1)
        } else {
            fields[idx] = String(digits.prefix(1))
            if !digits.isEmpty, idx < count - 1 {
                focused = idx + 1
            }
        }
        otp = fields.joined()
    }
}

// MARK: - Single Cell
private struct OTPCell: View {
    @Binding var text: String
    let isFocused: Bool

    var body: some View {
        TextField("", text: $text)
            .multilineTextAlignment(.center)
            .font(.system(size: AppTheme.Font.title, weight: .semibold))
            .keyboardType(.numberPad)
            .frame(width: 44, height: 52)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                    .stroke(isFocused ? Color.rsForestGreen : Color.rsBorder,
                            lineWidth: isFocused ? 2 : 1)
            )
            .cornerRadius(AppTheme.Radius.sm)
            .accessibilityLabel("Digit \(text.isEmpty ? "empty" : text)")
    }
}

#Preview {
    OTPInputField(otp: .constant(""))
        .padding()
}
