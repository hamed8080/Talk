//
// Persistence.swift
// Copyright (c) 2022 LeitnerBox
//
// Created by Hamed Hosseini on 10/28/22.

@preconcurrency import CoreData
import SwiftUI

extension Bundle {
    static var moduleBundle: Bundle {
#if SWIFT_PACKAGE
        return Bundle.module
#else
        return Bundle(identifier: "org.cocoapods.LeitnerBox") ?? Bundle.main
#endif
    }
}

@MainActor
final class PersistenceController: ObservableObject {
    static let isTest: Bool = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_TEST"] == "1"
    static let inMemory = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" || isTest
    static var shared = PersistenceController(inMemory: inMemory)
    public var container: NSPersistentCloudKitContainer?
    public let baseModelFileName = "LeitnerBox"

    var viewContext: NSManagedObjectContext {
        PersistenceController.shared.container?.viewContext ?? NSManagedObjectContext()
    }
    
    private lazy var modelFile: NSManagedObjectModel = {
        guard let modelURL = Bundle.moduleBundle.url(forResource: baseModelFileName, withExtension: "momd") else { fatalError("Couldn't find the mond file!") }
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else { fatalError("Error initializing mom from: \(modelURL)") }
        return mom
    }()
    
    private init(inMemory: Bool = false) {
        UIColorValueTransformer.register()
        let container = NSPersistentCloudKitContainer(name: baseModelFileName, managedObjectModel: modelFile)
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            container.viewContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        self.container = container
    }
    
    public func setup() async -> NSManagedObjectContextProtocol {
        _ = try? await container?.loadPersistentStoresAsync
        return viewContext
    }

    @MainActor
    func replaceDBIfExistFromShareExtension() async {
        let appSuppportFile = moveAppGroupFileToAppSupportFolder()
        if let appSuppportFile {
            await replaceDatabase(appSuppportFile: appSuppportFile)
        }
    }

    func moveAppGroupFileToAppSupportFolder() -> URL? {
        let fileManager = FileManager.default
        guard let appGroupDBFolder = fileManager.appGroupDBFolder else { return nil }
        if let contents = try? fileManager.contentsOfDirectory(atPath: appGroupDBFolder.path).filter({ $0.contains(".sqlite") }), contents.count > 0 {
            let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            let appGroupFile = appGroupDBFolder.appendingPathComponent(contents.first!)
            let appSuppportFile = appSupportDirectory!.appendingPathComponent(contents.first!)
            do {
                if fileManager.fileExists(atPath: appSuppportFile.path) {
                    try fileManager.removeItem(at: appSuppportFile) // to first delete old file and again replace with new one
                }
                try fileManager.moveItem(atPath: appGroupFile.path, toPath: appSuppportFile.path)
                return appSuppportFile
            } catch {
                print("Error to move appgroup file to app support folder\(error.localizedDescription)")
                return nil
            }
        } else {
            return nil
        }
    }

    func replaceDatabase(appSuppportFile: URL) async {
        do {
            let persistentCordinator = container?.persistentStoreCoordinator
            guard let oldStore = persistentCordinator?.persistentStores.first, let oldStoreUrl = oldStore.url else { return }
            try persistentCordinator?.replacePersistentStore(at: oldStoreUrl, withPersistentStoreFrom: appSuppportFile, type: .sqlite)
                _ = try await container?.loadPersistentStoresAsync
            self.objectWillChange.send()
            container?.viewContext.automaticallyMergesChangesFromParent = true
        } catch {
            print("error in restoring back up file\(error.localizedDescription)")
        }
    }

    class func saveDB(viewContext: NSManagedObjectContextProtocol, completionHandler: ((MyError) -> Void)? = nil) {
        do {
            try viewContext.save()
        } catch {
            print("error in save viewContext: ", error)
            completionHandler?(.failToSave)
        }
    }
}

extension NSPersistentCloudKitContainer {
    var loadPersistentStoresAsync: NSPersistentStoreDescription {
        get async throws {
            typealias LoadStoreContinuation = CheckedContinuation<NSPersistentStoreDescription, Error>
            return try await withCheckedThrowingContinuation { (continuation: LoadStoreContinuation) in
                loadPersistentStores { storeDescription, error in
                    if let error = error as NSError? {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: storeDescription)
                    }
                }
            }
        }
    }
}

@MainActor
extension PersistenceController {
    func replace(_ url: URL) async {
        do {
            if let newFileLocation = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.appendingPathComponent(url.lastPathComponent)
            {
                if FileManager.default.fileExists(atPath: newFileLocation.path) {
                    try FileManager.default.removeItem(atPath: newFileLocation.path)
                }
                let isAccessing = url.startAccessingSecurityScopedResource()
                let fileData = try Data(contentsOf: url)
                try fileData.write(to: newFileLocation)
                await replaceDatabase(appSuppportFile: newFileLocation)
                if isAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
        } catch {
            print("error happend\(error.localizedDescription)")
        }
    }
}
