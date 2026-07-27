import SwiftUI

struct DashboardView: View {
    var budgets: [CategoryBudget] = CategoryBudget.sample
    var netRemaining: Double = 4320
    var monthLabel: String = "Temmuz 2026"

    var totalSpent: Double { budgets.reduce(0) { $0 + $1.spent } }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                donutChart
                    .padding(.top, 24)
                legend
                    .padding(.top, 16)

                VStack(alignment: .leading, spacing: 12) {
                    Text("KATEGORİLER")
                        .font(Theme.body(13, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .tracking(0.5)
                        .padding(.horizontal, 24)
                        .padding(.top, 28)

                    ForEach(budgets) { budget in
                        CategoryBudgetCard(budget: budget)
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 24)
            }
        }
        .background(Theme.paper.ignoresSafeArea())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Text(monthLabel.uppercased())
                    .font(Theme.body(12.5, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.sage)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Theme.sage)
            }
            Text(netRemaining.currencyTR)
                .font(Theme.mono(36, weight: .bold))
                .foregroundStyle(Theme.paper)
            Text("bu ay net kaldı")
                .font(Theme.body(12.5))
                .foregroundStyle(Theme.paper.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 32)
        .background(Theme.ink)
        .clipShape(.rect(bottomLeadingRadius: 32, bottomTrailingRadius: 32))
    }

    private var donutChart: some View {
        ZStack {
            ForEach(Array(donutSegments.enumerated()), id: \.offset) { _, seg in
                Circle()
                    .trim(from: seg.start, to: seg.end)
                    .stroke(seg.color, style: StrokeStyle(lineWidth: 18, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
            }
            VStack(spacing: 2) {
                Text(totalSpent.currencyTR)
                    .font(Theme.mono(24, weight: .bold))
                    .foregroundStyle(Theme.ink)
                Text("bu ay harcandı")
                    .font(Theme.body(11.5))
                    .foregroundStyle(Theme.slate)
            }
        }
        .frame(width: 160, height: 160)
    }

    private var donutSegments: [(start: CGFloat, end: CGFloat, color: Color)] {
        var segments: [(CGFloat, CGFloat, Color)] = []
        var cursor: CGFloat = 0
        for budget in budgets {
            let fraction = totalSpent > 0 ? CGFloat(budget.spent / totalSpent) : 0
            segments.append((cursor, cursor + fraction, Theme.statusColor(for: budget.percent)))
            cursor += fraction
        }
        return segments
    }

    private var legend: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 8) {
            ForEach(budgets) { budget in
                HStack(spacing: 6) {
                    Circle()
                        .fill(Theme.statusColor(for: budget.percent))
                        .frame(width: 8, height: 8)
                    Text("\(budget.category.rawValue) %\(Int((budget.spent / totalSpent * 100).rounded()))")
                        .font(Theme.body(12))
                        .foregroundStyle(Theme.ink)
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

private struct CategoryBudgetCard: View {
    let budget: CategoryBudget

    var statusColor: Color { Theme.statusColor(for: budget.percent) }
    var isOverLimit: Bool { budget.percent >= 1.0 }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(statusColor.opacity(0.15)).frame(width: 40, height: 40)
                Text(budget.category.emoji).font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(budget.category.rawValue)
                        .font(Theme.body(14, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    Text("%\(Int((budget.percent * 100).rounded()))")
                        .font(Theme.body(12.5, weight: .bold))
                        .foregroundStyle(statusColor)
                }
                Text("\(budget.spent.currencyTR) / \(budget.monthlyLimit.currencyTR)")
                    .font(Theme.mono(12))
                    .foregroundStyle(Theme.slate)

                if isOverLimit {
                    Label("Limit aşıldı", systemImage: "exclamationmark.triangle.fill")
                        .font(Theme.body(10.5, weight: .semibold))
                        .foregroundStyle(Theme.clay)
                } else {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Theme.paperDark).frame(height: 6)
                            Capsule().fill(statusColor)
                                .frame(width: geo.size.width * min(budget.percent, 1), height: 6)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .overlay(alignment: .leading) {
            if isOverLimit {
                Rectangle().fill(Theme.clay).frame(width: 4)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.bottom, 12)
    }
}

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
}
