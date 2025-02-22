import SwiftUI
import Chat
import Combine
import TalkViewModels
import TalkModels

public struct BanOverlayView: View {
    @EnvironmentObject var viewModel: BanViewModel
    
    public init() {}
    
    public var body: some View {
        EmptyView()
            .onChange(of: viewModel.timerValue) { newValue in
                if newValue != 0 {
                    AppState.shared.objectsContainer.appOverlayVM.dialogView(canDismiss: false, view: AnyView(
                        BanView()
                            .environmentObject(viewModel)
                    ))
                }
            }
    }
}

struct BanView: View {
    @EnvironmentObject var viewModel: BanViewModel
    
    public var body: some View {
        Text(attr)
            .padding()
            .multilineTextAlignment(.center)
    }
    
    private var attr: AttributedString {
        let localized = "General.ban".bundleLocalized()
        let timerValue = viewModel.timerValue.timerString(locale: Language.preferredLocale) ?? ""
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
}
