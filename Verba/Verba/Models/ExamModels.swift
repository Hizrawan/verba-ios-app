//
//  ExamModels.swift
//  Verba
//
//  Sesuai skema database & OpenAPI: Exams, ExamQuestions, ExamQuestionOptions, ExamQuestionPairs, Rewards.
//

import Foundation

// MARK: - Exam (tabel Exams)
struct Exam: Codable, Identifiable, Equatable {
    let id: Int
    let courseId: Int
    let title: String?
    let description: String?
    let totalQuestions: Int
    let passingScore: Int
    let createdAt: String?
    let updatedAt: String?
    let questions: [ExamQuestion]?

    enum CodingKeys: String, CodingKey {
        case id
        case courseId = "course_id"
        case title
        case description
        case totalQuestions = "total_questions"
        case passingScore = "passing_score"
        case createdAt = "createdAt"
        case updatedAt = "updatedAt"
        case questions
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        courseId = try c.decode(Int.self, forKey: .courseId)
        title = try c.decodeIfPresent(String.self, forKey: .title)
        description = try c.decodeIfPresent(String.self, forKey: .description)
        totalQuestions = try c.decodeIfPresent(Int.self, forKey: .totalQuestions) ?? 0
        passingScore = try c.decodeIfPresent(Int.self, forKey: .passingScore) ?? 70
        createdAt = try c.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try c.decodeIfPresent(String.self, forKey: .updatedAt)
        questions = try c.decodeIfPresent([ExamQuestion].self, forKey: .questions)
    }
}

// MARK: - Exam Question (tabel ExamQuestions)
enum ExamQuestionType: String, Codable {
    case multipleChoice = "multiple_choice"
    case matching
}

struct ExamQuestion: Codable, Identifiable, Equatable {
    let id: Int
    let examId: Int
    let type: ExamQuestionType?
    let prompt: String?
    let options: [ExamQuestionOption]?
    let pairs: [ExamQuestionPair]?

    enum CodingKeys: String, CodingKey {
        case id
        case examId = "exam_id"
        case type
        case prompt
        case options
        case pairs
    }
}

// MARK: - Exam Question Option (tabel ExamQuestionOptions)
struct ExamQuestionOption: Codable, Identifiable, Equatable {
    let id: Int
    let questionId: Int
    let text: String?
    let isCorrect: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case questionId = "question_id"
        case text
        case isCorrect = "is_correct"
    }
}

// MARK: - Exam Question Pair (tabel ExamQuestionPairs)
struct ExamQuestionPair: Codable, Identifiable, Equatable {
    let id: Int
    let questionId: Int
    let leftText: String?
    let rightText: String?

    enum CodingKeys: String, CodingKey {
        case id
        case questionId = "question_id"
        case leftText = "left_text"
        case rightText = "right_text"
    }
}

// MARK: - Reward (tabel Rewards)
struct Reward: Codable, Identifiable, Equatable {
    let id: Int
    let userId: Int
    let xp: Int
    let source: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case xp
        case source
        case createdAt
        case updatedAt
    }
}
