import SwiftUI
import FirebaseAuth

struct RootView: View {
    @StateObject private var dataManager = DataManager()

    var body: some View {
        Group {
            if dataManager.currentUser != nil {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .environmentObject(dataManager)
    }
}

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    @State private var showAddExpense = false

    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: Sayfaların TabBar arkasında kalmaması için padding ekledik
            TabView(selection: $selectedTab) {
                NavigationStack { DashboardView() }
                    .tag(0)
                
                NavigationStack { BudgetFilterView() }
                    .tag(1)

                NavigationStack { PartnerSyncView() }
                    .tag(2)

                NavigationStack { SettingsView() }
                    .tag(3)
            }
            // TabBar'ın yüksekliği kadar içeriklerin altından boşluk bırakıyoruz (Üst üste binmeyi çözen kısım)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 60)
            }

            // MARK: Custom TabBar
            customTabBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom) // Klavye açıldığında TabBar'ın yukarı kaymasını önler
        .sheet(isPresented: $showAddExpense) {
            NavigationStack {
                AddExpenseView()
            }
        }
    }

    private var customTabBar: some View {
        HStack {
            tabButton(icon: "square.grid.2x2", title: "Panel", tag: 0)
            tabButton(icon: "slider.horizontal.3", title: "Filtre", tag: 1)

            // Orta + Butonu
            Button(action: { showAddExpense = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 50, height: 50)
                    .background(Theme.amber)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 3)
            }
            .offset(y: -10)

            tabButton(icon: "heart.text.square", title: "Ortak", tag: 2)
            tabButton(icon: "gearshape", title: "Ayarlar", tag: 3)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 20)
        .background(
            Color.white
                .shadow(color: .black.opacity(0.06), radius: 10, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func tabButton(icon: String, title: String, tag: Int) -> some View {
        Button(action: { selectedTab = tag }) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: selectedTab == tag ? .bold : .regular))
                Text(title)
                    .font(Theme.body(10, weight: selectedTab == tag ? .semibold : .regular))
            }
            .foregroundStyle(selectedTab == tag ? Theme.amber : Theme.slate)
            .frame(maxWidth: .infinity)
        }
    }
}
