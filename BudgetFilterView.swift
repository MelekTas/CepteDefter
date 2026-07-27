import SwiftUI

struct BudgetFilterView: View {
    var budgets: [CategoryBudget] = CategoryBudget.sample
    @State private var filter = TransactionFilter()
    var onApply: (TransactionFilter) -> Void = { _ in }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("BÜTÇE LİMİTLERİ")
                        .font(Theme.body(13, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(Theme.ink)

                    ForEach(budgets) { budget in
                        BudgetLimitRow(budget: budget)
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
            }
            .padding(24)
            .padding(.bottom, 100)
        }
        .background(Theme.paper.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            applyButton
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
        }
        .navigationTitle("Bütçe & Filtrele")
        .navigationBarTitleDisplayMode(.inline)
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

    private var applyButton: some View {
        Button(action: { onApply(filter) }) {
            Text("Filtreleri Uygula")
                .font(Theme.body(15, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Theme.amber)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
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
    var statusColor: Color { Theme.statusColor(for: budget.percent) }
    var isOverLimit: Bool { budget.percent >= 1.0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(budget.category.emoji) \(budget.category.rawValue)")
                    .font(Theme.body(14, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("\(budget.spent.currencyTR) / \(budget.monthlyLimit.currencyTR)")
                    .font(Theme.mono(12.5))
                    .foregroundStyle(Theme.slate)
            }

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
        }
        .overlay(alignment: .leading) {
            if isOverLimit {
                Rectangle().fill(Theme.clay).frame(width: 3).padding(.vertical, -2)
            }
        }
        .padding(.leading, isOverLimit ? 10 : 0)
    }
}

#Preview {
    NavigationStack { BudgetFilterView() }
}
