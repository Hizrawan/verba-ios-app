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
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSignup = false

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
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Selamat Datang")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Masuk untuk melanjutkan belajar Bahasa Indonesia bersama Verba.")
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)

                        VStack(spacing: 16) {
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

                            HStack(spacing: 10) {
                                Image(systemName: "lock")
                                    .foregroundStyle(.secondary)
                                Group {
                                    if showPassword {
                                        TextField("Password", text: $password)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                    } else {
                                        SecureField("Password", text: $password)
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled()
                                    }
                                }
                                Button {
                                    showPassword.toggle()
                                } label: {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))

                            Button {
                                Task {
                                    await login()
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    if isLoading {
                                        ProgressView()
                                            .tint(.white)
                                    }
                                    Text(isLoading ? "Masuk..." : "Login")
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
                            .disabled(isLoginDisabled)

                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            HStack {
                                Text("Belum punya akun?")
                                    .foregroundStyle(.secondary)
                                Button("Signup") {
                                    showSignup = true
                                }
                                .fontWeight(.semibold)
                            }
                            .font(.footnote)
                        }
                        .padding(20)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                    }
                    .padding(20)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showSignup) {
                SignupView(session: session) {
                    await onLoginSuccess()
                }
            }
        }
    }

    private var isLoginDisabled: Bool {
        isLoading ||
        email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        password.isEmpty
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
