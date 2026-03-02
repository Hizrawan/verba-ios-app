//
//  FirebaseAuthSession.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//


import Foundation
import FirebaseAuth

struct FirebaseAuthSession {
    let token: String
    let email: String
}

final class FirebaseAuthService {
    func signIn(email: String, password: String) async throws -> FirebaseAuthSession {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        let user = result.user
        let token = try await user.getIDToken()
        let resolvedEmail = user.email ?? email
        return FirebaseAuthSession(token: token, email: resolvedEmail)
    }

    func signUp(email: String, password: String) async throws -> FirebaseAuthSession {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let user = result.user
        let token = try await user.getIDToken()
        let resolvedEmail = user.email ?? email
        return FirebaseAuthSession(token: token, email: resolvedEmail)
    }
}
