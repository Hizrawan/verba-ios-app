
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
                VStack(spacing: 18) {
                    headerCard
                    currentPageView
                }
                .padding()
            }
            footerNavigation
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

            ProgressView(value: Double(currentPageIndex + 1), total: Double(max(pages.count, 1)))
                .tint(.green)
                .padding(.top, 4)

            Text("Halaman \(currentPageIndex + 1) dari \(max(pages.count, 1))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
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
        HStack(spacing: 12) {
            Button("Prev") {
                currentPageIndex = max(0, currentPageIndex - 1)
            }
            .buttonStyle(.bordered)
            .disabled(currentPageIndex == 0)

            Button(isLastPage ? "Selesai" : "Next") {
                if isLastPage {
                    completeLesson()
                } else {
                    currentPageIndex = min(pages.count - 1, currentPageIndex + 1)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canMoveNext)
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 18)
        .background(.ultraThinMaterial)
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
        VStack(alignment: .leading, spacing: 12) {
            Label("Materi", systemImage: "book.fill")
                .font(.headline)
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
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
        VStack(alignment: .leading, spacing: 12) {
            Label("Flashcard \(index)/\(total)", systemImage: "rectangle.on.rectangle")
                .font(.headline)
            Text("Tap kartu untuk flip.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                Text(isFlipped ? card.back : card.front)
                    .font(.title3.weight(.bold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(isFlipped ? .green : .primary)
                    .padding()
            }
            .frame(maxWidth: .infinity, minHeight: 220)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isFlipped ? Color.green.opacity(0.14) : Color.blue.opacity(0.12))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(isFlipped ? Color.green.opacity(0.35) : Color.blue.opacity(0.28), lineWidth: 1)
            )
            .onTapGesture { isFlipped.toggle() }
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
        VStack(alignment: .leading, spacing: 12) {
            Label("Cocokkan Arti", systemImage: "arrow.left.arrow.right.circle.fill")
                .font(.headline)
            Text("Arti dari: **\(prompt)**")
                .font(.title3.weight(.semibold))

            ForEach(options) { option in
                Button {
                    selectedAnswers[pageId] = option.id
                } label: {
                    HStack {
                        Text(option.text)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selectedAnswers[pageId] == option.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(optionBackground(for: option.id), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Button("Cek Jawaban") { checkAnswer() }
                .buttonStyle(.borderedProminent)
                .disabled(selectedAnswers[pageId] == nil || options.isEmpty)

            if checkedPages.contains(pageId),
               let selectedId = selectedAnswers[pageId] {
                let isCorrect = selectedId == correctOptionId
                Text(isCorrect ? "Benar! 🎉" : "Belum tepat, coba lagi ya.")
                    .font(.headline)
                    .foregroundStyle(isCorrect ? .green : .orange)
            }
        }
    }

    private func optionBackground(for optionId: Int) -> Color {
        guard selectedAnswers[pageId] == optionId else {
            return Color(.secondarySystemBackground)
        }
        return Color.blue.opacity(0.14)
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
        VStack(alignment: .leading, spacing: 12) {
            Label("Multiple Choice \(index)/\(total)", systemImage: "checkmark.circle.fill")
                .font(.headline)

            Text(question.prompt)
                .font(.title3.weight(.semibold))

            ForEach(question.options) { option in
                Button {
                    selectedAnswers[pageId] = option.id
                } label: {
                    HStack {
                        Text(option.text)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selectedAnswers[pageId] == option.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(optionBackground(for: option.id), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Button("Cek Jawaban") { checkAnswer() }
                .buttonStyle(.borderedProminent)
                .disabled(selectedAnswers[pageId] == nil || question.options.isEmpty)

            if checkedPages.contains(pageId),
               let selectedId = selectedAnswers[pageId],
               let correctOptionId = question.correctOptionId {
                let isCorrect = selectedId == correctOptionId
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
    }

    private func optionBackground(for optionId: Int) -> Color {
        guard selectedAnswers[pageId] == optionId else {
            return Color(.secondarySystemBackground)
        }
        return Color.blue.opacity(0.14)
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
            .padding(16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.22), lineWidth: 1)
            )
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
