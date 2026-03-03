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
    private let apiService: APIService

    init(apiService: APIService? = nil) {
        self.apiService = apiService ?? APIService()
        token = UserDefaults.standard.string(forKey: tokenKey)
        email = UserDefaults.standard.string(forKey: emailKey)
        lessonCompletions = Self.loadLessonCompletions(from: lessonProgressKey)
    }

    func saveSession(token: String, email: String) {
        self.token = token
        self.email = email
        UserDefaults.standard.set(token, forKey: tokenKey)
        UserDefaults.standard.set(email, forKey: emailKey)
        Task { await refreshProgressFromServer() }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            // Tetap hapus session lokal agar user bisa keluar dari app.
        }
        token = nil
        email = nil
        lessonCompletions = [:]
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
        UserDefaults.standard.removeObject(forKey: lessonProgressKey)
    }

    @discardableResult
    func completeLesson(
        lessonId: Int,
        courseId: Int,
        lessonTitle: String,
        wrongAnswers: Int,
        totalQuestions: Int,
        wrongItems: [WrongAnswerItem]
    ) async throws -> Int {
        let normalizedWrong = max(0, wrongAnswers)
        let normalizedTotal = max(0, totalQuestions)
        let gainedExp = Self.exp(forWrongCount: normalizedWrong, totalQuestions: normalizedTotal)
        let completedAtDate = Date()
        let completedAt = ISO8601DateFormatter().string(from: completedAtDate)
        let bulkItems = wrongItems.map {
            WrongAnswerBulkItem(
                lessonId: $0.lessonId,
                courseId: $0.courseId,
                lessonTitle: $0.lessonTitle,
                prompt: $0.prompt,
                userAnswer: $0.userAnswer,
                correctAnswer: $0.correctAnswer,
                recordedAt: ISO8601DateFormatter().string(from: $0.recordedAt)
            )
        }

        let syncPayload = ProgressSyncRequest(
            lessonId: lessonId,
            courseId: courseId,
            completed: true,
            score: max(0, normalizedTotal - normalizedWrong),
            wrongCount: normalizedWrong,
            xpGained: nil,
            completedAt: completedAt,
            wrongAnswers: nil
        )
        let bearerToken = try await resolveBearerToken()
        do {
            _ = try await apiService.syncProgress(syncPayload, bearerToken: bearerToken)
            try await postWrongAnswersIfPossible(bulkItems, bearerToken: bearerToken)
        } catch let APIError.serverError(statusCode) where statusCode == 500 {
            let fallbackPayload = ProgressSyncRequest(
                lessonId: lessonId,
                courseId: nil,
                completed: true,
                score: nil,
                wrongCount: normalizedWrong,
                xpGained: nil,
                completedAt: nil,
                wrongAnswers: nil
            )
            _ = try await apiService.syncProgress(fallbackPayload, bearerToken: bearerToken)
            try await postWrongAnswersIfPossible(bulkItems, bearerToken: bearerToken)
        } catch let APIError.serverError(statusCode) where statusCode == 401 {
            let refreshedToken = try await resolveBearerToken(forceRefresh: true)
            _ = try await apiService.syncProgress(syncPayload, bearerToken: refreshedToken)
            try await postWrongAnswersIfPossible(bulkItems, bearerToken: refreshedToken)
        }

        lessonCompletions[lessonId] = LessonCompletion(
            lessonId: lessonId,
            courseId: courseId,
            lessonTitle: lessonTitle,
            wrongAnswers: normalizedWrong,
            totalQuestions: normalizedTotal,
            completedAt: completedAtDate,
            wrongItems: wrongItems
        )
        saveLessonCompletions()
        return gainedExp
    }

    func refreshProgressFromServer() async {
        do {
            let bearerToken = try await resolveBearerToken()
            let history: [ProgressHistoryItem]
            do {
                history = try await apiService.fetchProgressHistory(bearerToken: bearerToken)
            } catch let APIError.serverError(statusCode) where statusCode == 401 {
                let refreshedToken = try await resolveBearerToken(forceRefresh: true)
                history = try await apiService.fetchProgressHistory(bearerToken: refreshedToken)
            }
            var rebuilt: [Int: LessonCompletion] = [:]
            for item in history {
                let existing = rebuilt[item.lessonId]
                let completion = LessonCompletion(
                    lessonId: item.lessonId,
                    courseId: item.courseId,
                    lessonTitle: existing?.lessonTitle ?? "Lesson \(item.lessonId)",
                    wrongAnswers: max(item.wrongCount, existing?.wrongAnswers ?? 0),
                    totalQuestions: max(item.score + item.wrongCount, existing?.totalQuestions ?? 0),
                    completedAt: Self.parseDate(item.completedAt) ?? Date(),
                    wrongItems: existing?.wrongItems ?? []
                )
                rebuilt[item.lessonId] = completion
            }
            if !rebuilt.isEmpty {
                lessonCompletions = rebuilt
                saveLessonCompletions()
            }
        } catch {
            // Keep using local snapshot when network fails.
        }
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

    private static func exp(forWrongCount wrongCount: Int, totalQuestions: Int) -> Int {
        let completion = LessonCompletion(
            lessonId: 0,
            courseId: 0,
            lessonTitle: "",
            wrongAnswers: max(0, wrongCount),
            totalQuestions: max(0, totalQuestions),
            completedAt: Date(),
            wrongItems: []
        )
        return exp(for: completion)
    }

    private static func parseDate(_ raw: String?) -> Date? {
        guard let raw else { return nil }
        return ISO8601DateFormatter().date(from: raw)
    }

    private func resolveBearerToken(forceRefresh: Bool = false) async throws -> String {
        if let currentUser = Auth.auth().currentUser {
            let freshToken = try await currentUser.getIDTokenForcingRefresh(forceRefresh)
            token = freshToken
            UserDefaults.standard.set(freshToken, forKey: tokenKey)
            return freshToken
        }

        if let token, !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return token
        }

        throw APIError.missingBearerToken
    }

    private func postWrongAnswersIfPossible(_ bulkItems: [WrongAnswerBulkItem], bearerToken: String) async throws {
        guard !bulkItems.isEmpty else { return }
        do {
            _ = try await apiService.recordWrongAnswersBulk(bulkItems, bearerToken: bearerToken)
        } catch {
            // Do not fail lesson completion if wrong-answer review endpoint fails.
        }
    }
}
