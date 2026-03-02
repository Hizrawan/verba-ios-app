//
//  CourseCardView.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//


import SwiftUI

struct CourseCardView: View {
    let course: Course

    private var fallbackDescription: String {
        let trimmed = course.description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Belum ada deskripsi." : trimmed
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Course #\(course.id)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "pencil")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Text(course.title)
                .font(.headline)
            Text(fallbackDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            Text("Tap untuk lihat lessons")
                .font(.caption)
                .foregroundStyle(.blue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
