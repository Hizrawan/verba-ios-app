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
