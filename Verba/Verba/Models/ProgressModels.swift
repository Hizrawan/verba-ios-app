import Foundation

struct CourseProgressSummary: Codable, Equatable {
    let courseId: Int
    let totalLessons: Int
    let completedLessons: Int
    let progressPercent: Int
    let totalWrongAnswers: Int

    enum CodingKeys: String, CodingKey {
        case courseId = "course_id"
        case totalLessons = "total_lessons"
        case completedLessons = "completed_lessons"
        case progressPercent = "progress_percent"
        case totalWrongAnswers = "total_wrong_answers"
    }
}

struct ProgressHistoryItem: Codable, Equatable, Identifiable {
    let id: Int
    let userId: Int
    let courseId: Int
    let lessonId: Int
    let score: Int
    let wrongCount: Int
    let xpGained: Int
    let completedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case courseId = "course_id"
        case lessonId = "lesson_id"
        case score
        case wrongCount = "wrong_count"
        case xpGained = "xp_gained"
        case completedAt = "completed_at"
    }
}

struct ProgressSyncRequest: Codable, Equatable {
    let lessonId: Int
    let courseId: Int?
    let completed: Bool?
    let score: Int?
    let wrongCount: Int?
    let xpGained: Int?
    let completedAt: String?
    let wrongAnswers: [WrongAnswerBulkItem]?

    enum CodingKeys: String, CodingKey {
        case lessonId = "lesson_id"
        case courseId = "course_id"
        case completed
        case score
        case wrongCount = "wrong_count"
        case xpGained = "xp_gained"
        case completedAt = "completed_at"
        case wrongAnswers = "wrong_answers"
    }
}

struct WrongAnswerBulkItem: Codable, Equatable {
    let lessonId: Int
    let courseId: Int
    let lessonTitle: String
    let prompt: String
    let userAnswer: String
    let correctAnswer: String
    let recordedAt: String

    enum CodingKeys: String, CodingKey {
        case lessonId = "lesson_id"
        case courseId = "course_id"
        case lessonTitle = "lesson_title"
        case prompt
        case userAnswer = "user_answer"
        case correctAnswer = "correct_answer"
        case recordedAt = "recorded_at"
    }
}

struct ProgressRecord: Codable, Equatable {
    let id: Int
    let userId: Int
    let lessonId: Int
    let completed: Bool
    let score: Int
    let wrongCount: Int
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case lessonId = "lesson_id"
        case completed
        case score
        case wrongCount = "wrong_count"
        case createdAt
        case updatedAt
    }
}

struct WrongAnswerBulkResponse: Codable, Equatable {
    let inserted: Int
}
