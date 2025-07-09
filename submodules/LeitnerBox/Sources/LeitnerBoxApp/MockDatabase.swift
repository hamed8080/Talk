//
//  MockDatabase.swift
//  LeitnerBoxApp
//
//  Created by Hamed Hosseini on 4/6/25.
//

#if DEBUG
import CoreData
import UIKit

@MainActor
class MockDatabase {
    static let shared = MockDatabase()
    private init() {}
    
    var viewContext: NSManagedObjectContext {
        PersistenceController.shared.container?.viewContext ?? NSManagedObjectContext()
    }
    
    func generateAndFillLeitner() -> [Leitner] {
        let leitners = generateLeitner(5)
        leitners.forEach { leitner in
            generateLevels(leitner: leitner).forEach { level in
                let questions = generateQuestions(20, level, leitner)
                generateTags(5, leitner).forEach { tag in
                    questions.forEach { question in
                        generateImages().forEach { image in
                            question.addToImages(image)
                        }
                        tag.addToQuestion(question)
                        generateStatistics(question)
                    }
                }
            }
        }
        PersistenceController.saveDB(viewContext: viewContext)
        return leitners
    }

    func generateLevels(leitner: Leitner) -> [Level] {
        var levels: [Level] = []
        for index in 1 ... 13 {
            let level = Level(context: viewContext)
            level.level = Int16(index)
            level.leitner = leitner
            level.daysToRecommend = 8
            levels.append(level)
        }
        return levels
    }

    func generateLeitner(_ count: Int) -> [Leitner] {
        var leitners: [Leitner] = []
        for index in 0 ..< count {
            let leitner = Leitner(context: viewContext)
            leitner.createDate = Date()
            leitner.name = "Leitner \(index)"
            leitner.id = Int64(index)
            leitners.append(leitner)
        }
        return leitners
    }

    func generateTags(_ count: Int, _ leitner: Leitner) -> [Tag] {
        var tags: [Tag] = []
        for index in 0 ..< count {
            let tag = Tag(context: viewContext)
            tag.name = "Tag \(index)-\(UUID().uuidString)"
            tag.color = UIColor.random()
            tag.leitner = leitner
            tags.append(tag)
        }
        return tags
    }

    func generateStatistics(_ question: Question) {
        let statistic = Statistic(context: viewContext)
        statistic.actionDate = Calendar.current.date(byAdding: .day, value: -(Int.random(in: 1 ... 360)), to: .now)
        statistic.isPassed = Bool.random()
        statistic.question = question
    }
    
    func generateImages() -> [ImageURL] {
        var images: [ImageURL] = []
        for _ in 0...10 {
            let imageURL = ImageURL(context: viewContext)
            imageURL.url = "www.google.com"
            images.append(imageURL)
        }
        return images
    }

    func generateQuestions(_ count: Int, _ level: Level, _ leitner: Leitner) -> [Question] {
        var questions: [Question] = []
        for index in 0 ..< count {
            let question = Question(context: viewContext)
            question.question = "Question \(index)"
            question.answer = "Answer with long text to test how it looks like on small screen we want to sure that the text is perfectly fit on the screen on smart phones and computers even with huge large screen \(index)"
            question.level = level
            question.passTime = level.level == 1 ? nil : Date().advanced(by: -(24 * 360))
            question.completed = Bool.random()
            question.favorite = Bool.random()
            question.createTime = Date()
            question.leitner = leitner

            questions.append(question)
        }
        return questions
    }
}
#endif
