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

    private var levelLabel: String {
        switch course.id % 3 {
        case 0:
            return "Beginner"
        case 1:
            return "Intermediate"
        default:
            return "Advanced"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Course #\(course.id)", systemImage: "book.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(levelLabel)
                    .font(.caption2.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.12), in: Capsule())
                    .foregroundStyle(.blue)
            }
            Text(course.title)
                .font(.title3.weight(.bold))
            Text(fallbackDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)

            HStack(spacing: 6) {
                Image(systemName: "play.circle.fill")
                Text("Lihat lessons")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.blue)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color(.secondarySystemBackground), Color(.tertiarySystemBackground)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.24), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
    }
}

