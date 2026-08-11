import SwiftUI

struct BudgetFilterView: View {
    @EnvironmentObject var dataManager: DataManager
    @State private var filter = TransactionFilter()
    @State private var editingCategory: ExpenseCategory?
    @State private var limitInput: String = ""

    private var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date()

        return dataManager.transactions.filter { tx in
            switch filter.dateRange {
            case .week:
                guard let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) else { return true }
                if tx.date < weekAgo || tx.date > now { return false }
            case .month:
                if !calendar.isDate(tx.date, equalTo: now, toGranularity: .month) { return false }
            case .year:
                if !calendar.isDate(tx.date, equalTo: now, toGranularity: .year) { return false }
            case .custom:
                break // tüm zamanlar
            }

            if !filter.categories.isEmpty && !filter.categories.contains(tx.category) { return false }
            if let type = filter.type, tx.type != type { return false }

            let query = filter.searchText.trimmingCharacters(in: .whitespaces)
            if !query.isEmpty && !tx.note.localizedCaseInsensitiveContains(query) { return false }

            return true
        }
        .sorted { $0.date > $1.date }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("BÜTÇE LİMİTLERİ")
                            .font(Theme.body(13, weight: .bold))
                            .tracking(0.5)
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text("Bir kategoriye dokunarak limit belirle")
                            .font(Theme.body(10.5))
                            .foregroundStyle(Theme.slate)
                    }

                    ForEach(dataManager.allCategoryBudgets) { budget in
                        BudgetLimitRow(budget: budget) {
                            editingCategory = budget.category
                            limitInput = budget.monthlyLimit > 0 ? String(format: "%.0f", budget.monthlyLimit) : ""
                        }
                    }
                }

                Divider().background(Theme.hairline)

                VStack(alignment: .leading, spacing: 16) {
                    Text("FİLTRELE")
                        .font(Theme.body(13, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(Theme.ink)

                    dateRangeChips
                    categoryChips
                    typeSegmented
                    searchField
                }

                Divider().background(Theme.hairline)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("İŞLEMLER")
                            .font(Theme.body(13, weight: .bold))
                            .tracking(0.5)
                            .foregroundStyle(Theme.ink)
                        Spacer()
                        Text("\(filteredTransactions.count) sonuç")
                            .font(Theme.body(11.5))
                            .foregroundStyle(Theme.slate)
                    }

                    if filteredTransactions.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "tray")
                                .font(.system(size: 26))
                                .foregroundStyle(Theme.slate)
                            Text("Bu filtrelere uyan işlem bulunamadı.")
                                .font(Theme.body(12.5))
                                .foregroundStyle(Theme.slate)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                    } else {
                        ForEach(filteredTransactions) { tx in
                            transactionRow(tx)
                        }
                    }
                }
            }
            .padding(24)
            .padding(.bottom, 40)
        }
        .background(Theme.paper.ignoresSafeArea())
        .navigationTitle("Bütçe & Filtrele")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            editingCategory?.rawValue ?? "Limit Belirle",
            isPresented: Binding(
                get: { editingCategory != nil },
                set: { isPresented in if !isPresented { editingCategory = nil } }
            )
        ) {
            TextField("Örn. 1500", text: $limitInput)
                .keyboardType(.decimalPad)
            Button("Kaydet") {
                if let category = editingCategory,
                   let value = Double(limitInput.replacingOccurrences(of: ",", with: ".")) {
                    dataManager.setBudgetLimit(category: category, limit: value)
                }
                editingCategory = nil
            }
            Button("İptal", role: .cancel) { editingCategory = nil }
        } message: {
            Text("Bu kategori için aylık bütçe limitini girin.")
        }
    }

    private var dateRangeChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TransactionFilter.DateRange.allCases) { range in
                    let isSelected = filter.dateRange == range
                    Button(range.rawValue) { filter.dateRange = range }
                        .font(Theme.body(12.5, weight: .semibold))
                        .foregroundStyle(isSelected ? Theme.paper : Theme.ink)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(isSelected ? Theme.ink : Color.white)
                        .clipShape(Capsule())
                        .overlay { Capsule().stroke(isSelected ? .clear : Theme.hairline, lineWidth: 1) }
                }
            }
        }
    }

    private var categoryChips: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 10)], spacing: 10) {
            ForEach(ExpenseCategory.allCases) { cat in
                let isSelected = filter.categories.contains(cat)
                Button(action: { toggle(cat) }) {
                    Text(isSelected ? "✓ \(cat.rawValue)" : cat.rawValue)
                        .font(Theme.body(12.5, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(isSelected ? Theme.amber.opacity(0.15) : Color.white)
                        .clipShape(Capsule())
                        .overlay {
                            Capsule().stroke(isSelected ? Theme.amber : Theme.hairline, lineWidth: isSelected ? 1.4 : 1)
                        }
                }
            }
        }
    }

    private var typeSegmented: some View {
        Picker("Tür", selection: Binding(
            get: { filter.type?.rawValue ?? "Tümü" },
            set: { newValue in filter.type = TransactionType(rawValue: newValue) }
        )) {
            Text("Tümü").tag("Tümü")
            ForEach(TransactionType.allCases) { type in
                Text(type.rawValue).tag(type.rawValue)
            }
        }
        .pickerStyle(.segmented)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(Theme.slate)
            TextField("Açıklamada ara...", text: $filter.searchText)
                .font(Theme.body(13.5))
        }
        .padding(16)
        .background(Color.white)
        .overlay { RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1) }
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func transactionRow(_ tx: Transaction) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Theme.paperDark).frame(width: 36, height: 36)
                Image(systemName: tx.category.iconName)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.ink)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(tx.note.isEmpty ? tx.category.rawValue : tx.note)
                    .font(Theme.body(13.5, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text("\(tx.category.rawValue) · \(tx.date.formatted(.dateTime.day().month(.abbreviated)))")
                    .font(Theme.body(11))
                    .foregroundStyle(Theme.slate)
            }
            Spacer()
            Text((tx.type == .gider ? "-" : "+") + tx.amount.currencyTR)
                .font(Theme.mono(13, weight: .bold))
                .foregroundStyle(tx.type == .gider ? Theme.clay : Theme.sage)
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func toggle(_ cat: ExpenseCategory) {
        if filter.categories.contains(cat) {
            filter.categories.remove(cat)
        } else {
            filter.categories.insert(cat)
        }
    }
}

private struct BudgetLimitRow: View {
    let budget: CategoryBudget
    var onTap: () -> Void

    var statusColor: Color { Theme.statusColor(for: budget.percent) }
    var isOverLimit: Bool { budget.monthlyLimit > 0 && budget.percent >= 1.0 }
    var hasLimit: Bool { budget.monthlyLimit > 0 }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(budget.category.rawValue)")
                        .font(Theme.body(14, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    if hasLimit {
                        Text("\(budget.spent.currencyTR) / \(budget.monthlyLimit.currencyTR)")
                            .font(Theme.mono(12.5))
                            .foregroundStyle(Theme.slate)
                    } else {
                        Text("Limit belirlenmedi")
                            .font(Theme.body(12))
                            .foregroundStyle(Theme.slate)
                        Image(systemName: "pencil.circle")
                            .foregroundStyle(Theme.amber)
                    }
                }

                if hasLimit {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.paperDark).frame(height: 8)
                            Capsule().fill(statusColor)
                                .frame(width: geo.size.width * min(budget.percent, 1), height: 8)
                        }
                    }
                    .frame(height: 8)

                    HStack {
                        if isOverLimit {
                            Label("Limit aşıldı, dikkatli ol", systemImage: "exclamationmark.triangle.fill")
                                .font(Theme.body(11.5, weight: .semibold))
                                .foregroundStyle(Theme.clay)
                        }
                        Spacer()
                        Text("%\(Int((budget.percent * 100).rounded()))")
                            .font(Theme.body(11, weight: .bold))
                            .foregroundStyle(statusColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 3)
                            .background(statusColor.opacity(0.15))
                            .clipShape(Capsule())
                    }
                } else {
                    Capsule()
                        .strokeBorder(Theme.hairline, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        .frame(height: 8)
                }
            }
            .overlay(alignment: .leading) {
                if isOverLimit {
                    Rectangle().fill(Theme.clay).frame(width: 3).padding(.vertical, -2)
                }
            }
            .padding(.leading, isOverLimit ? 10 : 0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { BudgetFilterView().environmentObject(DataManager()) }
}
