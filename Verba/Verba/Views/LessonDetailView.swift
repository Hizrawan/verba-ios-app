
import SwiftUI

struct LessonDetailView: View {
    let lesson: Lesson
    let lessonNumber: Int
    let totalLessons: Int
    @EnvironmentObject private var session: SessionManager
    @Environment(\.dismiss) private var dismiss
    @State private var currentPageIndex = 0
    @State private var selectedAnswers: [String: Int] = [:]
    @State private var checkedPages: Set<String> = []
    @State private var pageEvaluations: [String: AnswerEvaluation] = [:]
    @State private var showCompletionAlert = false
    @State private var expGained = 0
    @State private var submitErrorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    currentPageView
                }
                .padding(16)
            }
            footerNavigation
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Lesson \(lessonNumber)")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Lesson Selesai", isPresented: $showCompletionAlert) {
            Button("Kembali") { dismiss() }
        } message: {
            Text("Kamu menyelesaikan lesson dengan \(wrongAnswersCount) jawaban salah dan mendapat +\(expGained) EXP.")
        }
        .alert("Gagal Simpan Progress", isPresented: Binding(
            get: { submitErrorMessage != nil },
            set: { if !$0 { submitErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(submitErrorMessage ?? "Terjadi kesalahan.")
        }
    }

    private var headerCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: lesson.type.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.green.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(lesson.title)
                        .font(.headline)
                        .lineLimit(2)
                    Text(lesson.type.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }

            ProgressView(value: Double(currentPageIndex + 1), total: Double(max(pages.count, 1)))
                .tint(.green)
            Text("\(currentPageIndex + 1) / \(max(pages.count, 1))")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private var currentPageView: some View {
        if pages.indices.contains(currentPageIndex) {
            switch pages[currentPageIndex] {
            case let .material(text):
                MaterialPageView(text: text)
                    .lessonContentStyle
            case let .flashcard(card, index, total):
                FlashcardPageView(card: card, index: index, total: total)
                    .lessonContentStyle
            case let .flashcardMatching(pageId, prompt, options, correctOptionId):
                MatchingPageView(
                    pageId: pageId,
                    prompt: prompt,
                    options: options,
                    correctOptionId: correctOptionId,
                    selectedAnswers: $selectedAnswers,
                    checkedPages: $checkedPages,
                    pageEvaluations: $pageEvaluations
                )
                .lessonContentStyle
            case let .multipleChoice(pageId, question, index, total):
                MultipleChoicePageView(
                    pageId: pageId,
                    question: question,
                    index: index,
                    total: total,
                    selectedAnswers: $selectedAnswers,
                    checkedPages: $checkedPages,
                    pageEvaluations: $pageEvaluations
                )
                .lessonContentStyle
            }
        } else {
            Text("Konten lesson tidak tersedia.")
                .foregroundStyle(.secondary)
                .lessonContentStyle
        }
    }

    private var footerNavigation: some View {
        HStack(spacing: 16) {
            Button {
                currentPageIndex = max(0, currentPageIndex - 1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(currentPageIndex == 0 ? .tertiary : .primary)
            .disabled(currentPageIndex == 0)

            Spacer(minLength: 0)

            Button {
                if isLastPage {
                    completeLesson()
                } else {
                    currentPageIndex = min(pages.count - 1, currentPageIndex + 1)
                }
            } label: {
                HStack(spacing: 6) {
                    Text(isLastPage ? "Selesai" : "Lanjut")
                        .font(.subheadline.weight(.semibold))
                    Image(systemName: isLastPage ? "checkmark" : "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(canMoveNext ? Color.green : Color.gray, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!canMoveNext)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(.regularMaterial)
    }

    private var pages: [LessonPage] {
        switch lesson.type {
        case .material:
            return [.material(text: lesson.content?.trimmedNonEmpty ?? "Materi belum tersedia.")]
        case .flashcard:
            let cards = lesson.flashcards ?? []
            var allPages: [LessonPage] = cards.enumerated().map { index, card in
                .flashcard(card: card, index: index + 1, total: cards.count)
            }
            if let matching = makeMatchingPage(from: cards) {
                allPages.append(matching)
            }
            if allPages.isEmpty {
                allPages = [.material(text: "Flashcard belum tersedia.")]
            }
            return allPages
        case .multipleChoice:
            let questions = lesson.multipleChoiceQuestions
            if questions.isEmpty {
                return [.material(text: "Pertanyaan belum tersedia.")]
            }
            return questions.enumerated().map { index, question in
                .multipleChoice(
                    pageId: "mc_\(question.id)",
                    question: question,
                    index: index + 1,
                    total: questions.count
                )
            }
        }
    }

    private func makeMatchingPage(from cards: [FlashcardItem]) -> LessonPage? {
        guard cards.count >= 2 else { return nil }
        let sourceCard = cards[0]
        let optionCards = Array(cards.prefix(min(cards.count, 4)))
        let options = optionCards.enumerated().map { index, item in
            ChoiceItem(id: sourceCard.id * 10 + index, text: item.back)
        }
        let correctIndex = optionCards.firstIndex(where: { $0.id == sourceCard.id }) ?? 0
        let correctOptionId = sourceCard.id * 10 + correctIndex
        return .flashcardMatching(
            pageId: "match_\(sourceCard.id)",
            prompt: sourceCard.front,
            options: options,
            correctOptionId: correctOptionId
        )
    }

    private var currentPageNeedsCheck: Bool {
        guard pages.indices.contains(currentPageIndex) else { return false }
        switch pages[currentPageIndex] {
        case .flashcardMatching, .multipleChoice:
            return true
        case .material, .flashcard:
            return false
        }
    }

    private var currentPageId: String? {
        guard pages.indices.contains(currentPageIndex) else { return nil }
        switch pages[currentPageIndex] {
        case let .flashcardMatching(pageId, _, _, _):
            return pageId
        case let .multipleChoice(pageId, _, _, _):
            return pageId
        case .material, .flashcard:
            return nil
        }
    }

    private var canMoveNext: Bool {
        if !currentPageNeedsCheck { return true }
        guard let pageId = currentPageId else { return false }
        return checkedPages.contains(pageId)
    }

    private var isLastPage: Bool {
        currentPageIndex == max(0, pages.count - 1)
    }

    private var wrongAnswersCount: Int {
        let wrongPages = pageEvaluations.values.filter { !$0.isCorrect }.count
        return wrongPages
    }

    private var totalQuestionCount: Int {
        pages.reduce(0) { partialResult, page in
            switch page {
            case .flashcardMatching, .multipleChoice:
                return partialResult + 1
            case .material, .flashcard:
                return partialResult
            }
        }
    }

    private func completeLesson() {
        let wrongItems = pageEvaluations
            .values
            .filter { !$0.isCorrect }
            .map { evaluation in
                WrongAnswerItem(
                    id: "\(lesson.id)_\(evaluation.pageId)",
                    lessonId: lesson.id,
                    courseId: lesson.course_id,
                    lessonTitle: lesson.title,
                    prompt: evaluation.prompt,
                    userAnswer: evaluation.userAnswer,
                    correctAnswer: evaluation.correctAnswer,
                    recordedAt: Date()
                )
            }

        Task {
            do {
                expGained = try await session.completeLesson(
                    lessonId: lesson.id,
                    courseId: lesson.course_id,
                    lessonTitle: lesson.title,
                    wrongAnswers: wrongAnswersCount,
                    totalQuestions: totalQuestionCount,
                    wrongItems: wrongItems
                )
                showCompletionAlert = true
            } catch {
                submitErrorMessage = error.localizedDescription
            }
        }
    }
}

private enum LessonPage {
    case material(text: String)
    case flashcard(card: FlashcardItem, index: Int, total: Int)
    case flashcardMatching(pageId: String, prompt: String, options: [ChoiceItem], correctOptionId: Int)
    case multipleChoice(pageId: String, question: QuizQuestion, index: Int, total: Int)
}

private struct MaterialPageView: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct FlashcardPageView: View {
    let card: FlashcardItem
    let index: Int
    let total: Int
    @State private var isFlipped = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(index)/\(total)")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Text(isFlipped ? card.back : card.front)
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
                .foregroundStyle(isFlipped ? Color.green : .primary)
                .frame(maxWidth: .infinity, minHeight: 200)
                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .onTapGesture { isFlipped.toggle() }

            Text("Ketuk kartu untuk balik")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

private struct MatchingPageView: View {
    let pageId: String
    let prompt: String
    let options: [ChoiceItem]
    let correctOptionId: Int
    @Binding var selectedAnswers: [String: Int]
    @Binding var checkedPages: Set<String>
    @Binding var pageEvaluations: [String: AnswerEvaluation]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Arti dari: \(prompt)")
                .font(.headline)

            VStack(spacing: 10) {
                ForEach(options) { option in
                    Button {
                        selectedAnswers[pageId] = option.id
                    } label: {
                        HStack {
                            Text(option.text)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            if selectedAnswers[pageId] == option.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body)
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding(14)
                        .background(optionBackground(for: option.id), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            Button { checkAnswer() } label: {
                Text("Cek Jawaban")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(selectedAnswers[pageId] == nil || options.isEmpty)

            if checkedPages.contains(pageId), let selectedId = selectedAnswers[pageId] {
                let isCorrect = selectedId == correctOptionId
                Text(isCorrect ? "Benar" : "Belum tepat")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(isCorrect ? .green : .orange)
            }
        }
    }

    private func optionBackground(for optionId: Int) -> Color {
        guard selectedAnswers[pageId] == optionId else {
            return Color(.tertiarySystemGroupedBackground)
        }
        return Color.green.opacity(0.12)
    }

    private func checkAnswer() {
        guard let selectedId = selectedAnswers[pageId] else { return }
        checkedPages.insert(pageId)
        let selectedText = options.first(where: { $0.id == selectedId })?.text ?? "-"
        let correctText = options.first(where: { $0.id == correctOptionId })?.text ?? "-"
        pageEvaluations[pageId] = AnswerEvaluation(
            pageId: pageId,
            isCorrect: selectedId == correctOptionId,
            prompt: "Arti dari '\(prompt)'",
            userAnswer: selectedText,
            correctAnswer: correctText
        )
    }
}

private struct MultipleChoicePageView: View {
    let pageId: String
    let question: QuizQuestion
    let index: Int
    let total: Int
    @Binding var selectedAnswers: [String: Int]
    @Binding var checkedPages: Set<String>
    @Binding var pageEvaluations: [String: AnswerEvaluation]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(index)/\(total)")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Text(question.prompt)
                .font(.headline)

            VStack(spacing: 10) {
                ForEach(question.options) { option in
                    Button {
                        selectedAnswers[pageId] = option.id
                    } label: {
                        HStack {
                            Text(option.text)
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            if selectedAnswers[pageId] == option.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.body)
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding(14)
                        .background(optionBackground(for: option.id), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            Button { checkAnswer() } label: {
                Text("Cek Jawaban")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .disabled(selectedAnswers[pageId] == nil || question.options.isEmpty)

            if checkedPages.contains(pageId),
               let selectedId = selectedAnswers[pageId],
               let correctOptionId = question.correctOptionId {
                let isCorrect = selectedId == correctOptionId
                VStack(alignment: .leading, spacing: 6) {
                    Text(isCorrect ? "Benar" : "Belum tepat")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(isCorrect ? .green : .orange)
                    if let explanation = question.explanation,
                       !explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(explanation)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func optionBackground(for optionId: Int) -> Color {
        guard selectedAnswers[pageId] == optionId else {
            return Color(.tertiarySystemGroupedBackground)
        }
        return Color.green.opacity(0.12)
    }

    private func checkAnswer() {
        guard let selectedId = selectedAnswers[pageId] else { return }
        checkedPages.insert(pageId)
        guard let correctOptionId = question.correctOptionId else {
            pageEvaluations[pageId] = AnswerEvaluation(
                pageId: pageId,
                isCorrect: true,
                prompt: question.prompt,
                userAnswer: question.options.first(where: { $0.id == selectedId })?.text ?? "-",
                correctAnswer: "-"
            )
            return
        }
        let selectedText = question.options.first(where: { $0.id == selectedId })?.text ?? "-"
        let correctText = question.options.first(where: { $0.id == correctOptionId })?.text ?? "-"
        pageEvaluations[pageId] = AnswerEvaluation(
            pageId: pageId,
            isCorrect: selectedId == correctOptionId,
            prompt: question.prompt,
            userAnswer: selectedText,
            correctAnswer: correctText
        )
    }
}

private extension View {
    var lessonContentStyle: some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private struct AnswerEvaluation {
    let pageId: String
    let isCorrect: Bool
    let prompt: String
    let userAnswer: String
    let correctAnswer: String
}
