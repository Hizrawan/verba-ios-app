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
            lessons = fetchedLessons.isEmpty ? Self.makeDummyLessons(courseId: courseId) : fetchedLessons
            errorMessage = nil
        } catch {
            lessons = Self.makeDummyLessons(courseId: courseId)
            errorMessage = nil
        }
    }

    private static func makeDummyLessons(courseId: Int) -> [Lesson] {
        [
            Lesson(
                id: 9001,
                course_id: courseId,
                title: "Greeting Dasar",
                type: .material,
                content: "Gunakan 'Halo' untuk sapaan umum. Untuk lebih sopan gunakan 'Selamat pagi/siang/malam' sesuai waktu.",
                order: 1
            ),
            Lesson(
                id: 9002,
                course_id: courseId,
                title: "Kartu Kosakata",
                type: .flashcard,
                flashcards: [
                    FlashcardItem(id: 1, front: "Hello", back: "Halo"),
                    FlashcardItem(id: 2, front: "Good morning", back: "Selamat pagi"),
                    FlashcardItem(id: 3, front: "Thank you", back: "Terima kasih")
                ],
                order: 2
            ),
            Lesson(
                id: 9003,
                course_id: courseId,
                title: "Cek Pemahaman",
                type: .multipleChoice,
                questions: [
                    QuizQuestion(
                        id: 31,
                        prompt: "Terjemahan 'Good night' adalah...",
                        options: [
                            ChoiceItem(id: 11, text: "Selamat malam"),
                            ChoiceItem(id: 12, text: "Selamat pagi"),
                            ChoiceItem(id: 13, text: "Sampai jumpa")
                        ],
                        correctOptionId: 11,
                        explanation: "'Good night' dipakai saat malam hari atau sebelum tidur."
                    ),
                    QuizQuestion(
                        id: 32,
                        prompt: "Kapan biasanya kita mengucapkan 'Good morning'?",
                        options: [
                            ChoiceItem(id: 21, text: "Pagi hari"),
                            ChoiceItem(id: 22, text: "Malam hari"),
                            ChoiceItem(id: 23, text: "Setelah berpamitan")
                        ],
                        correctOptionId: 21,
                        explanation: "'Good morning' digunakan pada pagi hari."
                    )
                ],
                order: 3
            )
        ]
    }
}
