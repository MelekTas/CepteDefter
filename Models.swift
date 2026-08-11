import Foundation

enum ExpenseCategory: String, CaseIterable, Identifiable, Codable {
    case mutfak = "Mutfak"
    case egitim = "Eğitim"
    case eglence = "Eğlence"
    case fatura = "Fatura"
    case ulasim = "Ulaşım"
    case diger = "Diğer"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .mutfak: return "cart.fill"
        case .egitim: return "book.fill"
        case .eglence: return "popcorn.fill"
        case .fatura: return "doc.text.fill"
        case .ulasim: return "bus.fill"
        case .diger: return "ellipsis.circle.fill"
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

struct SharedMarketList: Identifiable, Codable {
    var id: String = UUID().uuidString
    var senderId: String
    var receiverId: String
    var imageURL: String?
    var note: String
    var category: ExpenseCategory = .mutfak
    var isCompleted: Bool = false
    var spentAmount: Double?
    var createdAt: Date = Date()
}
enum PairingRequestStatus: String, Codable {
    case pending
    case accepted
    case rejected
}

struct PairingRequest: Identifiable, Codable {
    var id: String = UUID().uuidString
    var fromUserId: String
    var fromUserCode: String
    var toUserId: String
    var status: PairingRequestStatus = .pending
    var createdAt: Date = Date()
}
