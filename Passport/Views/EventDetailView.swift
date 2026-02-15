import SwiftUI

struct EventDetailView: View {
    let event: Event
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 24) {
                Text(event.title)
                    .font(.title)
                    .bold()
                    .padding(.top, 32)

                Text(dateFromString(date: event.date), style: .date)
                    .font(.body)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Location:")
                        .font(.headline)
                    Text(event.location)
                        .font(.body)
                }

                QuietButton(action: {
                    openDirections(to: event.location)
                }) {
                    HStack {
                        Image(systemName: "map.fill")
                        Text("Get Directions")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.top, 8)

                Spacer()

                QuietButton(action: {
                    isPresented = false
                }) {
                    Text("Back")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundColor(.blue)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(uiColor: .systemBackground))
            .navigationBarHidden(true)
        }
    }

    private func openDirections(to location: String) {
        let encodedLocation =
            location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? location

        if let url = URL(string: "http://maps.apple.com/?q=\(encodedLocation)") {
            UIApplication.shared.open(url)
        } else {
            if let url = URL(
                string: "https://www.google.com/maps/search/?api=1&query=\(encodedLocation)")
            {
                UIApplication.shared.open(url)
            }
        }
    }
}
