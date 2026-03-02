//
//  LoginView.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var session: SessionManager
    let onLoginSuccess: () async -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSignup = false

    private let authService = FirebaseAuthService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selamat Datang")
                        .font(.largeTitle.bold())
                    Text("Masuk untuk mengelola course Bahasa Indonesia.")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 14) {
                    TextField("Email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                    SecureField("Password", text: $password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    Task {
                        await login()
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isLoading ? "Masuk..." : "Login")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(.white)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isLoading || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || password.isEmpty)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button("Belum punya akun? Signup") {
                    showSignup = true
                }
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .padding()
            .navigationTitle("Login")
            .sheet(isPresented: $showSignup) {
                SignupView(session: session) {
                    await onLoginSuccess()
                }
            }
        }
    }

    private func login() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let authSession = try await authService.signIn(email: trimmedEmail, password: password)
            session.saveSession(token: authSession.token, email: authSession.email)
            await onLoginSuccess()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
