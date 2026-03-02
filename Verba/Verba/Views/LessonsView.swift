//
//  LessonsView.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//

import SwiftUI

struct LessonsView: View {
    let course: Course
    @StateObject private var viewModel = LessonListViewModel()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemMint).opacity(0.12), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Group {
                if viewModel.isLoading && viewModel.lessons.isEmpty {
                    ProgressView("Memuat lesson...")
                } else if viewModel.lessons.isEmpty {
                    ContentUnavailableView(
                        "Belum Ada Lesson",
                        systemImage: "text.book.closed",
                        description: Text("Course ini belum memiliki lesson.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.lessons) { lesson in
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text("Lesson \(lesson.order ?? lesson.id)")
                                            .font(.caption.weight(.semibold))
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 4)
                                            .background(Color.blue.opacity(0.12), in: Capsule())
                                            .foregroundStyle(.blue)
                                        Spacer()
                                        Image(systemName: "headphones")
                                            .foregroundStyle(.secondary)
                                    }

                                    Text(lesson.title)
                                        .font(.headline)
                                    if let content = lesson.content, !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Text(content)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(3)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .stroke(.white.opacity(0.22), lineWidth: 1)
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle(course.title)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadLessons(courseId: course.id)
        }
        .task {
            await viewModel.loadLessons(courseId: course.id)
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Terjadi kesalahan.")
        }
    }
}
