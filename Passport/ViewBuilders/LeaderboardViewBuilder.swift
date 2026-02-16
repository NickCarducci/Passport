import SwiftUI

extension ContentView {
    @ViewBuilder
    var leaderboardView: some View {
        VStack(alignment: .leading) {
            Text("Leaderboard").font(.title).bold().padding()
            List {
                ForEach($leaders.indices, id: \.self) { index in
                    LeaderView(
                        studentId: leaders[index].id, username: leaders[index].username,
                        eventsAttended: $leaders[index].eventsAttended)
                }
                Color.clear.frame(height: 40)
            }
        }
        .onAppear { getLeaders() }
        .background(Color(uiColor: .systemBackground))
        .padding(.bottom, 10)
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 50)
        }
    }
}
