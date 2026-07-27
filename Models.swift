
import Foundation

enum ExpenseCategory: String, CaseIterable, Identifiable, Codable {
    case mutfak = "Mutfak"
    case egitim = "Eğitim"
    case eglence = "Eğlence"
    case fatura = "Fatura"
    case ulasim = "Ulaşım"
    case diger = "Diğer"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .mutfak: return "🍲"
        case .egitim: return "📚"
        case .eglence: return "🎬"
        case .fatura: return "🧾"
        case .ulasim: return "🚌"
        case .diger: return "⋯"
        }
    }
}

enum RecurrenceFrequency: String, CaseIterable, Identifiable, Codable {
    case weekly = "Haftalık"
    case monthly = "Aylık"
    var id: String { rawValue }
}

enum TransactionType: String, CaseIterable, Identifiable, Codable {
    case gelir = "Gelir"
    case gider = "Gider"
    var id: String { rawValue }
}

struct Transaction: Identifiable, Codable {
    var id: UUID = UUID()
    var amount: Double
    var category: ExpenseCategory
    var type: TransactionType
    var date: Date
    var note: String
    var isRecurring: Bool = false
    var frequency: RecurrenceFrequency? = nil
    var ownerUserId: String = ""
}

struct CategoryBudget: Identifiable, Codable {
    var id: UUID = UUID()
    var category: ExpenseCategory
    var monthlyLimit: Double
    var spent: Double

    var percent: Double {
        guard monthlyLimit > 0 else { return 0 }
        return spent / monthlyLimit
    }
}

struct TransactionFilter {
    enum DateRange: String, CaseIterable, Identifiable {
        case week = "Bu Hafta"
        case month = "Bu Ay"
        case year = "Bu Yıl"
        case custom = "Özel"
        var id: String { rawValue }
    }

    var dateRange: DateRange = .month
    var categories: Set<ExpenseCategory> = []
    var type: TransactionType? = nil
    var searchText: String = ""
}

extension Transaction {
    static let sample: [Transaction] = [
        Transaction(amount: 930, category: .mutfak, type: .gider, date: .now, note: "Migros market alışverişi"),
        Transaction(amount: 400, category: .egitim, type: .gider, date: .now, note: "Online kurs"),
        Transaction(amount: 528, category: .eglence, type: .gider, date: .now, note: "Sinema + akşam yemeği"),
        Transaction(amount: 840, category: .fatura, type: .gider, date: .now, note: "Elektrik faturası", isRecurring: true, frequency: .monthly)
    ]
}

extension CategoryBudget {
    static let sample: [CategoryBudget] = [
        CategoryBudget(category: .mutfak, monthlyLimit: 1500, spent: 930),
        CategoryBudget(category: .egitim, monthlyLimit: 1000, spent: 400),
        CategoryBudget(category: .eglence, monthlyLimit: 600, spent: 528),
        CategoryBudget(category: .fatura, monthlyLimit: 800, spent: 840)
    ]
}
