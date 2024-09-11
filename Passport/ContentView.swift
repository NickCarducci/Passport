//
//  ContentView.swift
//  Passport
//
//  Created by Nicholas Carducci on 9/7/24.
//
import Foundation
import PromiseKit
import SwiftUI
import Firebase
import FirebaseAuth
import CodeScanner
let db = Firestore.firestore()
//import FirebaseMessaging
extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}
func dateFromString (date: String) -> Date {
    // create dateFormatter with UTC time format
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
    let date = dateFormatter.date(from: date) ?? Date.now
    return date
}
struct EventView: View {
    @Binding public var title:String
    @Binding public var bodyy:String
    @Binding public var date:String
    let defaults = UserDefaults.standard
    var body: some View {
        HStack{
            Text("\(dateFromString(date:date)) \(title):\(bodyy)")
                .padding(10)
        }
    }
}
struct Event {
    var id: String
    var title: String
    var date: String
    var body: String
}
extension Event: Decodable {
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case date = "date"
        case body = "body"
    }
    init(from decoder: Decoder) throws {
        let podcastContainer = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try podcastContainer.decode(String.self, forKey: .id)
        self.title = try podcastContainer.decode(String.self, forKey: .title)
        self.date = try podcastContainer.decode(String.self, forKey: .date)
        self.body = try podcastContainer.decode(String.self, forKey: .body)
    }
}

enum FirebaseError: Error {
    case Error
    case VerificatrionEmpty
}
struct ContentView: View {
    
    @State var verificationCode = ""
    @State var verificationID = ""
    @State var phoneNumber = ""
    @State var countryCodeNumber = "+1"
    @State var country = ""
    @State var smsTextCode = ""
    @State var timerExpired = false
    @State var timeStr = ""
    @State var timeRemaining = 60
    @State var loggedin = false
    @State var verificationId = ""
    @State var verifiable = false
    @State var testing = false
    @GestureState private var isTapped = false
    //@State var session: User = User(coder: NSCoder())!
    
    @State private var rocks = [Event]()
    @State public var show: String = "home"
    @State public var openedEvent: String = ""
    @State public var eventTitle: String = "Scan a QR code"
    @State public var eventBody: String = ""

    init() {
        // Use Firebase library to configure APIs
        FirebaseApp.configure()
        self.microsoftProvider = OAuthProvider(providerID: "microsoft.com")
        
    }

    func signOut(){
        if Auth.auth().currentUser != nil {
            do {
                try Auth.auth().signOut()
            }
            catch {
              print (error)
            }
        }
    
        loggedin = false
    }
    var microsoftProvider : OAuthProvider?
    func signIn () {

        self.microsoftProvider?.getCredentialWith(_: nil){credential, error in

            if error != nil {
                // Handle error.
                print(error?.localizedDescription ?? "")
            }

            if let credential = credential {

                Auth.auth().signIn(with: credential) { (authResult, error) in

                    if error != nil {
                        // Handle error.
                    }

                    guard let authResult = authResult else {
                        print("Couldn't get graph authResult")
                        return
                    }

                    print(authResult.user)

                    // get credential and token when login successfully
                    let microCredential = authResult.credential as! OAuthCredential
                    let token = microCredential.accessToken!

                    // use token to call Microsoft Graph API
                    // ...
                }
            }
        }
    }
    func getEvents () {
        
        rocks = []
        let db = Firestore.firestore()
        db.collection("events")//.whereField("city", isEqualTo: placename)
            .getDocuments() { (querySnapshot, error) in
                        if let error = error {
                                print("Error getting documents: \(error)")
                        } else {
                                if querySnapshot!.documents.isEmpty {
                                    return print("is empty")
                                }
                            
                                for document in querySnapshot!.documents {
                                        //print("\(document.documentID): \(document.data())")
                                    let event = Event(id: document.documentID,title: document["title"] as? String ?? "", date: document["date"] as? String ?? "",body: document["body"] as? String ?? "")
                                    //print(post)
                                    
                                    rocks.append(event)
                                    
                                }
                            rocks.sort {
                                dateFromString(date: $0.date) < dateFromString(date: $1.date)
                            }
                        }
                }
    }
    func openEvent (eventId: String) {
        
        Task {
            let docRef = db.collection("events").document(eventId)
            
            do {
                let document = try await docRef.getDocument()
                if document.exists {
                    let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                    print("Document data: \(dataDescription)")
                    let event = Event(id: document.documentID,title: document["title"] as? String ?? "", date: document["date"] as? String ?? "",body: document["body"] as? String ?? "")
                    eventTitle = event.title
                    eventBody = event.body
                    
                } else {
                    print("Document does not exist")
                }
            } catch {
                print("Error getting document: \(error)")
            }
        }
    }
    func attendEvent (eventId:String) {
        Task {
            let eventRef = db.collection("events").document(eventId)
            
            // Set the "capital" field of the city 'DC'
            do {
                try await eventRef.updateData([
                    "attendees": FieldValue.arrayUnion([Auth.auth().currentUser?.uid ?? ""])
                ])
                print("Document successfully updated")
            } catch {
                print("Error updating document: \(error)")
            }
        }
    }
    var body: some View {
        if Auth.auth().currentUser == nil && !loggedin {
            Form{
                Section(footer: Text("Get an SMS code. Standard messaging rates apply.")) {
                    TextField("Country code", text: $countryCodeNumber)
                        .font(Font.system(size: 15))
                        .fontWeight(.semibold)
                        .frame(width: nil, height: nil, alignment: .leading)
                        .onChange(of: countryCodeNumber) {
                          verifiable = false
                        }
                    TextField("Enter your phone number", text: $phoneNumber)
                        .font(Font.system(size: 15))
                        .fontWeight(.semibold)
                        .frame(width: nil, height: nil, alignment: .leading)
                        .onChange(of: phoneNumber) {
                          verifiable = false
                        }
                }
                if verifiable {
                    Section{
                        TextField("SMS code", text: $verificationCode)
                            .font(Font.system(size: 15))
                            .fontWeight(.semibold)
                            .frame(width: nil, height: nil, alignment: .leading)
                    }
                }
                Button("Submit", action: {
                    
                    if !verifiable {
                        /*let _ = Auth.auth().addStateDidChangeListener({ (auth, user) in
                            if let _ = user {
                                loggedin = true
                                //session = user
                            } else {
                                loggedin = false
                                //session = User(coder: NSCoder())!
                            }
                        })*/
                        
                        //testing = true
                        //Auth.auth().settings?.isAppVerificationDisabledForTesting = true
                        /*let _ = PhoneAuthProvider.provider(auth: Auth.auth())
                        PhoneAuthProvider.provider().verifyPhoneNumber(
                            countryCodeNumber + phoneNumber, uiDelegate: nil) { verificationID, error in
                            if error != nil {
                                print(error!.localizedDescription)
                                return
                            }
                            guard let verificationID = verificationID else {
                                print(FirebaseError.VerificatrionEmpty)
                                return
                            }
                            verificationId = verificationID
                            verifiable = true
                        }*/
                        verifiable = true
                        /*firstly {
                            signUp(phoneNumber: countryCodeNumber + phoneNumber)
                        }.done(on: DispatchQueue.main) { id in
                            verificationId = id
                        }.catch { (error) in
                            print(error.localizedDescription)
                        }*/
                    } else {
                        /*let credential = PhoneAuthProvider.provider().credential(
                          withVerificationID: verificationId,
                          verificationCode: smsTextCode
                        )
                        Auth.auth().signIn(with: credential) { authResult, error in
                            if error != nil {
                                print(FirebaseError.Error)
                                return
                            }
                            guard let authResult = authResult else {
                                print(FirebaseError.VerificatrionEmpty)
                                return
                            }
                            _ = authResult
                         loggedin = true
                        }*/
                        loggedin = true
                    }
                    
                    
                })
                Section(footer: Text("Sign in with Microsoft.")) {
                    Button(action: signIn) {
                        Text("Sign in with Microsoft")
                    }
                }
            }
        }
        if(testing){
            Text(countryCodeNumber + phoneNumber)
        }
        
        if Auth.auth().currentUser != nil || loggedin {
            if show == "list"{
                VStack(alignment: .leading) {
                    Text("Events")
                        .onTapGesture {
                            getEvents()
                        }
                    
                    GeometryReader { geometry in
                        ScrollView {
                            List {
                                ForEach ($rocks.indices, id: \.self){ index in
                                    EventView(title:$rocks[index].title,bodyy:$rocks[index].body,
                                              date:$rocks[index].date
                                    )
                                    .onTapGesture {
                                        openedEvent = rocks[index].id
                                        openEvent(eventId:openedEvent)
                                        show = "home"
                                    }
                                }
                            }
                            .frame(width: geometry.size.width,
                                   height: geometry.size.height)
                        }
                        .frame(height: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(x: show == "list" ? 0 : -UIScreen.screenWidth)
            }
            if show == "leaderboard"{
                VStack(alignment: .leading) {
                    Text("Leaderboard")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(x: show == "leaderboard" ? 0 : UIScreen.screenWidth)
            }
            if show == "home" {
                NavigationView {
                    Text(eventBody)
                        .navigationTitle(eventTitle)
                        .toolbar(content: {
                            // 1
                            ToolbarItem(placement: .navigationBarTrailing) {
                                
                                Button(action: {
                                    print("Trailing button tapped")
                                    show = "leaderboard"
                                }) {
                                    Image(systemName: "person")
                                        .foregroundColor(.blue)
                                }
                            }
                            // 2
                            ToolbarItem(placement: .navigationBarLeading) {
                                
                                Button(action: {
                                    print("Leading button tapped")
                                    show = "list"
                                }) {
                                    Image(systemName: "list.dash")
                                        .foregroundColor(.blue)
                                }
                            }
                        })
                }
                
                CodeScannerView(codeTypes: [.qr], simulatedData: "PUCYMbQTTVlmTitXH8nO") { response in
                    switch response {
                    case .success(let result):
                        openEvent(eventId: result.string)
                        attendEvent(eventId: result.string)
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            }
            Text(show != "home" ? "back" : "logout")
                .font(Font.system(size: 15))
                .fontWeight(.semibold)
                .frame(width: nil, height: nil, alignment: .leading)
                .onTapGesture {
                    
                    if show == "home"{
                        //signOut()
                        loggedin = false
                        verifiable = false
                    } else {
                        show = "home"
                    }
                }
        }
    }
}


#Preview {
    ContentView()
}


