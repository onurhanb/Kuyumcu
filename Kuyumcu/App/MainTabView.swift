import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var gameState: GameState
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {

            HomeView()
                .tabItem {
                    Label("Ana Sayfa", systemImage: "house.fill")
                }
                .tag(0)

            NavigationStack {
                InventoryView()
            }
            .tabItem {
                Label("Envanter", systemImage: "archivebox.fill")
            }
            .tag(1)

            NavigationStack {
                ShopsView()
            }
            .tabItem {
                Label("Dükkanlar", systemImage: "building.2.fill")
            }
            .tag(2)

            NavigationStack {
                LifestyleView()
            }
            .tabItem {
                Label("Yaşam", systemImage: "star.circle.fill")
            }
            .tag(3)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profil", systemImage: "person.circle.fill")
            }
            .tag(4)
        }
        .accentColor(.gdlGold)
        .onAppear {
            configureTabBarAppearance()
        }
    }

    // MARK: - Appearance

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.gdlCard)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.gdlGold)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.gdlGold)]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.gdlTextSecondary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.gdlTextSecondary)]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    MainTabView().environmentObject(GameState())
}
