import SwiftUI

struct RootView: View {
    @State private var isAuthenticated = false

    var body: some View {
        if isAuthenticated {
            MainTabView()
        } else {
            AuthView(onAuthenticated: { isAuthenticated = true })
        }
    }
}

struct MainTabView: View {
    @State private var showAddExpense = false
    @State private var transactions: [Transaction] = Transaction.sample

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView()
                    .navigationBarHidden(true)
            }
            .tabItem { Label("Panel", systemImage: "square.grid.2x2") }

            NavigationStack {
                BudgetFilterView()
            }
            .tabItem { Label("Filtrele", systemImage: "slider.horizontal.3") }

            NavigationStack {
                SettingsPlaceholderView()
            }
            .tabItem { Label("Ayarlar", systemImage: "gearshape") }
        }
        .tint(Theme.amber)
        .overlay(alignment: .bottom) {
            Button(action: { showAddExpense = true }) {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 60, height: 60)
                    .background(Theme.amber)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
            }
            .padding(.bottom, 28)
        }
        .sheet(isPresented: $showAddExpense) {
            NavigationStack {
                AddExpenseView { newTransaction in
                    transactions.append(newTransaction)
                }
            }
        }
    }
}

private struct SettingsPlaceholderView: View {
    var body: some View {
        List {
            Section("Hesap") {
                Label("Profil", systemImage: "person.circle")
                Label("Şifre Değiştir", systemImage: "lock")
            }
            Section("Bildirimler") {
                Label("Bütçe Uyarıları", systemImage: "bell.badge")
            }
            Section {
                Label("Çıkış Yap", systemImage: "rectangle.portrait.and.arrow.right")
                    .foregroundStyle(Theme.clay)
            }
        }
        .navigationTitle("Ayarlar")
    }
}

#Preview {
    RootView()
}
