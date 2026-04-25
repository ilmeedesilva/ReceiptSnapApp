
import SwiftUI

struct PasscodeSetupView: View {

    @ObservedObject var viewModel: BiometricViewModel
    let onSuccess: () -> Void

    var body: some View {
        VStack(spacing: 0) {

            Spacer().frame(height: 60)

            // ── Header ───────────────────────────────────────────────────
            Text("Passcode Setup")
                .font(.system(size: AppTheme.Font.largeTitle, weight: .bold))
                .foregroundColor(.rsDeepGreen)

            Spacer().frame(height: 8)

            Text(viewModel.passcodeStep == .create
                 ? "Create a 6-digit passcode to secure your data."
                 : "Confirm your passcode.")
                .font(.system(size: AppTheme.Font.body))
                .foregroundColor(.rsTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.xl)

            Spacer().frame(height: 40)

            // ── Dots ──────────────────────────────────────────────────────
            HStack(spacing: 16) {
                ForEach(0..<6, id: \.self) { i in
                    let filled = viewModel.passcodeStep == .create
                        ? i < viewModel.passcodeDigits.count
                        : i < viewModel.passcodeConfirm.count
                    Circle()
                        .fill(filled ? Color.rsForestGreen : Color.rsBorder)
                        .frame(width: 14, height: 14)
                        .animation(.easeInOut(duration: 0.15), value: filled)
                }
            }

            if let err = viewModel.passcodeError {
                Text(err)
                    .font(.system(size: AppTheme.Font.caption))
                    .foregroundColor(.rsError)
                    .padding(.top, 12)
            }

            Spacer()

            // ── Numpad ────────────────────────────────────────────────────
            NumpadView(
                onDigit: { digit in
                    viewModel.appendDigit(digit)
                    // Auto-advance when 6 digits entered
                    let count = viewModel.passcodeStep == .create
                        ? viewModel.passcodeDigits.count
                        : viewModel.passcodeConfirm.count
                    if count == 6 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if viewModel.advancePasscode() { onSuccess() }
                        }
                    }
                },
                onDelete: viewModel.deleteDigit
            )
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.bottom, 40)
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarHidden(true)
    }
}

private struct NumpadView: View {
    let onDigit:  (String) -> Void
    let onDelete: () -> Void

    private let rows: [[String] ] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["",  "0", "⌫"]
    ]

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: AppTheme.Spacing.md) {
                    ForEach(row, id: \.self) { key in
                        numpadKey(key)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func numpadKey(_ key: String) -> some View {
        if key == "" {
            Color.clear.frame(width: 72, height: 72)
        } else if key == "⌫" {
            Button(action: onDelete) {
                Image(systemName: "delete.left.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.rsDeepGreen)
                    .frame(width: 72, height: 72)
            }
            .accessibilityLabel("Delete")
        } else {
            Button {
                onDigit(key)
            } label: {
                Text(key)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.rsDeepGreen)
                    .frame(width: 72, height: 72)
                    .background(Color.rsBackgroundGreen)
                    .clipShape(Circle())
            }
            .accessibilityLabel(key)
        }
    }
}

#Preview {
    PasscodeSetupView(viewModel: BiometricViewModel(), onSuccess: {})
}
