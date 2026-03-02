//
//  SessionManager.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//


import Foundation
import Combine
import FirebaseAuth

struct WrongAnswerItem: Codable, Equatable, Identifiable {
    let id: String
    let lessonId: Int
    let courseId: Int
    let lessonTitle: String
    let prompt: String
    let userAnswer: String
    let correctAnswer: String
    let recordedAt: Date
}

struct LessonCompletion: Codable, Equatable {
    let lessonId: Int
    let courseId: Int
    let lessonTitle: String
    let wrongAnswers: Int
    let totalQuestions: Int
    let completedAt: Date
    let wrongItems: [WrongAnswerItem]

    enum CodingKeys: String, CodingKey {
        case lessonId
        case courseId
        case lessonTitle
        case wrongAnswers
        case totalQuestions
        case completedAt
        case wrongItems
    }

    init(
        lessonId: Int,
        courseId: Int,
        lessonTitle: String,
        wrongAnswers: Int,
        totalQuestions: Int,
        completedAt: Date,
        wrongItems: [WrongAnswerItem]
    ) {
        self.lessonId = lessonId
        self.courseId = courseId
        self.lessonTitle = lessonTitle
        self.wrongAnswers = wrongAnswers
        self.totalQuestions = totalQuestions
        self.completedAt = completedAt
        self.wrongItems = wrongItems
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lessonId = try container.decode(Int.self, forKey: .lessonId)
        courseId = try container.decode(Int.self, forKey: .courseId)
        lessonTitle = try container.decodeIfPresent(String.self, forKey: .lessonTitle) ?? "Lesson \(lessonId)"
        wrongAnswers = try container.decode(Int.self, forKey: .wrongAnswers)
        totalQuestions = try container.decode(Int.self, forKey: .totalQuestions)
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt) ?? Date()
        wrongItems = try container.decodeIfPresent([WrongAnswerItem].self, forKey: .wrongItems) ?? []
    }
}

final class SessionManager: ObservableObject {
    @Published private(set) var token: String?
    @Published private(set) var email: String?
    @Published private(set) var lessonCompletions: [Int: LessonCompletion] = [:]

    var isAuthenticated: Bool {
        let value = token?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return !value.isEmpty
    }

    var totalExp: Int {
        lessonCompletions.values.reduce(0) { partialResult, completion in
            partialResult + Self.exp(for: completion)
        }
    }

    var level: Int {
        max(1, (totalExp / 100) + 1)
    }

    var expInCurrentLevel: Int {
        totalExp % 100
    }

    let expPerLevel = 100

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

    @discardableResult
    func completeLesson(
        lessonId: Int,
        courseId: Int,
        lessonTitle: String,
        wrongAnswers: Int,
        totalQuestions: Int,
        wrongItems: [WrongAnswerItem]
    ) -> Int {
        lessonCompletions[lessonId] = LessonCompletion(
            lessonId: lessonId,
            courseId: courseId,
            lessonTitle: lessonTitle,
            wrongAnswers: max(0, wrongAnswers),
            totalQuestions: max(0, totalQuestions),
            completedAt: Date(),
            wrongItems: wrongItems
        )
        saveLessonCompletions()
        guard let completion = lessonCompletions[lessonId] else { return 0 }
        return Self.exp(for: completion)
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

    func wrongAnswerItems(for courseId: Int? = nil) -> [WrongAnswerItem] {
        lessonCompletions.values
            .filter { courseId == nil || $0.courseId == courseId }
            .flatMap(\.wrongItems)
            .sorted { $0.recordedAt > $1.recordedAt }
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

    private static func exp(for completion: LessonCompletion) -> Int {
        let totalQuestions = max(1, completion.totalQuestions)
        let correctAnswers = max(0, totalQuestions - max(0, completion.wrongAnswers))
        let accuracy = Double(correctAnswers) / Double(totalQuestions)
        let baseExp = 20
        let bonusExp = Int(round(accuracy * 30))
        return baseExp + bonusExp
    }
}
