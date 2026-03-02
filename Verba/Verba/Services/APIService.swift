//
//  APIService.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//


import Foundation

final class APIService {
    private let baseURL = URL(string: "https://staging.verba.api.hizrawan.com/api")!
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchCourses() async throws -> [Course] {
        let request = URLRequest(url: baseURL.appending(path: "courses"))
        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        return try decode([Course].self, from: data)
    }

    func fetchLessons(courseId: Int) async throws -> [Lesson] {
        let request = URLRequest(url: baseURL.appending(path: "lessons/course/\(courseId)"))
        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        return try decode([Lesson].self, from: data)
    }

    func createCourse(title: String, description: String?, bearerToken: String) async throws -> Course {
        let cleanedToken = bearerToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedToken.isEmpty else { throw APIError.missingBearerToken }
        let url = baseURL.appending(path: "courses")
        let body = CourseCreateRequest(title: title, description: description)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(cleanedToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        return try decode(Course.self, from: data)
    }

    func updateCourse(_ course: Course, bearerToken: String) async throws -> Course {
        let cleanedToken = bearerToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedToken.isEmpty else { throw APIError.missingBearerToken }
        let url = baseURL.appending(path: "courses/\(course.id)")
        let body = CourseUpdateRequest(title: course.title, description: course.description)

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(cleanedToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        try validate(response: response)
        return try decode(Course.self, from: data)
    }

    func deleteCourse(id: Int, bearerToken: String) async throws {
        let cleanedToken = bearerToken.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedToken.isEmpty else { throw APIError.missingBearerToken }
        let url = baseURL.appending(path: "courses/\(id)")
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(cleanedToken)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await session.data(for: request)
        try validate(response: response)
    }

    private func validate(response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw APIError.serverError(statusCode: http.statusCode)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }

}

enum APIError: LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int)
    case decoding(Error)
    case missingBearerToken

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Server response tidak valid."
        case let .serverError(statusCode):
            return "Server error dengan status code \(statusCode)."
        case let .decoding(error):
            return "Gagal parsing response: \(error.localizedDescription)"
        case .missingBearerToken:
            return "Bearer token wajib diisi untuk create, update, atau delete course."
        }
    }
}
