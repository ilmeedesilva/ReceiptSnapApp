import SwiftUI
import PhotosUI

struct UserProfileView: View {

    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var displayName:    String        = ""
    @State private var selectedPhoto:  PhotosPickerItem? = nil
    @State private var profileImage:   UIImage?      = nil
    @State private var isSaving:       Bool          = false
    @State private var showSavedBadge: Bool          = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppTheme.Spacing.lg) {

                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        ZStack(alignment: .bottomTrailing) {
                            avatarView
                            editBadge
                        }
                    }
                    .onChange(of: selectedPhoto) { _, item in
                        Task { await loadPhoto(from: item) }
                    }
                    .padding(.top, AppTheme.Spacing.lg)

                    VStack(spacing: 0) {
                        profileField(label: "DISPLAY NAME", isReadOnly: false) {
                            TextField("Your name", text: $displayName)
                                .font(.system(size: AppTheme.Font.body))
                                .foregroundColor(.rsTextPrimary)
                        }

                        Divider().padding(.leading, AppTheme.Spacing.md)

                        profileField(label: "EMAIL", isReadOnly: true) {
                            Text(appState.currentUser?.email ?? "—")
                                .font(.system(size: AppTheme.Font.body))
                                .foregroundColor(.rsTextSecondary)
                        }

                        Divider().padding(.leading, AppTheme.Spacing.md)

                        profileField(label: "MEMBER SINCE", isReadOnly: true) {
                            Text(memberSinceLabel)
                                .font(.system(size: AppTheme.Font.body))
                                .foregroundColor(.rsTextSecondary)
                        }
                    }
                    .background(Color.rsCardBackground)
                    .cornerRadius(AppTheme.Radius.card)
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)

                    Button {
                        saveProfile()
                    } label: {
                        HStack(spacing: AppTheme.Spacing.sm) {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                                    .scaleEffect(0.85)
                            } else if showSavedBadge {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            Text(showSavedBadge ? "Saved!" : "Save Changes")
                                .font(.system(size: AppTheme.Font.bodyLg, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: AppTheme.Height.button)
                        .background(showSavedBadge ? Color.rsForestGreen : Color.rsDeepGreen)
                        .cornerRadius(AppTheme.Radius.button)
                        .animation(.easeInOut(duration: 0.2), value: showSavedBadge)
                    }
                    .disabled(isSaving)
                }
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.bottom, AppTheme.Spacing.md)
            }
            .rsScreenBackground()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.rsTextSecondary)
                    }
                }
            }
        }
        .onAppear {
            displayName = appState.currentUser?.displayName ?? ""
        }
    }

    private var avatarView: some View {
        Group {
            if let img = profileImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(Color.rsLightGreen)
                        .frame(width: 100, height: 100)
                    Image(systemName: "person.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.rsForestGreen)
                }
            }
        }
    }

    private var editBadge: some View {
        ZStack {
            Circle()
                .fill(Color.rsForestGreen)
                .frame(width: 30, height: 30)
            Image(systemName: "camera.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
        }
        .offset(x: 4, y: 4)
    }

    @ViewBuilder
    private func profileField<Content: View>(
        label: String,
        isReadOnly: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.rsTextMuted)
                .tracking(0.5)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm + 4)
    }


    private var memberSinceLabel: String {
        guard let date = appState.currentUser?.createdAt else { return "—" }
        let f = DateFormatter()
        f.dateStyle = .long
        f.timeStyle = .none
        return f.string(from: date)
    }


    private func saveProfile() {
        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isSaving = true
        appState.currentUser?.displayName = displayName

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isSaving       = false
            showSavedBadge = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showSavedBadge = false
            }
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let img  = UIImage(data: data) {
            await MainActor.run { profileImage = img }
        }
    }
}


#Preview {
    UserProfileView()
        .environmentObject({
            let s = AppState()
            s.signIn(user: AppUser(uid: "p", email: "alex.rivera@example.com", displayName: "Alex Rivera"))
            return s
        }())
}
