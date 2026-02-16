import SwiftUI

extension ContentView {
    var headerView: some View {
        HStack {
            QuietButton(action: { withAnimation(.spring()) { underlayMode = .list } }) {
                Image(systemName: "list.dash")
                    .font(.title)
                    .foregroundColor(.blue)
            }
            Spacer()
            Text(displayEventTitle)
                .font(.headline)
                .foregroundColor(deniedCamera ? .primary : .white)
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 50)
        }
    }

    var displayEventTitle: String {
        if eventTitle == "Scholarship week"
            && underlayMode == .home
            && cameraEnabled
            && !deniedCamera
        {
            return "Scan an event-host's QR code now"
        }
        return eventTitle
    }
}
