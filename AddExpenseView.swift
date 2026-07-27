import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var amountText: String = ""
    @State private var category: ExpenseCategory = .mutfak
    @State private var date: Date = .now
    @State private var note: String = ""
    @State private var isRecurring: Bool = false
    @State private var frequency: RecurrenceFrequency = .monthly
    @State private var showDatePicker = false

    var onSave: (Transaction) -> Void = { _ in }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                amountField

                sectionLabel("KATEGORİ")
                categoryChips

                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("TARİH")
                    dateRow
                }

                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("AÇIKLAMA")
                    TextField("Ör. Migros market alışverişi", text: $note)
                        .font(Theme.body(14))
                        .padding(.bottom, 10)
                        .overlay(alignment: .bottom) {
                            Rectangle().fill(Theme.ink).frame(height: 1.4)
                        }
                }

                recurringToggle

                if isRecurring {
                    frequencyPicker
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 100)
        }
        .background(Theme.paper.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            saveButton
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
        }
        .navigationTitle("Yeni Harcama")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left").foregroundStyle(Theme.ink)
                }
            }
        }
    }

    private var amountField: some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                Text("₺").font(Theme.mono(44, weight: .bold))
                TextField("0,00", text: $amountText)
                    .font(Theme.mono(44, weight: .bold))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.leading)
                    .fixedSize()
            }
            .foregroundStyle(Theme.ink)
            Text("tutarı girin")
                .font(Theme.body(12))
                .foregroundStyle(Theme.slate)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.body(13, weight: .bold))
            .foregroundStyle(Theme.ink)
            .tracking(0.5)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var categoryChips: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 10)], spacing: 10) {
            ForEach(ExpenseCategory.allCases) { cat in
                let isSelected = category == cat
                Button(action: { category = cat }) {
                    Text("\(cat.emoji) \(cat.rawValue)")
                        .font(Theme.body(13, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(isSelected ? Theme.amber : Color.white)
                        .clipShape(Capsule())
                        .overlay {
                            Capsule().stroke(isSelected ? .clear : Theme.hairline, lineWidth: 1)
                        }
                }
            }
        }
    }

    private var dateRow: some View {
        Button(action: { showDatePicker.toggle() }) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(Theme.slate)
                Text(date.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "tr_TR"))))
                    .font(Theme.body(14))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.slate)
            }
            .padding(16)
            .background(Color.white)
            .overlay { RoundedRectangle(cornerRadius: 14).stroke(Theme.hairline, lineWidth: 1) }
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .popover(isPresented: $showDatePicker) {
            DatePicker("Tarih", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .presentationCompactAdaptation(.popover)
        }
    }

    private var recurringToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Yinelenen Harcama")
                    .font(Theme.body(14, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text("Abonelik / fatura gibi düzenli ödemeler")
                    .font(Theme.body(11.5))
                    .foregroundStyle(Theme.slate)
            }
            Spacer()
            Toggle("", isOn: $isRecurring.animation())
                .labelsHidden()
                .tint(Theme.amber)
        }
    }

    private var frequencyPicker: some View {
        Picker("Sıklık", selection: $frequency) {
            ForEach(RecurrenceFrequency.allCases) { freq in
                Text(freq.rawValue).tag(freq)
            }
        }
        .pickerStyle(.segmented)
    }

    private var saveButton: some View {
        Button(action: save) {
            Text("Kaydet")
                .font(Theme.body(15, weight: .bold))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Theme.amber)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(Double(amountText.replacingOccurrences(of: ",", with: ".")) == nil)
    }

    private func save() {
        guard let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")) else { return }
        let transaction = Transaction(
            amount: amount,
            category: category,
            type: .gider,
            date: date,
            note: note,
            isRecurring: isRecurring,
            frequency: isRecurring ? frequency : nil
        )
        onSave(transaction)
        dismiss()
    }
}

#Preview {
    NavigationStack { AddExpenseView() }
}
