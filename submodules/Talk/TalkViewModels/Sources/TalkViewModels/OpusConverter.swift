import Foundation
import ffmpegkit
import Chat
import TalkExtensions

class OpusConverter {
    private init(path: URL) {}

    public static func isOpus(path: URL) async -> Bool {
        typealias Comepletion = CheckedContinuation<Bool, Never>
        return await withCheckedContinuation { (result: Comepletion) in
            isOpusAudio(path: path) { isOpus in
                result.resume(returning: isOpus)
            }
        }
    }

    private static func isOpusAudio(path: URL, _ completion: @escaping (Bool) -> Void) {
        FFprobeKit.executeAsync("-v quiet -select_streams a:0 -show_entries stream=codec_name -of default=noprint_wrappers=1:nokey=1 \(path)") { session in
            let returnCode = session?.getReturnCode()
            let output = session?.getOutput()
            let codecName = output?.trimmingCharacters(in: .whitespacesAndNewlines)
            let isOpus = codecName == "opus"
            completion(isOpus)
        }
    }

    public static func convert(_ message: Message) async -> URL? {
        typealias Completion = CheckedContinuation<URL?, Never>
        return await withCheckedContinuation { (result: Completion) in
            convertAudio(message) { url in
                result.resume(returning: url)
            }
        }
    }

    private static func convertAudio(_ message: Message, _ completion: @escaping (URL?) -> Void){
        guard
            let path = message.fileURL,
            let output = message.convertedFileURL,
            let convertedDIR = Message.convertedDIRURL
        else {
            completion(nil)
            return
        }
        createConvertDir(convertedDIR)
        removeOldFile(output)

        FFmpegKit.executeAsync("-i \(path.path()) -vn -c:a aac \(output)") { session in
            let returnCode = session?.getReturnCode()
            if ReturnCode.isSuccess(returnCode) {
                completion(output)
            } else {
                completion(nil)
            }
        }
    }

    private static func createConvertDir(_ convertedDIR: URL) {
        if !FileManager.default.fileExists(atPath: convertedDIR.path())  {
            do {
                try FileManager.default.createDirectory(atPath: convertedDIR.path(), withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating directory: \(error)")
            }
        }
    }

    private static func removeOldFile(_ output: URL) {
        // Check if the file already exists, and if so, remove it
        if FileManager.default.fileExists(atPath: output.path()) {
            do {
                try FileManager.default.removeItem(atPath: output.path())
                print("Existing file removed successfully.")
            } catch {
                print("Error removing existing file: \(error)")
                return
            }
        }
    }
}
