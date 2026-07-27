import SwiftUI

struct AuthView: View {
    enum Mode { case signIn, signUp }

    @State private var mode: Mode = .signIn
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil

    var onAuthenticated: () -> Void = {}

    var body: some View {
        ZStack {
            Theme.ink.ignoresSafeArea()

            VStack {
                Rectangle()
                    .fill(Theme.amber)
                    .frame(width: 24, height: 150)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .center)

            VStack(spacing: 0) {
                Spacer().frame(height: 170)

                VStack(spacing: 6) {
                    Text("Cepte Defter")
                        .font(Theme.display(32, weight: .semibold))
                        .foregroundStyle(Theme.paper)
                    Text("paranın hikayesini defterine yaz")
                        .font(Theme.body(13))
                        .foregroundStyle(Theme.sage)
                }

                Spacer().frame(height: 32)

                card
                    .padding(.horizontal, 24)

                Spacer()

                HStack(spacing: 4) {
                    Text(mode == .signIn ? "Hesabın yok mu?" : "Zaten hesabın var mı?")
                        .foregroundStyle(Theme.slate)
                    Button(mode == .signIn ? "Kayıt Ol" : "Giriş Yap") {
                        withAnimation { mode = mode == .signIn ? .signUp : .signIn }
                    }
                    .foregroundStyle(Theme.amber)
                    .fontWeight(.bold)
                }
                .font(Theme.body(13))
                .padding(.bottom, 24)
            }
        }
    }

    private var card: some View {
        VStack(spacing: 18) {
            HStack(spacing: 0) {
                tabButton("Giriş Yap", isActive: mode == .signIn) { mode = .signIn }
                tabButton("Kayıt Ol", isActive: mode == .signUp) { mode = .signUp }
            }
            .padding(4)
            .background(Theme.paperDark)
            .clipShape(RoundedRectangle(cornerRadius: 24))

            field(label: "E-POSTA", placeholder: "ornek@eposta.com", text: $email, isSecure: false)
            field(label: "ŞİFRE", placeholder: "••••••••", text: $password, isSecure: true)

            if let errorMessage {
                Text(errorMessage)
                    .font(Theme.body(12))
                    .foregroundStyle(Theme.clay)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if mode == .signIn {
                HStack {
                    Spacer()
                    Button("Şifremi unuttum") {}
                        .font(Theme.body(12.5, weight: .semibold))
                        .foregroundStyle(Theme.sage)
                }
            }

            Button(action: handleAuth) {
                ZStack {
                    if isLoading {
                        ProgressView().tint(Theme.ink)
                    } else {
                        Text(mode == .signIn ? "Giriş Yap" : "Kayıt Ol")
                            .font(Theme.body(15, weight: .bold))
                            .foregroundStyle(Theme.ink)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Theme.amber)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(email.isEmpty || password.isEmpty || isLoading)
        }
        .padding(24)
        .background(Theme.paper)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: .black.opacity(0.18), radius: 20, y: 8)
    }

    private func tabButton(_ title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.15)) { action() } }) {
            Text(title)
                .font(Theme.body(14, weight: .semibold))
                .foregroundStyle(isActive ? Theme.paper : Theme.slate)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isActive ? Theme.ink : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 22))
        }
    }

    private func field(label: String, placeholder: String, text: Binding<String>, isSecure: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(Theme.body(12, weight: .semibold))
                .foregroundStyle(Theme.slate)
                .tracking(0.3)
            Group {
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .font(Theme.body(14))
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Theme.paperDark)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func handleAuth() {
        errorMessage = nil
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isLoading = false
            onAuthenticated()
        }
    }
}

#Preview {
    AuthView()
}
