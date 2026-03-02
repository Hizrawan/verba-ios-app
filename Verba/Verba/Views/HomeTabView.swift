//
//  HomeTabView.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//

import SwiftUI

struct HomeTabView: View {
    @ObservedObject var viewModel: CourseListViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    ZStack(alignment: .bottomLeading) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 170)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Belajar Bahasa Indonesia")
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                            Text("Mulai dari course dasar sampai mahir.")
                                .foregroundStyle(.white.opacity(0.9))
                        }
                        .padding(20)
                    }

                    HStack(spacing: 12) {
                        SummaryCard(
                            title: "Total Course",
                            value: "\(viewModel.courses.count)",
                            icon: "books.vertical.fill",
                            tint: .indigo
                        )
                        SummaryCard(
                            title: "Status Data",
                            value: viewModel.isLoading ? "Loading" : "Ready",
                            icon: "bolt.fill",
                            tint: .green
                        )
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Lanjut Belajar")
                            .font(.headline)
                        Text("Buka tab Courses untuk tambah, edit, dan kelola semua materi course.")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
            .navigationTitle("Home")
            .task {
                guard viewModel.courses.isEmpty else { return }
                await viewModel.loadCourses()
            }
        }
    }
}
