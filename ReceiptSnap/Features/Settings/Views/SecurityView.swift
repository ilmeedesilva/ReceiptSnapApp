import SwiftUI

struct SecurityView: View {

    @StateObject private var vm    = SecurityViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showPasscodeEntry = false

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    Spacer().frame(height: 56)

                    biometricsSection
                    passcodeSection
                    advancedSection

                    Spacer().frame(height: AppTheme.Spacing.sm)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
            }
            .background(Color.rsBackgroundGreen)

            navBar
        }
        .navigationBarHidden(true)
        .overlay {
            if vm.showFaceIDScanning {
                FaceIDScanningOverlay {
                    vm.showFaceIDScanning = false
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: vm.showFaceIDScanning)
            }
        }
        .sheet(isPresented: $showPasscodeEntry) {
            EnterPasscodeView()
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
            Text("Security & Access")
                .font(.system(size: AppTheme.Font.headline, weight: .bold))
                .foregroundColor(.rsTextPrimary)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, AppTheme.Spacing.sm)
        .frame(height: 56)
        .background(Color.rsBackgroundGreen)
    }


    private var biometricsSection: some View {
        securityGroup(header: "BIOMETRICS") {
            HStack(spacing: AppTheme.Spacing.md) {
                securityIconBox(sfSymbol: "faceid", colorHex: "3B82F6")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Face ID")
                        .font(.system(size: AppTheme.Font.body))
                        .foregroundColor(.rsTextPrimary)
                    Text("Use Face ID to unlock the app")
                        .font(.system(size: AppTheme.Font.caption))
                        .foregroundColor(.rsTextSecondary)
                }
                Spacer()
                Toggle("", isOn: Binding(
                    get:  { vm.isFaceIDEnabled },
                    set:  { _ in vm.toggleFaceID() }
                ))
                .labelsHidden()
                .tint(.rsForestGreen)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm + 4)

            Divider().padding(.leading, 56)

            Button { vm.startFaceIDReset() } label: {
                HStack(spacing: AppTheme.Spacing.md) {
                    securityIconBox(sfSymbol: "arrow.counterclockwise", colorHex: "6366F1")
                    Text("Reset Face ID")
                        .font(.system(size: AppTheme.Font.body))
                        .foregroundColor(.rsTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundColor(.rsTextMuted)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm + 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }


    private var passcodeSection: some View {
        securityGroup(header: "PASSCODE") {

            Button { showPasscodeEntry = true } label: {
                HStack(spacing: AppTheme.Spacing.md) {
                    securityIconBox(sfSymbol: "lock.fill", colorHex: "10B981")
                    Text("Change Passcode")
                        .font(.system(size: AppTheme.Font.body))
                        .foregroundColor(.rsTextPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundColor(.rsTextMuted)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.sm + 4)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Divider().padding(.leading, 56)

            HStack(spacing: AppTheme.Spacing.md) {
                securityIconBox(sfSymbol: "clock.fill", colorHex: "F59E0B")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Require Passcode")
                        .font(.system(size: AppTheme.Font.body))
                        .foregroundColor(.rsTextPrimary)
                    Text("Immediately on lock")
                        .font(.system(size: AppTheme.Font.caption))
                        .foregroundColor(.rsTextSecondary)
                }
                Spacer()
                Toggle("", isOn: $vm.requirePasscodeImmediately)
                    .labelsHidden()
                    .tint(.rsForestGreen)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm + 4)
        }
    }


    private var advancedSection: some View {
        securityGroup(header: "ADVANCED") {
            HStack(spacing: AppTheme.Spacing.md) {
                securityIconBox(sfSymbol: "shield.lefthalf.filled", colorHex: "EF4444")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Two-Factor Authentication")
                        .font(.system(size: AppTheme.Font.body))
                        .foregroundColor(.rsTextPrimary)
                    Text("Add extra security to your account")
                        .font(.system(size: AppTheme.Font.caption))
                        .foregroundColor(.rsTextSecondary)
                }
                Spacer()
                Toggle("", isOn: $vm.isTwoFAEnabled)
                    .labelsHidden()
                    .tint(.rsForestGreen)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm + 4)
        }
    }


    private func securityGroup<Content: View>(
        header: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(header)
                .font(.system(size: AppTheme.Font.caption, weight: .semibold))
                .foregroundColor(.rsTextSecondary)
                .tracking(0.5)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(Color.white)
            .cornerRadius(AppTheme.Radius.card)
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        }
    }

    private func securityIconBox(sfSymbol: String, colorHex: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                .fill(Color(hex: colorHex))
                .frame(width: 34, height: 34)
            Image(systemName: sfSymbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
        }
    }
}


private struct FaceIDScanningOverlay: View {

    let onDismiss: () -> Void

    @State private var scanning = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.lg) {
                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.rsForestGreen, lineWidth: 3)
                        .frame(width: 200, height: 240)

                    VStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "faceid")
                            .font(.system(size: 72))
                            .foregroundColor(.rsLightGreen)
                            .scaleEffect(scanning ? 1.08 : 1.0)
                            .animation(
                                .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                                value: scanning
                            )

                        Text("Scanning…")
                            .font(.system(size: AppTheme.Font.body, weight: .medium))
                            .foregroundColor(.rsLightGreen)
                    }
                }

                Spacer()

                Text("Look at your iPhone to authenticate")
                    .font(.system(size: AppTheme.Font.body))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xl)

                Button { onDismiss() } label: {
                    Text("Cancel")
                        .font(.system(size: AppTheme.Font.body, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.Spacing.md)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(AppTheme.Radius.card)
                }
                .padding(.horizontal, AppTheme.Spacing.xl)
                .padding(.bottom, AppTheme.Spacing.xl)
            }
        }
        .onAppear { scanning = true }
    }
}


struct EnterPasscodeView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var digits: [String] = ["", "", "", "", "", ""]
    @State private var activeIndex = 0
    @State private var shake = false

    private let pinLength = 6

    var body: some View {
        ZStack {
            Color.rsDeepGreen.ignoresSafeArea()

            VStack(spacing: AppTheme.Spacing.xl) {
                Spacer()

                Image(systemName: "lock.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundColor(.white)

                Text("Enter Passcode")
                    .font(.system(size: AppTheme.Font.title, weight: .bold))
                    .foregroundColor(.white)

                Text("Enter your 6-digit passcode")
                    .font(.system(size: AppTheme.Font.body))
                    .foregroundColor(.white.opacity(0.7))

                HStack(spacing: 16) {
                    ForEach(0..<pinLength, id: \.self) { i in
                        Circle()
                            .fill(digits[i].isEmpty ? Color.white.opacity(0.3) : Color.white)
                            .frame(width: 14, height: 14)
                    }
                }
                .padding(.top, AppTheme.Spacing.sm)
                .offset(x: shake ? -10 : 0)
                .animation(shake
                    ? .default.repeatCount(4, autoreverses: true).speed(4)
                    : .default,
                    value: shake)

                Spacer()

                numpad
                    .padding(.horizontal, AppTheme.Spacing.xl)

                Button { dismiss() } label: {
                    Text("Cancel")
                        .font(.system(size: AppTheme.Font.body, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, AppTheme.Spacing.xl)
            }
        }
    }

    private var numpad: some View {
        let keys: [[String]] = [
            ["1","2","3"],
            ["4","5","6"],
            ["7","8","9"],
            ["","0","⌫"]
        ]
        return VStack(spacing: AppTheme.Spacing.md) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: AppTheme.Spacing.md) {
                    ForEach(row, id: \.self) { key in
                        if key.isEmpty {
                            Color.clear.frame(maxWidth: .infinity).frame(height: 64)
                        } else {
                            Button { handleKey(key) } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.12))
                                        .frame(width: 76, height: 76)
                                    Text(key)
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }

    private func handleKey(_ key: String) {
        if key == "⌫" {
            guard activeIndex > 0 else { return }
            activeIndex -= 1
            digits[activeIndex] = ""
        } else {
            guard activeIndex < pinLength else { return }
            digits[activeIndex] = key
            activeIndex += 1
            if activeIndex == pinLength {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismiss()
                }
            }
        }
    }
}


#Preview {
    NavigationStack {
        SecurityView()
    }
}
