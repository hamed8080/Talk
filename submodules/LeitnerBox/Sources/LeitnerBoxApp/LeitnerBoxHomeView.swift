//
// LeitnerBoxHomeView.swift
// Copyright (c) 2022 LeitnerBox
//
// Created by Hamed Hosseini on 10/28/22.

import SwiftUI
import AVFoundation
import CoreData

public struct LeitnerBoxHomeView: View, DropDelegate {
    @State private var dragOver = false
    var isUnitTesting = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_TEST"] == "1"
    @State var context: NSManagedObjectContext?
    
    public init() {
        
    }

    public var body: some View {
        ZStack {
            if isUnitTesting {
                Text("In Unit Testing")
            } else if let context = context {
                LeitnerView()
                    .environment(\.managedObjectContext, context)
                    .environmentObject(LeitnerViewModel(viewContext: context))
                    .environmentObject(NavigationViewModel.shared)
            }
        }
        .onDrop(of: [.fileURL, .data], delegate: self)
        .environment(\.avSpeechSynthesisVoice, AVSpeechSynthesisVoice(identifier:  UserDefaults.standard.string(forKey: "selectedVoiceIdentifire") ?? "") ?? AVSpeechSynthesisVoice(language: "en-GB")!)
        .task {
            let context = await PersistenceController.shared.setup()
            if let context = context as? NSManagedObjectContext {
                self.context = context
            }
        }
    }
    
    public func dropUpdated(info _: DropInfo) -> DropProposal? {
        let proposal = DropProposal(operation: .copy)
        return proposal
    }
    
    public func performDrop(info: DropInfo) -> Bool {
        dropDatabase(info)
        return true
    }
    
    @MainActor
    func dropDatabase(_ info: DropInfo) {
        info.itemProviders(for: [.fileURL, .data]).forEach { item in
            item.loadItem(forTypeIdentifier: item.registeredTypeIdentifiers.first!, options: nil) { data, error in
                if let url = data as? URL {
                    Task { @MainActor in
                        await PersistenceController.shared.replace(url)
                    }
                }
            }
        }
    }
}
