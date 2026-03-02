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
                List(viewModel.lessons) { lesson in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Lesson \(lesson.order ?? 0)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
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
                    .padding(.vertical, 4)
                }
                .listStyle(.insetGrouped)
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
