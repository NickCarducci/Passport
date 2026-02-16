import SwiftUI

extension ContentView {
    @ViewBuilder
    var listView: some View {
        VStack(alignment: .leading) {
            HStack {
                QuietButton(action: { withAnimation(.spring()) { underlayMode = .profile } }) {
                    Image(systemName: "person.crop.circle").font(.title2)
                }
                Spacer()
                Text("Events").font(.title).bold()
                Spacer()
                QuietButton(action: { withAnimation(.spring()) { underlayMode = .leaderboard } }) {
                    Image(systemName: "list.number").font(.title2)
                }
            }
            .padding()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ScrollPositionTracker(.top, in: "listScroll", isAtEdge: $isAtTop)
                    ForEach($rocks.indices, id: \.self) { index in
                        EventView(
                            title: $rocks[index].title,
                            location: $rocks[index].location,
                            date: $rocks[index].date,
                            descriptionLink: $rocks[index].descriptionLink,
                            onTap: {
                                handleEventTap(event: rocks[index])
                            },
                            onLongPress: {
                                presentEventDetail(event: rocks[index])
                            }
                        )
                        Divider()
                    }
                }
                .padding(.bottom, 70)
            }
            .coordinateSpace(name: "listScroll")
        }
        .padding(.bottom, 10)
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 50)
        }
        .onAppear { getEvents() }
        .sheet(isPresented: $showEventDetail) {
            if let event = selectedEvent {
                EventDetailView(event: event, isPresented: $showEventDetail)
            }
        }
    }
}
