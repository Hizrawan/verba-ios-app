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
                        LazyVStack(spacing: 0) {
                            ForEach(Array(viewModel.lessons.enumerated()), id: \.element.id) { index, lesson in
                                StageLessonNodeView(
                                    lesson: lesson,
                                    lessonNumber: index + 1,
                                    totalLessons: viewModel.lessons.count
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

private struct StageLessonNodeView: View {
    let lesson: Lesson
    let lessonNumber: Int
    let totalLessons: Int

    private var xOffset: CGFloat {
        lessonNumber.isMultiple(of: 2) ? 56 : -56
    }

    var body: some View {
        VStack(spacing: 0) {
            NavigationLink {
                LessonDetailView(
                    lesson: lesson,
                    lessonNumber: lessonNumber,
                    totalLessons: totalLessons
                )
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.green, Color.blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 66, height: 66)
                            .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)

                        Image(systemName: lesson.type.iconName)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Lesson \(lessonNumber)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(lesson.title)
                            .font(.headline)
                            .lineLimit(2)
                        Text(lesson.type.title)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.12), in: Capsule())
                            .foregroundStyle(.blue)
                    }
                    Spacer()
                }
                .padding(14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.white.opacity(0.24), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .offset(x: xOffset)

            if lessonNumber < totalLessons {
                Rectangle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 5, height: 36)
                    .clipShape(Capsule())
                    .padding(.vertical, 6)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
