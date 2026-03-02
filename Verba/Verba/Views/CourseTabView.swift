//
//  CourseTabView.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//


import SwiftUI

struct CoursesTabView: View {
    @ObservedObject var viewModel: CourseListViewModel
    @ObservedObject var session: SessionManager
    @Binding var showAddSheet: Bool
    @Binding var editingCourse: Course?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.courses.isEmpty {
                    ProgressView("Memuat course...")
                } else if viewModel.courses.isEmpty {
                    ContentUnavailableView(
                        "Belum Ada Course",
                        systemImage: "book.closed",
                        description: Text("Tekan tombol + untuk menambahkan course pertama.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.courses) { course in
                                NavigationLink {
                                    LessonsView(course: course)
                                } label: {
                                    CourseCardView(course: course)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button {
                                        editingCourse = course
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        Task {
                                            if let index = viewModel.courses.firstIndex(where: { $0.id == course.id }) {
                                                await viewModel.delete(
                                                    at: IndexSet(integer: index),
                                                    bearerToken: session.token
                                                )
                                            }
                                        }
                                    } label: {
                                        Label("Hapus", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Courses")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reload") {
                        Task { await viewModel.loadCourses() }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .refreshable {
                await viewModel.loadCourses()
            }
            .task {
                guard viewModel.courses.isEmpty else { return }
                await viewModel.loadCourses()
            }
        }
    }
}
