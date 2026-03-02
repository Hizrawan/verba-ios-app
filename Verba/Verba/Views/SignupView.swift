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
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let authService = FirebaseAuthService()

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.07, green: 0.13, blue: 0.36),
                        Color(red: 0.11, green: 0.33, blue: 0.64),
                        Color(red: 0.15, green: 0.57, blue: 0.84)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Buat Akun")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Daftar untuk mulai belajar Bahasa Indonesia.")
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        VStack(spacing: 14) {
                            HStack(spacing: 10) {
                                Image(systemName: "envelope")
                                    .foregroundStyle(.secondary)
                                TextField("Email", text: $email)
                                    .textInputAutocapitalization(.never)
                                    .keyboardType(.emailAddress)
                                    .autocorrectionDisabled()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))

                            passwordField(
                                title: "Password (min. 6 karakter)",
                                text: $password,
                                showText: $showPassword
                            )

                            passwordField(
                                title: "Konfirmasi Password",
                                text: $confirmPassword,
                                showText: $showConfirmPassword
                            )

                            Button {
                                Task {
                                    await signup()
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    }
                                    Text(isLoading ? "Mendaftar..." : "Signup")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .foregroundStyle(.white)
                                .background(
                                    LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing),
                                    in: RoundedRectangle(cornerRadius: 14)
                                )
                            }
                            .disabled(isSignupDisabled)

                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(20)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                    }
                    .padding(20)
                }
            }
            .navigationBarHidden(true)
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

    private func passwordField(title: String, text: Binding<String>, showText: Binding<Bool>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "lock")
                .foregroundStyle(.secondary)
            Group {
                if showText.wrappedValue {
                    TextField(title, text: text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    SecureField(title, text: text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            Button {
                showText.wrappedValue.toggle()
            } label: {
                Image(systemName: showText.wrappedValue ? "eye.slash" : "eye")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}
