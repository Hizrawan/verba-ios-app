//
//  SessionManager.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//


import Foundation
import Combine
import FirebaseAuth

struct LessonCompletion: Codable, Equatable {
    let lessonId: Int
    let courseId: Int
    let wrongAnswers: Int
    let totalQuestions: Int
    let completedAt: Date
}

final class SessionManager: ObservableObject {
    @Published private(set) var token: String?
    @Published private(set) var email: String?
    @Published private(set) var lessonCompletions: [Int: LessonCompletion] = [:]

    var isAuthenticated: Bool {
        let value = token?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !value.isEmpty
    }

    private let tokenKey = "verba.auth.token"
    private let emailKey = "verba.auth.email"
    private let lessonProgressKey = "verba.lesson.progress"

    init() {
        token = UserDefaults.standard.string(forKey: tokenKey)
        email = UserDefaults.standard.string(forKey: emailKey)
        lessonCompletions = Self.loadLessonCompletions(from: lessonProgressKey)
    }

    func saveSession(token: String, email: String) {
        self.token = token
        self.email = email
        UserDefaults.standard.set(token, forKey: tokenKey)
        UserDefaults.standard.set(email, forKey: emailKey)
    }

    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            // Tetap hapus session lokal agar user bisa keluar dari app.
        }
        token = nil
        email = nil
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
    }

    func completeLesson(
        lessonId: Int,
        courseId: Int,
        wrongAnswers: Int,
        totalQuestions: Int
    ) {
        lessonCompletions[lessonId] = LessonCompletion(
            lessonId: lessonId,
            courseId: courseId,
            wrongAnswers: max(0, wrongAnswers),
            totalQuestions: max(0, totalQuestions),
            completedAt: Date()
        )
        saveLessonCompletions()
    }

    func isLessonCompleted(_ lessonId: Int) -> Bool {
        lessonCompletions[lessonId] != nil
    }

    func lessonCompletion(for lessonId: Int) -> LessonCompletion? {
        lessonCompletions[lessonId]
    }

    func completedLessonsCount(for courseId: Int) -> Int {
        lessonCompletions.values.filter { $0.courseId == courseId }.count
    }

    func totalWrongAnswers(for courseId: Int? = nil) -> Int {
        lessonCompletions.values
            .filter { courseId == nil || $0.courseId == courseId }
            .reduce(0) { $0 + $1.wrongAnswers }
    }

    private func saveLessonCompletions() {
        do {
            let data = try JSONEncoder().encode(lessonCompletions)
            UserDefaults.standard.set(data, forKey: lessonProgressKey)
        } catch {
            // Keep app responsive if local persistence fails.
        }
    }

    private static func loadLessonCompletions(from key: String) -> [Int: LessonCompletion] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [:] }
        do {
            return try JSONDecoder().decode([Int: LessonCompletion].self, from: data)
        } catch {
            return [:]
        }
    }
}
