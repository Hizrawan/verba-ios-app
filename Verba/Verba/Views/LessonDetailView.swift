
import SwiftUI

struct LessonDetailView: View {
    let lesson: Lesson
    let lessonNumber: Int
    let totalLessons: Int

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                headerCard
                contentCard
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.16), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("Lesson \(lessonNumber)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)
                    .shadow(color: .green.opacity(0.35), radius: 12, x: 0, y: 6)

                Image(systemName: lesson.type.iconName)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(lesson.title)
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)

            Text("\(lesson.type.title) • Stage \(lessonNumber)/\(totalLessons)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    @ViewBuilder
    private var contentCard: some View {
        switch lesson.type {
        case .material:
            VStack(alignment: .leading, spacing: 12) {
                Label("Materi", systemImage: "book.fill")
                    .font(.headline)
                Text(lesson.content?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                     ? (lesson.content ?? "")
                     : "Materi belum tersedia.")
                    .font(.body)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .lessonContentStyle

        case .flashcard:
            FlashcardDeckView(cards: lesson.flashcards ?? [])
                .lessonContentStyle

        case .multipleChoice:
            MultipleChoiceLessonView(
                questions: lesson.multipleChoiceQuestions
            )
            .lessonContentStyle
        }
    }
}

private struct FlashcardDeckView: View {
    let cards: [FlashcardItem]
    @State private var selectedIndex = 0
    @State private var flippedCardIDs: Set<Int> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Flashcard", systemImage: "rectangle.on.rectangle")
                .font(.headline)

            if cards.isEmpty {
                Text("Flashcard belum tersedia.")
                    .foregroundStyle(.secondary)
            } else {
                TabView(selection: $selectedIndex) {
                    ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                        flashcard(card)
                            .tag(index)
                    }
                }
                .frame(height: 230)
                .tabViewStyle(.page(indexDisplayMode: .always))

                Text("Tap kartu untuk flip.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private func flashcard(_ card: FlashcardItem) -> some View {
        let isFlipped = flippedCardIDs.contains(card.id)
        VStack(spacing: 12) {
            Text(isFlipped ? card.back : card.front)
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(isFlipped ? .green : .primary)
                .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(isFlipped ? Color.green.opacity(0.14) : Color.blue.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(isFlipped ? Color.green.opacity(0.35) : Color.blue.opacity(0.28), lineWidth: 1)
        )
        .onTapGesture {
            if isFlipped {
                flippedCardIDs.remove(card.id)
            } else {
                flippedCardIDs.insert(card.id)
            }
        }
    }
}

private struct MultipleChoiceLessonView: View {
    let questions: [QuizQuestion]

    @State private var selectedOptions: [Int: Int] = [:]
    @State private var checkedQuestions: Set<Int> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Multiple Choice", systemImage: "checkmark.circle.fill")
                .font(.headline)

            if questions.isEmpty {
                Text("Pertanyaan belum tersedia.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(Array(questions.enumerated()), id: \.element.id) { index, question in
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Soal \(index + 1)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(question.prompt)
                            .font(.title3.weight(.semibold))

                        ForEach(question.options) { option in
                            Button {
                                selectedOptions[question.id] = option.id
                            } label: {
                                HStack {
                                    Text(option.text)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if selectedOptions[question.id] == option.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.blue)
                                    }
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 14)
                                .background(
                                    optionBackground(
                                        questionId: question.id,
                                        optionId: option.id
                                    ),
                                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        Button("Cek Jawaban Soal \(index + 1)") {
                            checkedQuestions.insert(question.id)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedOptions[question.id] == nil || question.options.isEmpty)

                        if checkedQuestions.contains(question.id),
                           let selectedOptionId = selectedOptions[question.id],
                           let correctOptionId = question.correctOptionId {
                            let isCorrect = selectedOptionId == correctOptionId
                            Text(isCorrect ? "Benar! 🎉" : "Belum tepat, coba lagi ya.")
                                .font(.headline)
                                .foregroundStyle(isCorrect ? .green : .orange)

                            if let explanation = question.explanation,
                               !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(explanation)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 6)

                    if index < questions.count - 1 {
                        Divider()
                            .padding(.vertical, 4)
                    }
                }
            }
        }
    }

    private func optionBackground(questionId: Int, optionId: Int) -> Color {
        guard selectedOptions[questionId] == optionId else {
            return Color(.secondarySystemBackground)
        }
        return Color.blue.opacity(0.14)
    }
}

private extension View {
    var lessonContentStyle: some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.22), lineWidth: 1)
            )
    }
}
