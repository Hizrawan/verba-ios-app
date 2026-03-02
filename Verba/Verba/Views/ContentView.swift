//
//  ContentView.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//


import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: CourseListViewModel
    @State private var selectedTab = 0
    @State private var showAddSheet = false
    @State private var editingCourse: Course?

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeTabView(viewModel: viewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            CoursesTabView(
                viewModel: viewModel,
                showAddSheet: $showAddSheet,
                editingCourse: $editingCourse
            )
            .tabItem {
                Label("Courses", systemImage: "book.closed.fill")
            }
            .tag(1)

            ProfileTabView(viewModel: viewModel)
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(2)
        }
        .sheet(isPresented: $showAddSheet) {
            CourseFormView(mode: .add) { course in
                guard let course else { return }
                await viewModel.addCourse(title: course.title, description: course.description)
            }
        }
        .sheet(item: $editingCourse) { course in
            CourseFormView(mode: .edit(course)) { updated in
                guard let updated else { return }
                await viewModel.saveCourse(updated)
            }
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

private struct HomeTabView: View {
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

private struct CoursesTabView: View {
    @ObservedObject var viewModel: CourseListViewModel
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
                                CourseCardView(course: course)
                                    .onTapGesture {
                                        editingCourse = course
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            Task {
                                                if let index = viewModel.courses.firstIndex(where: { $0.id == course.id }) {
                                                    await viewModel.delete(at: IndexSet(integer: index))
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

private struct ProfileTabView: View {
    @ObservedObject var viewModel: CourseListViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Akun") {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Verba Learner")
                                .font(.headline)
                            Text("Belajar Bahasa Indonesia")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("API Settings") {
                    TextField("Bearer token", text: $viewModel.bearerToken)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Text("Token dipakai untuk create, update, dan delete course.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Profile")
        }
    }
}

private struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct CourseCardView: View {
    let course: Course
    private var fallbackDescription: String {
        let trimmed = course.description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Belum ada deskripsi." : trimmed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Course #\(course.id)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Text(course.title)
                .font(.headline)
            Text(fallbackDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}


#Preview {
    ContentView(viewModel: CourseListViewModel())}
