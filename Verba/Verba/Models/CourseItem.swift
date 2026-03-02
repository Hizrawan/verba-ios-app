//
//  Item.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//
import Foundation

struct Course: Codable, Identifiable, Equatable {
    let id: Int
    var title: String
    var description: String?
    let createdAt: String?
    let updatedAt: String?
}

struct CourseCreateRequest: Codable {
    let title: String
    let description: String?
}

struct CourseUpdateRequest: Codable {
    let title: String
    let description: String?
}

enum LessonType: String, Codable, Equatable {
    case material
    case flashcard
    case multipleChoice = "multiple_choice"

    var title: String {
        switch self {
        case .material:
            return "Materi"
        case .flashcard:
            return "Flashcard"
        case .multipleChoice:
            return "Quiz"
        }
    }

    var iconName: String {
        switch self {
        case .material:
            return "book.pages.fill"
        case .flashcard:
            return "rectangle.on.rectangle.fill"
        case .multipleChoice:
            return "checklist"
        }
    }
}

struct FlashcardItem: Codable, Identifiable, Equatable {
    let id: Int
    let front: String
    let back: String
}

struct ChoiceItem: Codable, Identifiable, Equatable {
    let id: Int
    let text: String
}

struct QuizQuestion: Codable, Identifiable, Equatable {
    let id: Int
    let prompt: String
    let options: [ChoiceItem]
    let correctOptionId: Int?
    let explanation: String?

    enum CodingKeys: String, CodingKey {
        case id
        case prompt
        case options
        case correctOptionId = "correct_option_id"
        case explanation
    }
}

struct Lesson: Codable, Identifiable, Equatable {
    let id: Int
    let course_id: Int
    let title: String
    let type: LessonType
    let content: String?
    let flashcards: [FlashcardItem]?
    let questions: [QuizQuestion]?
    let question: String?
    let options: [ChoiceItem]?
    let correctOptionId: Int?
    let explanation: String?
    let order: Int?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case course_id
        case title
        case type
        case content
        case flashcards
        case questions
        case question
        case options
        case correctOptionId = "correct_option_id"
        case explanation
        case order
        case createdAt
        case updatedAt
    }

    init(
        id: Int,
        course_id: Int,
        title: String,
        type: LessonType = .material,
        content: String? = nil,
        flashcards: [FlashcardItem]? = nil,
        questions: [QuizQuestion]? = nil,
        question: String? = nil,
        options: [ChoiceItem]? = nil,
        correctOptionId: Int? = nil,
        explanation: String? = nil,
        order: Int? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.course_id = course_id
        self.title = title
        self.type = type
        self.content = content
        self.flashcards = flashcards
        self.questions = questions
        self.question = question
        self.options = options
        self.correctOptionId = correctOptionId
        self.explanation = explanation
        self.order = order
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        course_id = try container.decode(Int.self, forKey: .course_id)
        title = try container.decode(String.self, forKey: .title)

        let rawType = try container.decodeIfPresent(String.self, forKey: .type)?.lowercased()
        type = LessonType(rawValue: rawType ?? "") ?? .material

        content = try container.decodeIfPresent(String.self, forKey: .content)
        flashcards = try container.decodeIfPresent([FlashcardItem].self, forKey: .flashcards)
        questions = try container.decodeIfPresent([QuizQuestion].self, forKey: .questions)
        question = try container.decodeIfPresent(String.self, forKey: .question)
        options = try container.decodeIfPresent([ChoiceItem].self, forKey: .options)
        correctOptionId = try container.decodeIfPresent(Int.self, forKey: .correctOptionId)
        explanation = try container.decodeIfPresent(String.self, forKey: .explanation)
        order = try container.decodeIfPresent(Int.self, forKey: .order)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }

    var multipleChoiceQuestions: [QuizQuestion] {
        if let questions, !questions.isEmpty {
            return questions
        }

        guard
            let prompt = question?.trimmingCharacters(in: .whitespacesAndNewlines),
            !prompt.isEmpty,
            let options,
            !options.isEmpty
        else {
            return []
        }

        return [
            QuizQuestion(
                id: id * 1000 + 1,
                prompt: prompt,
                options: options,
                correctOptionId: correctOptionId,
                explanation: explanation
            )
        ]
    }
}
