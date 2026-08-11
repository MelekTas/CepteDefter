import SwiftUI
import Combine
import Firebase
import FirebaseAuth
import FirebaseFirestore

@MainActor
class DataManager: ObservableObject {
    @Published var currentUser: User?
    @Published var partnerId: String?
    @Published var userCode: String?
    @Published var transactions: [Transaction] = []
    @Published var sharedLists: [SharedMarketList] = []
    @Published var budgetLimits: [String: Double] = [:] // key: ExpenseCategory.rawValue
    @Published var incomingRequest: PairingRequest?
    @Published var outgoingRequest: PairingRequest?
    
    
    private var db = Firestore.firestore()
    private var transactionsListener: ListenerRegistration?
    private var sentListsListener: ListenerRegistration?
    private var receivedListsListener: ListenerRegistration?
    private var budgetsListener: ListenerRegistration?
    private var incomingRequestListener: ListenerRegistration?
    private var outgoingRequestListener: ListenerRegistration?

    private var sentLists: [SharedMarketList] = []
    private var receivedLists: [SharedMarketList] = []

    init() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            if let userId = user?.uid {
                self?.ensureUserPairingCode(userId: userId)
                self?.fetchUserData(userId: userId)
                self?.listenToTransactions(userId: userId)
                self?.listenToSharedLists(userId: userId)
                self?.listenToBudgets(userId: userId)
                self?.listenToPairingRequests(userId: userId)
            } else {
                self?.resetData()
            }
        }
    }

    private func resetData() {
        transactions = []
        sharedLists = []
        sentLists = []
        receivedLists = []
        budgetLimits = [:]
        partnerId = nil
        userCode = nil
        transactionsListener?.remove()
        sentListsListener?.remove()
        receivedListsListener?.remove()
        budgetsListener?.remove()
        incomingRequest = nil
        outgoingRequest = nil
        incomingRequestListener?.remove()
        outgoingRequestListener?.remove()
    }

    // MARK: - Auth İşlemleri
    func signOut() {
        try? Auth.auth().signOut()
    }

    // MARK: - 6 Haneli Kullanıcı Kodu & Kullanıcı Verisi
    func generatePairingCode() -> String {
        let randomID = Int.random(in: 100000...999999)
        return "\(randomID)"
    }

    func ensureUserPairingCode(userId: String) {
        let userRef = db.collection("users").document(userId)
        userRef.getDocument { [weak self] snapshot, _ in
            if let data = snapshot?.data(), let code = data["userCode"] as? String {
                self?.userCode = code
            } else {
                let newCode = self?.generatePairingCode() ?? "123456"
                userRef.setData(["userCode": newCode], merge: true)
                self?.userCode = newCode
            }
        }
    }

    private func fetchUserData(userId: String) {
        db.collection("users").document(userId).addSnapshotListener { [weak self] snapshot, _ in
            guard let self = self else { return }
            let data = snapshot?.data()

            let rawPartnerId = data?["partnerId"] as? String
            // Boş string ("") gelirse gerçek bir eşleşme yok demektir, nil olarak say.
            self.partnerId = (rawPartnerId?.isEmpty ?? true) ? nil : rawPartnerId

            if let code = data?["userCode"] as? String {
                self.userCode = code
            }
        }
    }

    // MARK: - Eşleşme İsteği Gönder (Onay Gerektirir)
    func sendPairingRequest(partnerCode: String) async -> (success: Bool, message: String) {
        guard let currentUserId = currentUser?.uid else {
            return (false, "Kullanıcı oturumu bulunamadı.")
        }
        if let currentCode = userCode, currentCode == partnerCode {
            return (false, "Kendi eşleşme kodunu giremezsin!")
        }
        if let existing = outgoingRequest, existing.status == .pending {
            return (false, "Zaten bekleyen bir isteğin var.")
        }

        do {
            let snapshot = try await db.collection("users")
                .whereField("userCode", isEqualTo: partnerCode)
                .getDocuments()

            guard let partnerDoc = snapshot.documents.first else {
                return (false, "Bu koda sahip kullanıcı bulunamadı.")
            }

            let foundPartnerId = partnerDoc.documentID
            if foundPartnerId == currentUserId {
                return (false, "Kendi hesabınla eşleşemezsin!")
            }

            let request = PairingRequest(
                fromUserId: currentUserId,
                fromUserCode: userCode ?? "",
                toUserId: foundPartnerId
            )
            try db.collection("pairing_requests").document(request.id).setData(from: request)
            return (true, "Eşleşme isteği gönderildi. Eşinin onayını bekliyorsun.")

        } catch {
            print("❌ İstek gönderilemedi: \(error)")
            return (false, "İstek gönderilemedi: \(error.localizedDescription)")
        }
    }

    // MARK: - Gelen İsteğe Yanıt Ver
    func respondToPairingRequest(_ request: PairingRequest, accept: Bool) async {
        guard let currentUserId = currentUser?.uid else { return }

        if accept {
            do {
                try await db.collection("users").document(request.fromUserId).setData(["partnerId": request.toUserId], merge: true)
                try await db.collection("users").document(request.toUserId).setData(["partnerId": request.fromUserId], merge: true)
                try await db.collection("pairing_requests").document(request.id).delete()

                self.partnerId = request.fromUserId
                self.listenToTransactions(userId: currentUserId)
                self.listenToSharedLists(userId: currentUserId)
                print("✅ Eşleşme isteği kabul edildi.")
            } catch {
                print("❌ İstek kabul edilemedi: \(error.localizedDescription)")
            }
        } else {
            do {
                try await db.collection("pairing_requests").document(request.id).delete()
                print("✅ Eşleşme isteği reddedildi.")
            } catch {
                print("❌ İstek reddedilemedi: \(error.localizedDescription)")
            }
        }
    }

    func cancelOutgoingRequest() {
        guard let request = outgoingRequest else { return }
        db.collection("pairing_requests").document(request.id).delete { error in
            if let error = error {
                print("❌ İstek iptal edilemedi: \(error.localizedDescription)")
            } else {
                print("✅ Gönderdiğin istek iptal edildi.")
            }
        }
    }

    // MARK: - Eşleşme İsteklerini Dinle (Gelen & Giden)
    func listenToPairingRequests(userId: String) {
        incomingRequestListener?.remove()
        outgoingRequestListener?.remove()

        incomingRequestListener = db.collection("pairing_requests")
            .whereField("toUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: PairingRequestStatus.pending.rawValue)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("❌ Gelen istekler dinlenemedi: \(error.localizedDescription)")
                    return
                }
                let requests = snapshot?.documents.compactMap { try? $0.data(as: PairingRequest.self) } ?? []
                self.incomingRequest = requests.first
            }

        outgoingRequestListener = db.collection("pairing_requests")
            .whereField("fromUserId", isEqualTo: userId)
            .whereField("status", isEqualTo: PairingRequestStatus.pending.rawValue)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("❌ Gönderdiğim istek dinlenemedi: \(error.localizedDescription)")
                    return
                }
                let requests = snapshot?.documents.compactMap { try? $0.data(as: PairingRequest.self) } ?? []
                self.outgoingRequest = requests.first
            }
    }
    // MARK: - Eşleşmeyi Kes (Sıfırla)
    func unpairPartner() async {
        guard let currentUserId = currentUser?.uid else {
            print("❌ Eşleşme kesilemedi: kullanıcı oturumu yok.")
            return
        }

        let oldPartnerId = partnerId

        do {
            // 1. Kendi partnerId alanını kaldır
            try await db.collection("users").document(currentUserId).updateData([
                "partnerId": FieldValue.delete()
            ])
            print("✅ Kendi partnerId alanım silindi.")
        } catch {
            print("❌ Kendi partnerId alanım silinemedi: \(error.localizedDescription)")
        }

        // 2. Karşı tarafın da partnerId alanını kaldır
        if let pId = oldPartnerId, !pId.isEmpty {
            do {
                try await db.collection("users").document(pId).updateData([
                    "partnerId": FieldValue.delete()
                ])
                print("✅ Eşin partnerId alanı silindi.")
            } catch {
                print("❌ Eşin partnerId alanı silinemedi: \(error.localizedDescription)")
            }
        }

        // 3. Yerel durumu HER DURUMDA güncelle (kendi tarafın koptu bile olsa arayüz doğru gözüksün)
        self.partnerId = nil
        self.listenToTransactions(userId: currentUserId)
        self.listenToSharedLists(userId: currentUserId)
        print("🔄 Yerel partnerId nil'e ayarlandı.")
    }

    func listenToTransactions(userId: String) {
        transactionsListener?.remove()

        transactionsListener = db.collection("transactions")
            .whereField("ownerUserId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ İşlemler dinlenemedi: \(error.localizedDescription)")
                    return
                }
                guard let documents = snapshot?.documents else { return }
                self.transactions = documents.compactMap { try? $0.data(as: Transaction.self) }
                print("📥 \(self.transactions.count) işlem yüklendi.")
            }
    }

    // MARK: - Gelir / Gider Ekleme
    func addTransaction(_ transaction: Transaction) {
        var newTx = transaction
        newTx.ownerUserId = currentUser?.uid ?? ""

        do {
            try db.collection("transactions").document(newTx.id.uuidString).setData(from: newTx) { error in
                if let error = error {
                    print("❌ İşlem kaydedilemedi: \(error.localizedDescription)")
                } else {
                    print("✅ İşlem Firestore'a kaydedildi.")
                }
            }
        } catch {
            print("❌ İşlem encode edilemedi: \(error.localizedDescription)")
        }
    }

    // MARK: - Bütçe Limitleri
    func listenToBudgets(userId: String) {
        budgetsListener?.remove()
        budgetsListener = db.collection("users").document(userId).collection("budgets")
            .addSnapshotListener { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                var limits: [String: Double] = [:]
                for doc in documents {
                    if let limit = doc.data()["monthlyLimit"] as? Double {
                        limits[doc.documentID] = limit
                    }
                }
                self.budgetLimits = limits
            }
    }

    func setBudgetLimit(category: ExpenseCategory, limit: Double) {
        guard let userId = currentUser?.uid else { return }
        db.collection("users").document(userId).collection("budgets").document(category.rawValue)
            .setData(["monthlyLimit": limit], merge: true) { error in
                if let error = error {
                    print("❌ Limit kaydedilemedi: \(error.localizedDescription)")
                } else {
                    print("✅ Limit Firestore'a kaydedildi.")
                }
            }
    }

    // MARK: - Dinamik Ay Hesaplamaları & İşlem Filtreleme
    func transactions(for date: Date) -> [Transaction] {
        let calendar = Calendar.current
        return transactions
            .filter { calendar.isDate($0.date, equalTo: date, toGranularity: .month) }
            .sorted(by: { $0.date > $1.date })
    }

    func totalSpent(for date: Date) -> Double {
        transactions(for: date).filter { $0.type == .gider }.reduce(0) { $0 + $1.amount }
    }

    func totalIncome(for date: Date) -> Double {
        transactions(for: date).filter { $0.type == .gelir }.reduce(0) { $0 + $1.amount }
    }

    func netRemaining(for date: Date) -> Double {
        totalIncome(for: date) - totalSpent(for: date)
    }

    func categoryBudgets(for date: Date) -> [CategoryBudget] {
        let monthTx = transactions(for: date)
        return ExpenseCategory.allCases.compactMap { category in
            let spent = monthTx
                .filter { $0.type == .gider && $0.category == category }
                .reduce(0) { $0 + $1.amount }
            let limit = budgetLimits[category.rawValue] ?? 0
            guard spent > 0 || limit > 0 else { return nil }
            return CategoryBudget(category: category, monthlyLimit: limit, spent: spent)
        }
    }

    var allCategoryBudgets: [CategoryBudget] {
        ExpenseCategory.allCases.map { category in
            let spent = transactions
                .filter { $0.type == .gider && $0.category == category }
                .reduce(0) { $0 + $1.amount }
            let limit = budgetLimits[category.rawValue] ?? 0
            return CategoryBudget(category: category, monthlyLimit: limit, spent: spent)
        }
    }

    // MARK: - Ortak Listeler (hem gönderdiklerim hem bana gelenler)
    func listenToSharedLists(userId: String) {
        sentListsListener?.remove()
        receivedListsListener?.remove()

        sentListsListener = db.collection("shared_lists")
            .whereField("senderId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("❌ Gönderdiğim listeler dinlenemedi: \(error.localizedDescription)")
                    return
                }
                guard let docs = snapshot?.documents else { return }
                self.sentLists = docs.compactMap { try? $0.data(as: SharedMarketList.self) }
                self.recomputeSharedLists()
            }

        receivedListsListener = db.collection("shared_lists")
            .whereField("receiverId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("❌ Bana gelen listeler dinlenemedi: \(error.localizedDescription)")
                    return
                }
                guard let docs = snapshot?.documents else { return }
                self.receivedLists = docs.compactMap { try? $0.data(as: SharedMarketList.self) }
                self.recomputeSharedLists()
            }
    }

    private func recomputeSharedLists() {
        var merged: [String: SharedMarketList] = [:]
        for list in sentLists { merged[list.id] = list }
        for list in receivedLists { merged[list.id] = list }
        self.sharedLists = merged.values.sorted { $0.createdAt > $1.createdAt }
    }

    func sendMarketList(note: String, category: ExpenseCategory) {
        guard let currentUserId = currentUser?.uid, let pId = partnerId else {
            print("❌ Liste gönderilemedi: eşleşme yok.")
            return
        }
        let list = SharedMarketList(
            senderId: currentUserId,
            receiverId: pId,
            imageURL: nil,
            note: note,
            category: category
        )
        do {
            try db.collection("shared_lists").document(list.id).setData(from: list) { error in
                if let error = error {
                    print("❌ Liste kaydedilemedi: \(error.localizedDescription)")
                } else {
                    print("✅ Liste Firestore'a kaydedildi.")
                }
            }
        } catch {
            print("❌ Liste encode edilemedi: \(error.localizedDescription)")
        }
    }

    func completeMarketList(list: SharedMarketList, amount: Double) {
        db.collection("shared_lists").document(list.id).updateData([
            "isCompleted": true,
            "spentAmount": amount
        ]) { error in
            if let error = error {
                print("❌ Liste tamamlanamadı: \(error.localizedDescription)")
            } else {
                print("✅ Liste tamamlandı olarak işaretlendi.")
            }
        }

        // Tamamlanan alışverişi GÖNDEREN kişinin bütçesine, listedeki kategoriye göre gider olarak işler.
        let transaction = Transaction(
            amount: amount,
            category: list.category,
            type: .gider,
            date: Date(),
            note: "Ortak Liste: \(list.note)",
            ownerUserId: list.senderId
        )
        addTransaction(transaction)
    }
    func deleteMarketList(_ list: SharedMarketList) {
        db.collection("shared_lists").document(list.id).delete { error in
            if let error = error {
                print("❌ Liste silinemedi: \(error.localizedDescription)")
            } else {
                print("✅ Liste silindi.")
            }
        }
    }
}
