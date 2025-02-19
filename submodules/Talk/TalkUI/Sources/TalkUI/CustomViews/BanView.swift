import SwiftUI
import Chat
import Combine
import TalkViewModels
import TalkModels

public struct BanOverlayView: View {
    @State private var cancelable = Set<AnyCancellable>()
    
    public init() {}
    
    public var body: some View {
        EmptyView()
            .task {
                registerEvent()
            }
    }
    
    private func registerEvent() {
        NotificationCenter.error.publisher(for: .error)
            .sink { notif in
                if let response = notif.object as? ChatResponse<Sendable> {
                    self.handelBanError(response: response)
                }
            }
            .store(in: &cancelable)
    }
    
    private func handelBanError(response: ChatResponse<Sendable>) {
        guard let error = response.error,
              let code = error.code,
              ServerErrorType(rawValue: code) == .temporaryBan,
              let data = error.message?.data(using: .utf8),
              let banError = try? JSONDecoder.instance.decode(BanError.self, from: data)
        else { return }
        /// We added 0.5 seconds to make sure the server will accept our request.
        let time = (TimeInterval(banError.duration ?? 0) / 1000) + 0.5
        let view = AnyView(BanView(banError: banError))
        AppState.shared.objectsContainer.appOverlayVM.dialogView(canDismiss: false, view: view)
        Timer.scheduledTimer(withTimeInterval: time, repeats: false) { _ in
            Task { @MainActor in
                AppState.shared.objectsContainer.appOverlayVM.dialogView(canDismiss: false, view: nil)
            }
        }
    }
}

struct BanView: View {
    let banError: BanError
    @State private var time: TimeInterval = 0
    
    public var body: some View {
        Text(attr)
            .padding()
            .multilineTextAlignment(.center)
            .task {
                time = banTime
                startTimer()
            }
    }
    
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                time -= 1
            }
        }
    }
    
    private var attr: AttributedString {
        let localized = "General.ban".bundleLocalized()
        let timerValue = time.timerString(locale: Language.preferredLocale) ?? ""
        let string = String(format: localized, "\(timerValue)")
        let attr = NSMutableAttributedString(string: string)
        if let range = string.range(of: string) {
            let allRange = NSRange(range, in: string)
            attr.addAttributes([.foregroundColor: Color.App.textPrimary, .font: UIFont.uiiransansLargeTitle], range: allRange)
        }
        if let range = string.range(of: timerValue) {
            let nsRange = NSRange(range, in: string)
            attr.addAttributes([.foregroundColor: UIColor.red, .font: UIFont.uiiransansBoldLargeTitle], range: nsRange)
        }
        return AttributedString(attr)
    }
    
    private var banTime: TimeInterval {
        let banTime = banError.duration ?? 0
        return TimeInterval(banTime / 1000)
    }
}
