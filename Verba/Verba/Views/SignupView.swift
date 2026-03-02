//
//  SignupView.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//

import SwiftUI

struct SignupView: View {
    @ObservedObject var session: SessionManager
    let onSignupSuccess: () async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let authService = FirebaseAuthService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Buat Akun")
                        .font(.largeTitle.bold())
                    Text("Daftar untuk mulai belajar Bahasa Indonesia.")
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

                    SecureField("Password (min. 6 karakter)", text: $password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                    SecureField("Konfirmasi Password", text: $confirmPassword)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    Task {
                        await signup()
                    }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isLoading ? "Mendaftar..." : "Signup")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .foregroundStyle(.white)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isSignupDisabled)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Signup")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Batal") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var isSignupDisabled: Bool {
        isLoading ||
        email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        password.count < 6 ||
        confirmPassword.isEmpty
    }

    private func signup() async {
        guard password == confirmPassword else {
            errorMessage = "Konfirmasi password tidak sama."
            return
        }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
            let authSession = try await authService.signUp(email: trimmedEmail, password: password)
            session.saveSession(token: authSession.token, email: authSession.email)
            await onSignupSuccess()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
