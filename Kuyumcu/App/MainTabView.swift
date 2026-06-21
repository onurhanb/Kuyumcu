import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var gameState: GameState
    @State private var selectedTab: Int = 0

    private let items: [TabItem] = [
        TabItem(title: "Ana Sayfa", icon: "house.fill"),
        TabItem(title: "Envanter", icon: "archivebox.fill"),
        TabItem(title: "Dükkanlar", icon: "building.2.fill"),
        TabItem(title: "Yaşam", icon: "star.circle.fill"),
        TabItem(title: "Profil", icon: "person.circle.fill"),
    ]

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    HomeView()
                }
                    .tag(0)

                NavigationStack {
                    InventoryView()
                }
                .tag(1)

                NavigationStack {
                    ShopsView()
                }
                .tag(2)

                NavigationStack {
                    LifestyleView()
                }
                .tag(3)

                NavigationStack {
                    ProfileView()
                }
                .tag(4)
            }
            .toolbar(.hidden, for: .tabBar)

            VStack {
                Spacer()
                customTabBar
                    .padding(.horizontal, GDLSpacing.md)
                    .padding(.bottom, GDLSpacing.sm)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .onAppear {
            configureTabBarAppearance()
        }
    }

    private var customTabBar: some View {
        HStack(spacing: GDLSpacing.xs) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        selectedTab = index
                    }
                } label: {
                    VStack(spacing: GDLSpacing.xxxs) {
                        Image(systemName: item.icon)
                            .font(.system(size: selectedTab == index ? 18 : 17, weight: .semibold))
                            .foregroundColor(selectedTab == index ? .gdlGold : .gdlTextSecondary)
                            .frame(width: 24, height: 24)

                        Text(item.title)
                            .font(.system(size: 10, weight: selectedTab == index ? .semibold : .medium, design: .rounded))
                            .foregroundColor(selectedTab == index ? .gdlTextPrimary : .gdlTextSecondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, GDLSpacing.sm)
                    .background(
                        ZStack {
                            if selectedTab == index {
                                RoundedRectangle(cornerRadius: GDLRadius.lg)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.gdlGold.opacity(0.18),
                                                Color.gdlGold.opacity(0.06)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                RoundedRectangle(cornerRadius: GDLRadius.lg)
                                    .stroke(Color.gdlGold.opacity(0.42), lineWidth: 1)
                            } else {
                                RoundedRectangle(cornerRadius: GDLRadius.lg)
                                    .fill(Color.clear)
                            }
                        }
                    )
                    .scaleEffect(selectedTab == index ? 1.0 : 0.97)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, GDLSpacing.sm)
        .padding(.top, GDLSpacing.xs)
        .padding(.bottom, GDLSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: GDLRadius.xxl)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.gdlBackgroundTop.opacity(0.98),
                            Color.gdlCard.opacity(0.98)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: GDLRadius.xxl)
                .stroke(Color.gdlStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.34), radius: 18, x: 0, y: 8)
    }

    // MARK: - Appearance

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().isHidden = true
    }
}

private struct TabItem {
    let title: String
    let icon: String
}

#Preview {
    MainTabView().environmentObject(GameState())
}
