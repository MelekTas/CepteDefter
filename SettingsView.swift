import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var dataManager: DataManager
    
    @State private var showResetAlert = false
    @State private var showUnpairAlert = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // 1. Profil Kartı
                profileHeaderCard

                // 2. Ortak Hesap & Eşleşen Kişi Kartı
                partnerSection

                // 3. Veri Yönetimi
                sectionGroup(title: "VERİ YÖNETİMİ") {
                    Button(action: { showResetAlert = true }) {
                        HStack {
                            settingLabel(icon: "arrow.counterclockwise.circle.fill", title: "Bütçe Limitlerini Sıfırla")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(Theme.slate)
                        }
                    }
                }

                // 4. Hesap İşlemleri
                sectionGroup(title: "HESAP") {
                    Button(action: { dataManager.signOut() }) {
                        HStack {
                            settingLabel(icon: "rectangle.portrait.and.arrow.right.fill", title: "Çıkış Yap", isDestructive: true)
                            Spacer()
                        }
                    }
                }

                Text("Cepte Defter v1.0.0")
                    .font(Theme.body(11))
                    .foregroundStyle(Theme.slate)
                    .padding(.top, 8)
            }
            .padding(20)
            .padding(.bottom, 100)
        }
        .background(Theme.paper.ignoresSafeArea())
        .navigationTitle("Ayarlar")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Bütçe Limitleri Sıfırlansın mı?", isPresented: $showResetAlert) {
            Button("Sıfırla", role: .destructive) {
                for category in ExpenseCategory.allCases {
                    dataManager.setBudgetLimit(category: category, limit: 0)
                }
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Tüm kategoriler için belirlediğin aylık limitler sıfırlanacaktır.")
        }
        .alert("Eşleşmeyi Bitir", isPresented: $showUnpairAlert) {
            Button("Eşleşmeyi Kopar", role: .destructive) {
                Task {
                    await dataManager.unpairPartner()
                }
            }
            Button("İptal", role: .cancel) {}
        } message: {
            Text("Ortak hesap eşleşmesi sonlandırılacak. Emin misin?")
        }
    }

    private var partnerSection: some View {
        sectionGroup(title: "ORTAK HESAP & EŞLEŞME") {
            VStack(spacing: 14) {
                // Durum Rozeti
                HStack {
                    settingLabel(icon: "person.2.fill", title: "Eşleşme Durumu")
                    Spacer()
                    Text(dataManager.partnerId != nil ? "Eşleşti" : "Bağlı Değil")
                        .font(Theme.body(12, weight: .bold))
                        .foregroundStyle(dataManager.partnerId != nil ? Theme.sage : Theme.clay)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background((dataManager.partnerId != nil ? Theme.sage : Theme.clay).opacity(0.15))
                        .clipShape(Capsule())
                }

                Divider().background(Theme.hairline)

                // Kendi Kodun Bilgisi
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Senin Eşleşme Kodun")
                            .font(Theme.body(11, weight: .semibold))
                            .foregroundStyle(Theme.slate)
                        Text(dataManager.userCode ?? "Yükleniyor...")
                            .font(Theme.mono(15, weight: .bold))
                            .foregroundStyle(Theme.ink)
                    }
                    Spacer()
                }

                // Eğer Birisiyle Eşleşmişse Kart Ve Bitir Butonu Açılır
                if let partnerId = dataManager.partnerId, !partnerId.isEmpty {
                    Divider().background(Theme.hairline)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("EŞLEŞİLEN KULLANICI")
                            .font(Theme.body(10, weight: .bold))
                            .foregroundStyle(Theme.slate)

                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Theme.sage.opacity(0.2))
                                    .frame(width: 38, height: 38)
                                Image(systemName: "person.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Theme.sage)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Ortak Kullanıcı")
                                    .font(Theme.body(13, weight: .semibold))
                                    .foregroundStyle(Theme.ink)
                                Text("ID: \(partnerId)")
                                    .font(Theme.mono(11))
                                    .foregroundStyle(Theme.slate)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Button(action: { showUnpairAlert = true }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "link.badge.plus")
                                    Text("Bitir")
                                }
                                .font(Theme.body(11, weight: .bold))
                                .foregroundStyle(Theme.clay)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Theme.clay.opacity(0.12))
                                .clipShape(Capsule())
                            }
                        }
                        .padding(10)
                        .background(Theme.paper)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    private var profileHeaderCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.amber)
                    .frame(width: 48, height: 48)
                Text(String(dataManager.currentUser?.email?.prefix(1).uppercased() ?? "U"))
                    .font(Theme.body(20, weight: .bold))
                    .foregroundStyle(Theme.ink)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(dataManager.currentUser?.email ?? "Giriş Yapılmadı")
                    .font(Theme.body(14, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("Hesap Aktif")
                    .font(Theme.body(11.5))
                    .foregroundStyle(Theme.slate)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func sectionGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(Theme.body(12, weight: .bold))
                .tracking(1.0)
                .foregroundStyle(Theme.ink)

            VStack { content() }
                .padding(16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func settingLabel(icon: String, title: String, isDestructive: Bool = false) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(isDestructive ? Theme.clay : Theme.ink)
                .frame(width: 24)
            Text(title)
                .font(Theme.body(13.5, weight: .medium))
                .foregroundStyle(isDestructive ? Theme.clay : Theme.ink)
        }
    }
}
