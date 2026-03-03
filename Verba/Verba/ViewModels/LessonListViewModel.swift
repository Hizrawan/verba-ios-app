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
            let fetchedLessons = try await apiService.fetchLessons(courseId: courseId)
            lessons = fetchedLessons.sorted {
                ($0.lessonOrder ?? .max, $0.id) < ($1.lessonOrder ?? .max, $1.id)
            }
            errorMessage = nil
        } catch {
            lessons = []
            errorMessage = error.localizedDescription
        }
    }
}
