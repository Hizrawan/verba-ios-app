//
//  CourseListViewModel.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//


import Foundation
import Combine

@MainActor
final class CourseListViewModel: ObservableObject {
    @Published private(set) var courses: [Course] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var bearerToken = ""

    private let apiService: APIService

    init(apiService: APIService? = nil) {
        self.apiService = apiService ?? APIService()
    }

    func loadCourses() async {
        isLoading = true
        defer { isLoading = false }

        do {
            courses = try await apiService.fetchCourses()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addCourse(title: String, description: String?) async {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }
        let trimmedDescription = description?.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            let created = try await apiService.createCourse(
                title: trimmedTitle,
                description: trimmedDescription?.isEmpty == true ? nil : trimmedDescription,
                bearerToken: bearerToken
            )
            courses.insert(created, at: 0)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveCourse(_ course: Course) async {
        do {
            let updated = try await apiService.updateCourse(course, bearerToken: bearerToken)
            if let idx = courses.firstIndex(where: { $0.id == updated.id }) {
                courses[idx] = updated
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(at offsets: IndexSet) async {
        for index in offsets {
            let course = courses[index]
            do {
                try await apiService.deleteCourse(id: course.id, bearerToken: bearerToken)
                courses.remove(at: index)
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
