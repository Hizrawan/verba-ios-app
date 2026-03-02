//
//  HomeTabView.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//
import SwiftUI

struct HomeTabView: View {
    @ObservedObject var viewModel: CourseListViewModel
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(.systemIndigo).opacity(0.18), Color(.systemBlue).opacity(0.08), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        ZStack(alignment: .bottomLeading) {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [.indigo, .blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 190)

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Belajar Bahasa Indonesia")
                                    .font(.title2.bold())
                                    .foregroundStyle(.white)
                                Text("Sesi hari ini: kosakata, grammar, dan listening ringan.")
                                    .foregroundStyle(.white.opacity(0.9))
                                Label("Daily Streak 7 hari", systemImage: "flame.fill")
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.white, in: Capsule())
                            }
                            .padding(20)
                        }
                        .shadow(color: .indigo.opacity(0.2), radius: 14, x: 0, y: 8)

                        HStack(spacing: 12) {
                            SummaryCard(
                                title: "Total Course",
                                value: "\(viewModel.courses.count)",
                                icon: "books.vertical.fill",
                                tint: .indigo
                            )
                            SummaryCard(
                                title: "Lesson Selesai",
                                value: "\(session.lessonCompletions.count)",
                                icon: "checkmark.seal.fill",
                                tint: .green
                            )
                        }

                        SummaryCard(
                            title: "Total Jawaban Salah",
                            value: "\(session.totalWrongAnswers())",
                            icon: "exclamationmark.triangle.fill",
                            tint: .orange
                        )

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Rekomendasi Hari Ini")
                                    .font(.headline)
                                Spacer()
                                Text("Personalized")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.blue)
                            }
                            Text("Buka tab Courses untuk tambah, edit, dan kelola semua materi belajarmu.")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .padding()
                }
            }
            .navigationTitle("Home")
            .task {
                guard viewModel.courses.isEmpty else { return }
                await viewModel.loadCourses()
            }
        }
    }
}
