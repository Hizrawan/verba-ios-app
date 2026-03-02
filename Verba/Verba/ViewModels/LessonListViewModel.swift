//
//  LessonListViewModel.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//

import Foundation
import Combine

@MainActor
final class LessonListViewModel: ObservableObject {
    @Published private(set) var lessons: [Lesson] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService: APIService

    init(apiService: APIService? = nil) {
        self.apiService = apiService ?? APIService()
    }

    func loadLessons(courseId: Int) async {
        isLoading = true
        defer { isLoading = false }

        do {
            lessons = try await apiService.fetchLessons(courseId: courseId)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
