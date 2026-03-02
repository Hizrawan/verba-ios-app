//
//  CourseFormView.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
//

import SwiftUI

struct CourseFormView: View {
    enum Mode {
        case add
        case edit(Course)
    }

    let mode: Mode
    let onSave: (Course?) async -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var descriptionText = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Course") {
                    TextField("Judul course", text: $title)
                    TextEditor(text: $descriptionText)
                        .frame(minHeight: 120)
                }
            }
            .navigationTitle(modeTitle)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Batal") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Simpan") {
                        Task {
                            await save()
                        }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
        }
        .onAppear {
            switch mode {
            case .add:
                title = ""
                descriptionText = ""
            case let .edit(course):
                title = course.title
                descriptionText = course.description ?? ""
            }
        }
    }

    private var modeTitle: String {
        switch mode {
        case .add:
            return "Tambah Course"
        case .edit:
            return "Edit Course"
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        switch mode {
        case .add:
            let newCourse = Course(
                id: -1,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? nil
                    : descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: nil,
                updatedAt: nil
            )
            await onSave(newCourse)
        case let .edit(course):
            let updated = Course(
                id: course.id,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? nil
                    : descriptionText.trimmingCharacters(in: .whitespacesAndNewlines),
                createdAt: course.createdAt,
                updatedAt: course.updatedAt
            )
            await onSave(updated)
        }
        dismiss()
    }
}
