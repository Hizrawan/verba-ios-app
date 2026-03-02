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
            ZStack {
                LinearGradient(
                    colors: [Color(.systemTeal).opacity(0.1), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        HStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 62, height: 62)
                                Image(systemName: "person.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.email ?? "Pengguna")
                                    .font(.headline)
                                Text("Belajar Bahasa Indonesia")
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                        VStack(alignment: .leading, spacing: 10) {
                            Label("Status Akun: Login", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                                .font(.subheadline.weight(.semibold))
                            Text("Token auth tersimpan lokal, dan akan dipakai otomatis untuk request backend.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                        Button(role: .destructive) {
                            showLogoutAlert = true
                        } label: {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                    .padding()
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
