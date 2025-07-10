//
// AddOrEditQuestionView.swift
// Copyright (c) 2022 LeitnerBox
//
// Created by Hamed Hosseini on 10/28/22.

import CoreData
import SwiftUI

struct AddOrEditQuestionView: View {
    @EnvironmentObject var objVM: LeitnerBoxObjectsContainer
    @Environment(\.dismiss) var dissmiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) var context: NSManagedObjectContext
    @State var showTagPicker: Bool = false
    @State var showSuggestion: Bool = false
    @State var showSynonymPicker: Bool = false
    private var questionVMBinding: Binding<QuestionViewModel> { $objVM.questionVM }
    private var questionVM: QuestionViewModel { objVM.questionVM }
    @Environment(\.horizontalSizeClass) private var sizeClass
    @AppStorage("leitner_token") var leitnerToken: String?

    var body: some View {
        HStack(spacing: 0) {
            Spacer()
            ScrollView {
                VStack(spacing: 36) {
                    VStack(alignment: .leading) {
                        TextEditorView(
                            placeholder: "Enter your question here...",
                            shortPlaceholder: "Question",
                            string: questionVMBinding.questionString,
                            textEditorHeight: 48
                        )
                        if questionVM.batchInserPhrasesMode {
                            Text("When you are in the batch mode the question filed automatically split all th questions by (NewLine/Enter).")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }

                    if !questionVM.batchInserPhrasesMode {
                        CheckBoxView(isActive: questionVMBinding.isManual, text: "Manual Answer")
                        if questionVM.isManual {
                            TextEditorView(
                                placeholder: "Enter your Answer here...",
                                shortPlaceholder: "Answer",
                                string: questionVMBinding.answer,
                                textEditorHeight: 48
                            )
                            TextEditorView(
                                placeholder: "Enter your description here...",
                                shortPlaceholder: "Description",
                                string: questionVMBinding.detailDescription,
                                textEditorHeight: 48
                            )
                        }
                    }
                    VStack(alignment: .leading) {
                        HStack {
                            Button {
                                showSuggestion = true
                            } label: {
                                HStack {
                                    Spacer()
                                    Label("Suggestions", systemImage: "tray.full.fill")
                                    Spacer()
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .tint(.accentColor)
                            
                            AddOrEditQuestionSuggestView(suggest: questionVM.questionString, answer: questionVM.answer)
                                .disabled(leitnerToken == nil)
                                .opacity(leitnerToken == nil ? 0.4 : 1.0)
                                .allowsHitTesting(leitnerToken != nil)
                        }
                        Text("Share a word or import words directly from an online word list by clicking on suggestions.")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.gray)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(0)
                    
                    CheckBoxView(isActive: questionVMBinding.completed, text: "Complete Answer")

                    HStack {
                        Button {
                            withAnimation {
                                questionVM.favorite.toggle()
                            }
                        } label: {
                            HStack {
                                Image(systemName: questionVM.favorite == true ? "star.fill" : "star")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 32, height: 32)
                                    .foregroundColor(.accentColor)
                                Text(verbatim: "favorite")
                                    .font(.body.weight(.semibold))
                            }
                        }

                        Spacer()
                    }

                    VStack(alignment: .leading) {
                        Button {
                            showTagPicker.toggle()
                        } label: {
                            Label("Tags", systemImage: "plus.circle")
                        }
                        .keyboardShortcut("t", modifiers: [.command])
                        .buttonStyle(.borderless)
                        QuestionTagList(tags: questionVM.tags) { tag in
                            questionVM.removeTagForQuestion(tag)
                        }

                        Button {
                            showSynonymPicker.toggle()
                        } label: {
                            Label("Synonyms", systemImage: "plus.circle")
                        }
                        .buttonStyle(.borderless)

                        QuestionSynonymList(synonyms: questionVM.synonyms) { _ in

                        } onLongClick: { synonymQuestion in
                            withAnimation {
                                questionVM.removeSynonym(synonymQuestion)
                            }
                        }
                    }
                    Group {
                        QuestionImagesView(isInReviewView: false)
                            .environmentObject(questionVM)
                        if #available(iOS 17.0, macOS 14.0, watchOS 10.0, tvOS 17.0, *) {
                            QuestionLocationView(isInReviewView: false)
                                .environmentObject(questionVM)
                        }
                    }
                    Spacer()
                }
                .padding()
            }
            Spacer()
        }
        .animation(.easeInOut, value: questionVM.tags.count)
        .animation(.easeInOut, value: questionVM.question?.tagsArray?.count)
        .animation(.easeInOut, value: questionVM.synonyms.count)
        .animation(.easeInOut, value: questionVM.completed)
        .animation(.easeInOut, value: questionVM.favorite)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(questionVM.title)
        .animation(.easeInOut, value: questionVM.isManual)
        .toolbar {
            ToolbarItem {
                Button(action: questionVM.reset) {
                    Label("Clear", systemImage: "trash")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color("accent"))
                }
            }

            ToolbarItem {
                Button {
                    withAnimation {
                        questionVM.batchInserPhrasesMode.toggle()
                    }
                } label: {
                    Label("Pharses", systemImage: questionVM.batchInserPhrasesMode ? "plus.app" : "rectangle.stack.badge.plus")
                        .font(.title3)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(colorScheme == .dark ? .white : .black.opacity(0.5), Color("accent"))
                }
            }

            ToolbarItemGroup(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button("Done") {
                        hideKeyboard()
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                Button {
                    questionVM.save()
                    questionVM.reset()
                    dissmiss()
                } label: {
                    HStack {
                        Spacer()
                        Label("Save", systemImage: "checkmark.square.fill")
                        Spacer()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.accentColor)
                .frame(maxWidth: 600)
                Spacer()
            }
            .padding(8)
            .background(Material.regular)
        }
        .contentShape(Rectangle())
        .sheet(isPresented: $showSynonymPicker) {
            QuestionSynonymPickerView { question in
                questionVM.addSynonym(question)
            }
            .environmentObject(objVM)
        }
        .sheet(isPresented: $showTagPicker) {
            TagsListPickerView { tag in
                questionVM.addTagToQuestion(tag)
            }
            .environmentObject(objVM)
        }
        .sheet(isPresented: $showSuggestion) {
            SuggestionListView { suggestion in
                questionVM.questionString = suggestion.suggested
                questionVM.answer = suggestion.answer
            }
            .environmentObject(objVM)
        }
        .onDisappear {
            questionVM.reset()
            context.rollback()
        }
    }
}

#if DEBUG
struct AddQuestionView_Previews: PreviewProvider {
    struct Preview: View {
        static let leitner = MockDatabase.shared.generateAndFillLeitner().first!
        static let question = Question(context: PersistenceController.shared.viewContext)
        @StateObject var viewModel = QuestionViewModel(
            viewContext: PersistenceController.shared.viewContext,
            leitner: Preview.leitner,
            question: question
        )

        var body: some View {
            AddOrEditQuestionView()
                .environmentObject(viewModel)
                .environment(\.managedObjectContext, PersistenceController.shared.viewContext)
        }
    }

    static var previews: some View {
        NavigationStack {
            Preview()
        }
    }
}
#endif
