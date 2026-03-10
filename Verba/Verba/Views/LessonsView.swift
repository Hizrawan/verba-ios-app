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
    @EnvironmentObject private var session: SessionManager

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
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
                        VStack(spacing: 14) {
                            progressCard

                            LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.lessons.enumerated()), id: \.element.id) { index, lesson in
                                StageLessonNodeView(
                                    lesson: lesson,
                                    lessonNumber: index + 1,
                                    totalLessons: viewModel.lessons.count,
                                    isCompleted: session.isLessonCompleted(lesson.id)
                                )
                            }
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

    private var progressCard: some View {
        let completed = session.completedLessonsCount(for: course.id)
        let total = max(viewModel.lessons.count, 1)
        let progress = Double(completed) / Double(total)

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(completed)/\(viewModel.lessons.count) selesai")
                    .font(.subheadline.weight(.medium))
                Spacer(minLength: 0)
                Text("\(session.totalWrongAnswers(for: course.id)) salah")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: progress)
                .tint(.green)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct StageLessonNodeView: View {
    let lesson: Lesson
    let lessonNumber: Int
    let totalLessons: Int
    let isCompleted: Bool

    var body: some View {
        NavigationLink {
            LessonDetailView(
                lesson: lesson,
                lessonNumber: lessonNumber,
                totalLessons: totalLessons
            )
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : lesson.type.iconName)
                    .font(.system(size: 22))
                    .foregroundStyle(isCompleted ? .green : .blue)
                    .frame(width: 44, height: 44)
                    .background((isCompleted ? Color.green : Color.blue).opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(lesson.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    Text(lesson.type.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
