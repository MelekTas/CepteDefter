import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var dataManager: DataManager
    
    @State private var selectedDate: Date = Date()

    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: selectedDate).capitalized
    }

    private var monthTransactions: [Transaction] {
        dataManager.transactions(for: selectedDate)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.bottom, 16)

                incomeExpenseSummary
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                if !monthTransactions.filter({ $0.type == .gider }).isEmpty {
                    // MARK: Kategori Bazlı Harcama Dağılım Grafiği
                    categoryFinancialChartCard
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                }

                if monthTransactions.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SON İŞLEMLER (GELİR / GİDER)")
                            .font(Theme.body(13, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .tracking(0.5)
                            .padding(.horizontal, 24)
                            .padding(.top, 24)

                        ForEach(monthTransactions) { tx in
                            TransactionRowCard(transaction: tx)
                                .padding(.horizontal, 24)
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .background(Theme.paper.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Menu {
                ForEach(0..<12, id: \.self) { monthOffset in
                    if let date = Calendar.current.date(byAdding: .month, value: -monthOffset, to: Date()) {
                        Button(action: {
                            withAnimation {
                                selectedDate = date
                            }
                        }) {
                            HStack {
                                Text(formatMonth(date))
                                if Calendar.current.isDate(date, equalTo: selectedDate, toGranularity: .month) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(monthLabel.uppercased())
                        .font(Theme.body(12.5, weight: .bold))
                        .tracking(1.2)
                        .foregroundStyle(Theme.sage)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.sage)
                }
                .padding(.vertical, 4)
            }

            Text(dataManager.netRemaining(for: selectedDate).currencyTR)
                .font(Theme.mono(36, weight: .bold))
                .foregroundStyle(Theme.paper)
            
            Text("\(monthLabel.lowercased()) net bakiye")
                .font(Theme.body(12.5))
                .foregroundStyle(Theme.paper.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 28)
        .background(Theme.ink)
        .clipShape(.rect(bottomLeadingRadius: 32, bottomTrailingRadius: 32))
    }

    private var incomeExpenseSummary: some View {
        HStack(spacing: 12) {
            // Gelir Özeti
            HStack {
                Image(systemName: "arrow.down.left.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.sage)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gelir")
                        .font(Theme.body(11))
                        .foregroundStyle(Theme.slate)
                    Text(dataManager.totalIncome(for: selectedDate).currencyTR)
                        .font(Theme.mono(14, weight: .bold))
                        .foregroundStyle(Theme.ink)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Gider Özeti
            HStack {
                Image(systemName: "arrow.up.right.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.clay)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Gider")
                        .font(Theme.body(11))
                        .foregroundStyle(Theme.slate)
                    Text(dataManager.totalSpent(for: selectedDate).currencyTR)
                        .font(Theme.mono(14, weight: .bold))
                        .foregroundStyle(Theme.ink)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Kategori Bazlı Pasta / Halka Grafik Kartı
    private var categoryFinancialChartCard: some View {
        let totalSpent = dataManager.totalSpent(for: selectedDate)
        
        // Seçilen ayın harcamalarını kategorilere göre gruplayıp tutarını hesaplıyoruz
        let categoryData: [(category: ExpenseCategory, amount: Double, ratio: Double, color: Color)] = ExpenseCategory.allCases.compactMap { cat in
            let spent = monthTransactions
                .filter { $0.type == .gider && $0.category == cat }
                .reduce(0) { $0 + $1.amount }
            
            guard spent > 0, totalSpent > 0 else { return nil }
            let ratio = spent / totalSpent
            return (cat, spent, ratio, colorForCategory(cat))
        }.sorted(by: { $0.amount > $1.amount })

        return VStack(spacing: 16) {
            HStack {
                Text("HARCAMA KATEGORİLERİ")
                    .font(Theme.body(12, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .tracking(0.5)
                Spacer()
                Text("\(categoryData.count) Kategori")
                    .font(Theme.body(11, weight: .semibold))
                    .foregroundStyle(Theme.slate)
            }

            HStack(spacing: 20) {
                // Kategori Halka Grafiği
                ZStack {
                    Circle()
                        .stroke(Theme.paperDark, lineWidth: 14)

                    var startAngle: Double = 0.0

                    ForEach(Array(categoryData.enumerated()), id: \.offset) { index, item in
                        let endAngle = startAngle + item.ratio

                        Circle()
                            .trim(from: CGFloat(startAngle), to: CGFloat(endAngle))
                            .stroke(item.color, style: StrokeStyle(lineWidth: 14, lineCap: .butt))
                            .rotationEffect(.degrees(-90))
                            .onAppear {
                                startAngle = endAngle
                            }

                        // Döngü ilerledikçe açıyı güncelliyoruz
                        let _ = { startAngle = endAngle }()
                    }

                    VStack(spacing: 2) {
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.ink)
                    }
                }
                .frame(width: 95, height: 95)

                // Kategoriler ve Yüzdelik Listesi
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(categoryData, id: \.category) { item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 8, height: 8)
                            
                            Text(item.category.rawValue)
                                .font(Theme.body(12, weight: .medium))
                                .foregroundStyle(Theme.ink)
                            
                            Spacer()
                            
                            Text("%\(Int((item.ratio * 100).rounded()))")
                                .font(Theme.mono(12, weight: .bold))
                                .foregroundStyle(Theme.slate)
                        }
                    }
                }
            }
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // Kategoriler İçin Renk Paleti
    private func colorForCategory(_ category: ExpenseCategory) -> Color {
        switch category {
        case .mutfak: return Theme.amber
        case .egitim: return Theme.sage
        case .eglence: return Color.purple
        case .fatura: return Theme.clay
        case .ulasim: return Color.blue
        case .diger: return Theme.slate
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 32))
                .foregroundStyle(Theme.slate)
            Text("Bu ay için işlem bulunamadı")
                .font(Theme.body(14, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Text("Sağ alttaki + butonuyla gelir veya gider ekleyebilirsin.")
                .font(Theme.body(12.5))
                .foregroundStyle(Theme.slate)
        }
        .padding(.top, 60)
        .frame(maxWidth: .infinity)
    }

    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date).capitalized
    }
}

// MARK: - İşlem Kartı (Gelir / Gider Görünümü)

struct TransactionRowCard: View {
    let transaction: Transaction

    var isIncome: Bool { transaction.type == .gelir }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isIncome ? Theme.sage.opacity(0.15) : Theme.clay.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: isIncome ? "arrow.down.left" : "arrow.up.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isIncome ? Theme.sage : Theme.clay)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.note.isEmpty ? transaction.category.rawValue : transaction.note)
                    .font(Theme.body(14, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                
                Text("\(transaction.category.rawValue) · \(transaction.date.formatted(.dateTime.day().month(.abbreviated)))")
                    .font(Theme.body(11.5))
                    .foregroundStyle(Theme.slate)
            }

            Spacer()

            Text("\(isIncome ? "+" : "-")\(transaction.amount.currencyTR)")
                .font(Theme.mono(15, weight: .bold))
                .foregroundStyle(isIncome ? Theme.sage : Theme.ink)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Global Para Birimi Uzantısı

extension Double {
    var currencyTR: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₺"
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.maximumFractionDigits = self.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        return formatter.string(from: NSNumber(value: self)) ?? "₺\(self)"
    }
}

#Preview {
    DashboardView()
        .environmentObject(DataManager())
}
