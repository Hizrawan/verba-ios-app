//
//  CourseFormView.swift
//  Verba
//
//  Created by Oka on 2026/3/2.
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
            ZStack {
                LinearGradient(
                    colors: [Color(.systemBlue).opacity(0.08), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        HStack(spacing: 10) {
                            Image(systemName: "textformat")
                                .foregroundStyle(.secondary)
                            TextField("Judul course", text: $title)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Deskripsi")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            TextEditor(text: $descriptionText)
                                .frame(minHeight: 130)
                                .scrollContentBackground(.hidden)
                                .padding(8)
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle(modeTitle)
            .navigationBarTitleDisplayMode(.inline)
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
