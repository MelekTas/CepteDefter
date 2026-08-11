import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PartnerSyncView: View {
    @EnvironmentObject var dataManager: DataManager

    @State private var partnerCodeInput: String = ""
    @State private var listNoteInput: String = ""
    @State private var listCategory: ExpenseCategory = .mutfak
    @State private var completingList: SharedMarketList?
    @State private var spentAmountInput: String = ""
    @State private var listToDelete: SharedMarketList?

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var isSendingRequest: Bool = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                userCodeCard

                if let incoming = dataManager.incomingRequest {
                    incomingRequestCard(incoming)
                } else if let outgoing = dataManager.outgoingRequest {
                    outgoingPendingCard(outgoing)
                } else if dataManager.partnerId == nil {
                    sendRequestCard
                }

                if dataManager.partnerId != nil {
                    sendListCard
                    sharedListsSection
                }
            }
            .padding(20)
            .padding(.bottom, 100)
        }
        .background(Theme.paper.ignoresSafeArea())
        .navigationTitle("Ortak Defter")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Eşleşme", isPresented: $showAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Listeyi Sil", isPresented: Binding(
            get: { listToDelete != nil },
            set: { if !$0 { listToDelete = nil } }
        )) {
            Button("Sil", role: .destructive) {
                if let list = listToDelete {
                    dataManager.deleteMarketList(list)
                }
                listToDelete = nil
            }
            Button("İptal", role: .cancel) { listToDelete = nil }
        } message: {
            Text("Bu listeyi silmek istediğine emin misin? Bu işlem geri alınamaz.")
        }
        .sheet(item: $completingList) { list in
            completeListSheet(list: list)
        }
    }

    private var userCodeCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("SENİN EŞLEŞME KODUN")
                    .font(Theme.body(11, weight: .bold))
                    .foregroundStyle(Theme.slate)
                Text(dataManager.userCode ?? "******")
                    .font(Theme.mono(22, weight: .bold))
                    .foregroundStyle(Theme.ink)
            }
            Spacer()
            Image(systemName: "qrcode")
                .font(.system(size: 28))
                .foregroundStyle(Theme.amber)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Gelen istek (biri seninle eşleşmek istiyor)
    private func incomingRequestCard(_ request: PairingRequest) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Eşleşme İsteği", systemImage: "person.crop.circle.badge.questionmark")
                .font(Theme.body(13, weight: .bold))
                .foregroundStyle(Theme.ink)

            Text("Kodu **\(request.fromUserCode)** olan bir kullanıcı seninle eşleşmek istiyor.")
                .font(Theme.body(13))
                .foregroundStyle(Theme.slate)

            HStack(spacing: 12) {
                Button(action: {
                    Task { await dataManager.respondToPairingRequest(request, accept: false) }
                }) {
                    Text("Reddet")
                        .font(Theme.body(13, weight: .bold))
                        .foregroundStyle(Theme.clay)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Theme.clay.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button(action: {
                    Task { await dataManager.respondToPairingRequest(request, accept: true) }
                }) {
                    Text("Kabul Et")
                        .font(Theme.body(13, weight: .bold))
                        .foregroundStyle(Theme.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Theme.amber)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Gönderdiğin istek onay bekliyor
    private func outgoingPendingCard(_ request: PairingRequest) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ProgressView()
                Text("Onay bekleniyor...")
                    .font(Theme.body(13, weight: .semibold))
                    .foregroundStyle(Theme.ink)
            }
            Text("Eşleşme isteğin gönderildi. Karşı tarafın kabul etmesini bekliyorsun.")
                .font(Theme.body(12))
                .foregroundStyle(Theme.slate)

            Button("İsteği İptal Et") {
                dataManager.cancelOutgoingRequest()
            }
            .font(Theme.body(12.5, weight: .semibold))
            .foregroundStyle(Theme.clay)
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Yeni istek gönderme formu
    private var sendRequestCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Eşinle Bütçeni Birleştir")
                .font(Theme.body(14, weight: .bold))
                .foregroundStyle(Theme.ink)
            Text("Eşinin 6 haneli kodunu gir. Eşleşme, karşı taraf onayladıktan sonra tamamlanır.")
                .font(Theme.body(12))
                .foregroundStyle(Theme.slate)

            HStack {
                TextField("Örn. 839201", text: $partnerCodeInput)
                    .font(Theme.mono(14))
                    .keyboardType(.numberPad)
                    .padding(10)
                    .background(Theme.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button(action: sendRequest) {
                    if isSendingRequest {
                        ProgressView().tint(Theme.ink).frame(width: 20)
                    } else {
                        Text("İstek Gönder")
                    }
                }
                .font(Theme.body(13, weight: .bold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.amber)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .disabled(isSendingRequest)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var sendListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("YENİ ORTAK LİSTE GÖNDER")
                .font(Theme.body(12, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.ink)

            TextField("Örn. Pazar listesi: Domates, Salatalık, Peynir...", text: $listNoteInput, axis: .vertical)
                .lineLimit(3...5)
                .font(Theme.body(13))
                .padding(12)
                .background(Theme.paper)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 8) {
                Text("KATEGORİ")
                    .font(Theme.body(10.5, weight: .bold))
                    .tracking(0.5)
                    .foregroundStyle(Theme.slate)
                categoryChips
            }

            HStack {
                Spacer()
                Button(action: sendList) {
                    HStack {
                        Text("Gönder")
                        Image(systemName: "paperplane.fill")
                    }
                    .font(Theme.body(13, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Theme.amber)
                    .clipShape(Capsule())
                }
                .disabled(listNoteInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ExpenseCategory.allCases) { cat in
                    let isSelected = listCategory == cat
                    Button(action: { listCategory = cat }) {
                        HStack(spacing: 4) {
                            Image(systemName: cat.iconName)
                            Text(cat.rawValue)
                        }
                        .font(Theme.body(12, weight: .semibold))
                        .foregroundStyle(isSelected ? Theme.ink : Theme.slate)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? Theme.amber : Theme.paper)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var sharedListsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ORTAK LİSTELER")
                .font(Theme.body(12, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.ink)

            if dataManager.sharedLists.isEmpty {
                Text("Henüz paylaşılmış bir liste bulunmuyor.")
                    .font(Theme.body(12.5))
                    .foregroundStyle(Theme.slate)
                    .padding(.vertical, 12)
            } else {
                ForEach(dataManager.sharedLists) { list in
                    sharedListRow(list: list)
                }
            }
        }
    }

    private func sharedListRow(list: SharedMarketList) -> some View {
        let isMine = list.senderId == dataManager.currentUser?.uid

        return HStack(alignment: .top, spacing: 12) {
            Image(systemName: list.isCompleted ? "checkmark.circle.fill" : "clock.fill")
                .font(.system(size: 20))
                .foregroundStyle(list.isCompleted ? Theme.sage : Theme.amber)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(isMine ? "Gönderdiğin liste" : "Sana gelen liste")
                        .font(Theme.body(10, weight: .bold))
                        .foregroundStyle(Theme.slate)
                        .tracking(0.3)
                    Text("· \(list.category.rawValue)")
                        .font(Theme.body(10, weight: .semibold))
                        .foregroundStyle(Theme.amber)
                }

                if !list.note.isEmpty {
                    Text(list.note)
                        .font(Theme.body(13.5, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                }

                if list.isCompleted, let amount = list.spentAmount {
                    Text("Tamamlandı · Harcanan: \(amount.currencyTR)")
                        .font(Theme.mono(12, weight: .bold))
                        .foregroundStyle(Theme.sage)
                } else {
                    Text("Alışveriş bekleniyor...")
                        .font(Theme.body(11.5))
                        .foregroundStyle(Theme.slate)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                if !list.isCompleted && !isMine {
                    Button("Tamamla") {
                        completingList = list
                    }
                    .font(Theme.body(11.5, weight: .bold))
                    .foregroundStyle(Theme.paper)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.ink)
                    .clipShape(Capsule())
                }

                if isMine && !list.isCompleted {
                    Button(action: { listToDelete = list }) {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Theme.clay)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func sendRequest() {
        let code = partnerCodeInput.trimmingCharacters(in: .whitespaces)

        guard !code.isEmpty else {
            alertMessage = "Lütfen 6 haneli eşleşme kodunu girin."
            showAlert = true
            return
        }
        guard code.count == 6, code.allSatisfy(\.isNumber) else {
            alertMessage = "Eşleşme kodu 6 haneli ve yalnızca rakamlardan oluşmalıdır."
            showAlert = true
            return
        }

        isSendingRequest = true
        Task {
            let result = await dataManager.sendPairingRequest(partnerCode: code)
            isSendingRequest = false
            alertMessage = result.message
            showAlert = true
            if result.success {
                partnerCodeInput = ""
            }
        }
    }

    private func sendList() {
        dataManager.sendMarketList(note: listNoteInput, category: listCategory)
        listNoteInput = ""
        listCategory = .mutfak
    }

    private func completeListSheet(list: SharedMarketList) -> some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("Alışveriş Tutarını Girin")
                        .font(Theme.body(16, weight: .bold))
                        .foregroundStyle(Theme.ink)
                    Text("\(list.category.rawValue) kategorisine işlenecek")
                        .font(Theme.body(12))
                        .foregroundStyle(Theme.slate)
                }

                TextField("0,00 ₺", text: $spentAmountInput)
                    .font(Theme.mono(32, weight: .bold))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Theme.paper)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                Button("Alışverişi Tamamla & Bütçeye İşle") {
                    if let amount = Double(spentAmountInput.replacingOccurrences(of: ",", with: ".")) {
                        dataManager.completeMarketList(list: list, amount: amount)
                        completingList = nil
                        spentAmountInput = ""
                    }
                }
                .font(Theme.body(14, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Theme.amber)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Spacer()
            }
            .padding(24)
            .navigationTitle("Alışveriş Tamamla")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.height(320)])
    }
} 
