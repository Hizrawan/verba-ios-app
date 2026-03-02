//
//  ContentView.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//


import SwiftUI
struct ContentView: View {
    @ObservedObject var viewModel: CourseListViewModel
    @ObservedObject var session: SessionManager
    @State private var selectedTab = 0
    @State private var showAddSheet = false
    @State private var editingCourse: Course?

    var body: some View {
        Group {
            if session.isAuthenticated {
                authenticatedContent
            } else {
                LoginView(session: session) {
                    await viewModel.loadCourses()
                }
            }
        }
        .animation(.easeInOut, value: session.isAuthenticated)
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Terjadi kesalahan.")
        }
    }

    private var authenticatedContent: some View {
        TabView(selection: $selectedTab) {
            HomeTabView(viewModel: viewModel)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)

            CoursesTabView(
                viewModel: viewModel,
                session: session,
                showAddSheet: $showAddSheet,
                editingCourse: $editingCourse
            )
            .tabItem { Label("Courses", systemImage: "book.closed.fill") }
            .tag(1)

            ProfileTabView(session: session)
                .tabItem { Label("Profile", systemImage: "person.crop.circle.fill") }
                .tag(2)
        }
        .environmentObject(session)
        .sheet(isPresented: $showAddSheet) {
            CourseFormView(mode: .add) { course in
                guard let course else { return }
                await viewModel.addCourse(
                    title: course.title,
                    description: course.description,
                    bearerToken: session.token
                )
            }
        }
        .sheet(item: $editingCourse) { course in
            CourseFormView(mode: .edit(course)) { updated in
                guard let updated else { return }
                await viewModel.saveCourse(updated, bearerToken: session.token)
            }
        }
    }
}
