import SwiftUI

public struct ErrorView: View {
    var error: String

    public init(error: String) {
        self.error = error
    }

    public var body: some View {
        HStack {
            Text(error)
                .font(Font.normal(.caption2))
                .foregroundColor(.red.opacity(0.7))
        }
        .padding()
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .background(.red.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius:(8)))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.App.red.opacity(0.7), lineWidth: 1)
        )
    }
}


struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView(error: "TEST")
    }
}
