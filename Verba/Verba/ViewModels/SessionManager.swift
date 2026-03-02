//
//  SessionManager.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//


import Foundation
import Combine
import FirebaseAuth

final class SessionManager: ObservableObject {
    @Published private(set) var token: String?
    @Published private(set) var email: String?

    var isAuthenticated: Bool {
        let value = token?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !value.isEmpty
    }

    private let tokenKey = "verba.auth.token"
    private let emailKey = "verba.auth.email"

    init() {
        token = UserDefaults.standard.string(forKey: tokenKey)
        email = UserDefaults.standard.string(forKey: emailKey)
    }

    func saveSession(token: String, email: String) {
        self.token = token
        self.email = email
        UserDefaults.standard.set(token, forKey: tokenKey)
        UserDefaults.standard.set(email, forKey: emailKey)
    }

    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            // Tetap hapus session lokal agar user bisa keluar dari app.
        }
        token = nil
        email = nil
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
    }
}
