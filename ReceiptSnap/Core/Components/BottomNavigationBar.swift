import SwiftUI

enum MainTab: Int, CaseIterable {
    case dashboard     = 0
    case receipts      = 1
    case add           = 2
    case notifications = 3
    case settings      = 4

    var icon: String {
        switch self {
        case .dashboard:     return "house.fill"
        case .receipts:      return "list.bullet.rectangle.fill"
        case .add:           return "plus"
        case .notifications: return "bell.fill"
        case .settings:      return "gearshape.fill"
        }
    }
}

struct BottomNavigationBar: View {

    @Binding var selectedTab: Int
    let onAddTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .foregroundColor(Color.rsBorder)

            HStack(spacing: 0) {
                ForEach(MainTab.allCases, id: \.rawValue) { tab in
                    if tab == .add {
                        FABButton(action: onAddTap)
                            .frame(maxWidth: .infinity)
                    } else {
                        TabBarItem(
                            icon:       tab.icon,
                            isSelected: selectedTab == tab.rawValue
                        ) {
                            selectedTab = tab.rawValue
                        }
                    }
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(Color.rsCardBackground)
        }
        .background(Color.rsCardBackground)
    }
}

private struct FABButton: View {

    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.rsDeepGreen)
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.rsDeepGreen.opacity(0.35), radius: 8, x: 0, y: 4)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .offset(y: -10)
    }
}


private struct TabBarItem: View {

    let icon:       String
    let isSelected: Bool
    let onTap:      () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 21))
                    .foregroundColor(isSelected ? Color.rsDeepGreen : Color.rsTextMuted)
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isSelected)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
    }
}


#Preview {
    VStack {
        Spacer()
        BottomNavigationBar(selectedTab: .constant(0), onAddTap: {})
    }
    .background(Color.rsBackgroundGreen)
}
