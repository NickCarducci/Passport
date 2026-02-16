import SwiftUI
import Firebase
import FirebaseAuth

extension ContentView {
    func getEvents() {
        if !rocks.isEmpty { return }
        let db = Firestore.firestore()
        db.collection("events")
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                } else {
                    if querySnapshot!.documents.isEmpty {
                        return print("is empty")
                    }

                    for document in querySnapshot!.documents {
                        let event = Event(
                            id: document.documentID, title: document["title"] as? String ?? "",
                            date: document["date"] as? String ?? "",
                            location: document["location"] as? String ?? "",
                            descriptionLink: document["descriptionLink"] as? String ?? "")
                        rocks.append(event)
                    }
                    rocks.sort {
                        dateFromString(date: $0.date) < dateFromString(date: $1.date)
                    }
                }
            }
    }

    func getLeaders() {
        leaders = []
        let db = Firestore.firestore()
        db.collection("leaders")
            .order(by: "eventsAttended", descending: false)
            .getDocuments { (querySnapshot, error) in
                if let error = error {
                    print("Error getting documents: \(error)")
                } else {
                    if querySnapshot!.documents.isEmpty {
                        return print("is empty")
                    }

                    for document in querySnapshot!.documents {
                        let leader = Leader(
                            id: document.documentID,
                            eventsAttended: document["eventsAttended"] as? Int64 ?? 0,
                            username: document["username"] as? String ?? "")
                        leaders.append(leader)
                    }
                    leaders.sort {
                        $0.eventsAttended > $1.eventsAttended
                    }
                }
            }
    }

    func openEvent(eventId: String) {
        Task {
            db.collection("events").document(eventId)
                .addSnapshotListener { documentSnapshot, error in
                    guard let document = documentSnapshot else {
                        print("Error fetching document: \(error!)")
                        return
                    }
                    guard let data = document.data() else {
                        print("Document data was empty.")
                        return
                    }
                    print("Current data: \(data)")
                    let event = Event(
                        id: document.documentID, title: document["title"] as? String ?? "",
                        date: document["date"] as? String ?? "",
                        location: document["location"] as? String ?? "",
                        descriptionLink: document["descriptionLink"] as? String ?? "")
                    eventTitle = event.title
                    eventBody = event.date + ": " + event.location
                }
        }
    }

    func attendEvent(eventId: String, address: String, fullName: String) {
        guard let user = Auth.auth().currentUser else { return }
        Task {
            guard let idToken = try? await user.getIDToken() else {
                print("Failed to get ID token")
                return
            }

            let attendBody = try? JSONSerialization.data(withJSONObject: [
                "eventId": eventId,
                "fullName": fullName,
                "address": address,
            ])
            var attendReq = URLRequest(url: URL(string: "https://pass.contact/api/attend")!)
            attendReq.httpMethod = "POST"
            attendReq.setValue("application/json", forHTTPHeaderField: "Content-Type")
            attendReq.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
            attendReq.httpBody = attendBody

            guard let (attendData, _) = try? await URLSession.shared.data(for: attendReq),
                  let messenger = try? JSONDecoder().decode(Message.self, from: attendData)
            else {
                print("Attend request failed")
                return
            }

            DispatchQueue.main.async {
                withAnimation(.spring()) {
                    if messenger.message == "attended" {
                        self.eventTitle = messenger.message + " " + messenger.title
                    } else {
                        self.eventTitle = messenger.message
                    }
                    self.underlayMode = .list
                    presentEventDetail(eventId: eventId)
                }
            }
        }
    }

    func loadUsername() {
        let slug = Auth.auth().currentUser?.email?.components(separatedBy: "@").first ?? ""
        if !slug.isEmpty {
            db.collection("leaders").document(slug).getDocument { doc, error in
                if let doc = doc, doc.exists {
                    username = doc.data()?["username"] as? String ?? ""
                }
            }
        }
    }

    func presentEventDetail(event: Event) {
        selectedEvent = event
        showEventDetail = true
    }

    func presentEventDetail(eventId: String) {
        if let event = rocks.first(where: { $0.id == eventId }) {
            presentEventDetail(event: event)
            return
        }
        db.collection("events").document(eventId).getDocument { doc, error in
            guard let doc = doc, doc.exists else { return }
            let event = Event(
                id: doc.documentID,
                title: doc["title"] as? String ?? "",
                date: doc["date"] as? String ?? "",
                location: doc["location"] as? String ?? "",
                descriptionLink: doc["descriptionLink"] as? String ?? ""
            )
            DispatchQueue.main.async {
                presentEventDetail(event: event)
            }
        }
    }

    func handleEventTap(event: Event) {
        if !event.descriptionLink.isEmpty && isValidHttpsUrl(event.descriptionLink) {
            if let url = URL(string: event.descriptionLink) {
                UIApplication.shared.open(url)
            }
        } else {
            presentEventDetail(event: event)
        }
    }
}
