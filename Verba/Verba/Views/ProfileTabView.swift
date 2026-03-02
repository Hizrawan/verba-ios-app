//
//  ProfileTabView.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//
import SwiftUI

struct ProfileTabView: View {
    @ObservedObject var session: SessionManager
    @State private var showLogoutAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Akun") {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.email ?? "Pengguna")
                                .font(.headline)
                            Text("Belajar Bahasa Indonesia")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Session") {
                    Text("Status: Login")
                    Text("Token tersimpan di perangkat.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button(role: .destructive) {
                        showLogoutAlert = true
                    } label: {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Logout", isPresented: $showLogoutAlert) {
                Button("Batal", role: .cancel) {}
                Button("Logout", role: .destructive) {
                    session.logout()
                }
            } message: {
                Text("Yakin ingin keluar?")
            }
        }
    }
}
