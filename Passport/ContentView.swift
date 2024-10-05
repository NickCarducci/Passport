//
//  ContentView.swift
//  Passport
//
//  Created by Nicholas Carducci on 9/7/24.
//
import Foundation
import AVFoundation
//import PromiseKit
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
    @Binding public var location:String
    @Binding public var date:String
    @Binding public var descriptionLink:String
    let defaults = UserDefaults.standard
    var body: some View {
        HStack{
            Link("\(dateFromString(date:date)) \(title): \(location)",
                 destination: URL(string: descriptionLink)!)
                .foregroundColor(.black)
                .padding(10)
        }
    }
}
struct Event {
    var id: String
    var title: String
    var date: String
    var location: String
    var attendees: Array<String>
    var descriptionLink: String
}
extension Event: Decodable {
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case date = "date"
        case location = "location"
        case attendees = "attendees"
        case descriptionLink = "descriptionLink"
    }
    init(from decoder: Decoder) throws {
        let podcastContainer = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try podcastContainer.decode(String.self, forKey: .id)
        self.title = try podcastContainer.decode(String.self, forKey: .title)
        self.date = try podcastContainer.decode(String.self, forKey: .date)
        self.location = try podcastContainer.decode(String.self, forKey: .location)
        self.attendees = try podcastContainer.decode(Array.self, forKey: .attendees)
        self.descriptionLink = try podcastContainer.decode(String.self, forKey: .descriptionLink)
    }
}
struct LeaderView: View {
    @Binding public var username:String
    @Binding public var eventsAttended:Int64
    let defaults = UserDefaults.standard
    var body: some View {
        HStack{
            Text("\(username): \(eventsAttended)")
                .padding(10)
        }
    }
}
struct Leader {
    var id: String
    var username: String
    var eventsAttended: Int64
}
extension Leader: Decodable {
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case username = "username"
        case eventsAttended = "eventsAttended"
    }
    init(from decoder: Decoder) throws {
        let podcastContainer = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try podcastContainer.decode(String.self, forKey: .id)
        self.username = try podcastContainer.decode(String.self, forKey: .username)
        self.eventsAttended = try podcastContainer.decode(Int64.self, forKey: .eventsAttended)
    }
}

enum FirebaseError: Error {
    case Error
    case VerificatrionEmpty
}
struct ContentView: View {
    @Environment(\.scenePhase) var scenePhase
    
    @State var alertCamera = "Go to Settings, Passport, and then Allow Passport to Access: Camera"
    @State var address = ""
    @State var promptAddress = false
    @State var fullName = ""
    @State var studentId = ""
    @State var addressLine1 = ""
    @State var addressLine2 = ""
    @State var city = ""
    @State var state = ""
    @State var zipCode = ""
    @State var phoneNumber = ""
    @State var countryCodeNumber = "+1"
    @State var country = ""
    @State var smsTextCode = ""
    @State var deniedCamera = true
    @State var loggedin = false
    @State var verificationId = ""
    @State var verifiable = false
    @State var testing = false
    //@State var session: User = User(coder: NSCoder())!
    
    @State var newUsername = ""
    @State private var rocks = [Event]()
    @State private var leaders = [Leader]()
    @State public var show: String = "home"
    @State public var openedEvent: String = ""
    @State public var eventTitle: String = "Scan a QR code"
    @State public var eventBody: String = ""

    init() {
        // Use Firebase library to configure APIs
        //FirebaseApp.configure()
        //self.microsoftProvider = OAuthProvider(providerID: "microsoft.com")
        
    }

    func signOut(){
        //if Auth.auth().currentUser != nil {
            do {
                try Auth.auth().signOut()
            }
            catch {
              print (error)
            }
        //}
    
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
                    // uncomment this for warning
                    //let microCredential = authResult.credential as! OAuthCredential
                    //let _ = microCredential.accessToken!

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
                                    let event = Event(id: document.documentID,title: document["title"] as? String ?? "", date: document["date"] as? String ?? "",location: document["location"] as? String ?? "",attendees: document["attendees"] as? Array<String> ?? [],descriptionLink: document["descriptionLink"] as? String ?? "")
                                    //print(post)
                                    
                                    rocks.append(event)
                                    
                                }
                            rocks.sort {
                                dateFromString(date: $0.date) < dateFromString(date: $1.date)
                            }
                        }
                }
    }
    func getLeaders () {
        
        leaders = []
        let db = Firestore.firestore()
        db.collection("leaders")//.whereField("city", isEqualTo: placename)
            .order(by: "eventsAttended", descending: false)
            .getDocuments() { (querySnapshot, error) in
                        if let error = error {
                                print("Error getting documents: \(error)")
                        } else {
                                if querySnapshot!.documents.isEmpty {
                                    return print("is empty")
                                }
                            
                                for document in querySnapshot!.documents {
                                        //print("\(document.documentID): \(document.data())")
                                    let leader = Leader(id: document.documentID,username: document["username"] as? String ?? "",eventsAttended: document["eventsAttended"] as? Int64 ?? 0)
                                    //print(post)
                                    
                                    leaders.append(leader)
                                    
                                }
                            leaders.sort {
                                $0.eventsAttended > $1.eventsAttended
                            }
                        }
                }
    }
    func openEvent (eventId: String) {
        
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
                  let event = Event(id: document.documentID,title: document["title"] as? String ?? "", date: document["date"] as? String ?? "",location: document["location"] as? String ?? "",attendees: document["attendees"] as? Array<String> ?? [],descriptionLink: document["descriptionLink"] as? String ?? "")
                  eventTitle = event.title
                  eventBody = event.date + ": " + event.location
              }
        }
    }
    func attendEvent (eventId:String) {
        deniedCamera = true
        
        Task {
            let docRef = db.collection("events").document(eventId)
            
            do {
                let document = try await docRef.getDocument()
                if document.exists {
                    alertCamera = "Thank you"
                    let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                    print("Document data: \(dataDescription)")
                    let event = Event(id: document.documentID,title: document["title"] as? String ?? "", date: document["date"] as? String ?? "",location: document["location"] as? String ?? "",attendees: document["attendees"] as? Array<String> ?? [],descriptionLink: document["descriptionLink"] as? String ?? "")
                    if event.attendees.contains(Auth.auth().currentUser?.uid ?? "") {
                        return
                    }
                    
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
                    
                    let leadersRef = db.collection("leaders").document(Auth.auth().currentUser?.uid ?? "")
                    
                    // Set the "capital" field of the city 'DC'
                    do {
                        try await leadersRef.updateData([
                            "eventsAttended": FieldValue.increment(Int64(1))
                        ])
                        print("Document successfully updated")
                    } catch {
                        print("Error updating document: \(error)")
                    }
                    
                } else {
                    alertCamera = "Event doesn't exist"
                    print("Document does not exist")
                }
            } catch {
                alertCamera = "Event doesn't exist"
                print("Error getting document: \(error)")
            }
            
        }
    }
    let logo = Image("PassportWeek_Logo")
    var body: some View {
        //Auth.auth().currentUser == nil &&
        if !loggedin {
            Form{
                logo
                    .resizable()
                    .scaledToFit()
                if promptAddress {
                    Section(footer: Text("Enter your mailing address in case you win a gift card.")) {
                        TextField("Full Name", text: $fullName)
                            .font(Font.system(size: 15))
                            .fontWeight(.semibold)
                            .frame(width: nil, height: nil, alignment: .leading)
                            .onChange(of: fullName) {
                                verifiable = false
                            }
                        TextField("Student ID (s0989374)", text: $studentId)
                            .font(Font.system(size: 15))
                            .fontWeight(.semibold)
                            .frame(width: nil, height: nil, alignment: .leading)
                            .onChange(of: studentId) {
                                verifiable = false
                            }
                        TextField("Line 1", text: $addressLine1)
                            .font(Font.system(size: 15))
                            .fontWeight(.semibold)
                            .frame(width: nil, height: nil, alignment: .leading)
                            .onChange(of: addressLine1) {
                                verifiable = false
                            }
                        TextField("Line 2", text: $addressLine2)
                            .font(Font.system(size: 15))
                            .fontWeight(.semibold)
                            .frame(width: nil, height: nil, alignment: .leading)
                            .onChange(of: addressLine2) {
                                verifiable = false
                            }
                        TextField("City", text: $city)
                            .font(Font.system(size: 15))
                            .fontWeight(.semibold)
                            .frame(width: nil, height: nil, alignment: .leading)
                            .onChange(of: city) {
                                verifiable = false
                            }
                        TextField("State", text: $state)
                            .font(Font.system(size: 15))
                            .fontWeight(.semibold)
                            .frame(width: nil, height: nil, alignment: .leading)
                            .onChange(of: state) {
                                verifiable = false
                            }
                        TextField("Zip Code", text: $zipCode)
                            .font(Font.system(size: 15))
                            .fontWeight(.semibold)
                            .frame(width: nil, height: nil, alignment: .leading)
                            .onChange(of: zipCode) {
                                verifiable = false
                            }
                    }
                }
                if !promptAddress {
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
                            TextField("SMS code", text: $smsTextCode)
                                .font(Font.system(size: 15))
                                .fontWeight(.semibold)
                                .frame(width: nil, height: nil, alignment: .leading)
                                .onChange(of: smsTextCode) {
                                    
                                }
                        }
                    }
                }
                Button("Submit", action: {
                    
                    if promptAddress {
                        if fullName == "" {
                            return print("No full name")
                        }
                        if studentId == "" {
                            return print("No student id")
                        }
                        if addressLine1 == "" {
                            return print("No address line 1")
                        }
                        if city == "" {
                            return print("No city")
                        }
                        if state == "" {
                            return print("No state")
                        }
                        if zipCode == "" {
                            return print("No zip code")
                        }
                        if addressLine2 == "" {
                            address = addressLine1 + ", "
                            + city + ", "
                            + state + " " + zipCode
                        }else {
                            address = addressLine1 + ", "
                            + addressLine2 + ", "
                            + city + ", "
                            + state + " " + zipCode
                        }
                        Task {
                            do {
                                try await db.collection("leaders").document(Auth.auth().currentUser?.uid ?? "").setData([
                                    "fullName": fullName,
                                    "studentId": studentId,
                                    "username": "Student",
                                    "eventsAttended": 0,
                                    "phone": phoneNumber,
                                    "address": address
                                ])
                                print("Welcome to Passport!")
                                loggedin = true
                            } catch {
                                print("Error writing document: \(error)")
                            }
                        }
                    }
                    
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
                        if phoneNumber == "" {
                            print("No phone number")
                            return
                        }
                        if countryCodeNumber == "" {
                            return
                        }
                        let _ = PhoneAuthProvider.provider(auth: Auth.auth())
                        let phoneNumber = String(format: "+%@", countryCodeNumber + phoneNumber)
                        PhoneAuthProvider.provider().verifyPhoneNumber( phoneNumber, uiDelegate: nil) { verificationID, error in
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
                        }
                        //verifiable = true
                    } else {
                        let credential = PhoneAuthProvider.provider().credential(
                          withVerificationID: verificationId,
                          verificationCode: smsTextCode
                        )
                        Auth.auth().signIn(with: credential) { authResult, error in
                            if error != nil {
                                print(error?.localizedDescription ?? "")
                                return
                            }
                            guard let authResult = authResult else {
                                print(FirebaseError.VerificatrionEmpty)
                                return
                            }
                            _ = authResult
                            
                            Task {
                                let docRef = db.collection("leaders").document(Auth.auth().currentUser?.uid ?? "")
                                
                                do {
                                    let document = try await docRef.getDocument()
                                    if document.exists {
                                        print("Document already exists")
                                        loggedin = true
                                    } else {
                                        promptAddress = true
                                    }
                                } catch {
                                    print("Error getting document: \(error)")
                                }
                                //loggedin = true
                            }
                        }
                        //loggedin = true
                    }
                    
                    
                })
                /*Section(footer: Text("Sign in with Microsoft.")) {
                    Button(action: signIn) {
                        Text("Sign in with Microsoft")
                    }
                }*/
            }
        }
        if(testing){
            Text(countryCodeNumber + phoneNumber)
        }
        //Auth.auth().currentUser != nil ||
        if loggedin {
            if show == "list"{
                VStack(alignment: .leading) {
                    Text("Load Events")
                        .font(Font.system(size: 15))
                        .fontWeight(.semibold)
                        .frame(width: nil, height: nil, alignment: .leading)
                        .onTapGesture {
                            getEvents()
                        }
                        .padding(10)
                    
                    GeometryReader { geometry in
                        ScrollView {
                            List {
                                ForEach ($rocks.indices, id: \.self){ index in
                                    EventView(title:$rocks[index].title,location:$rocks[index].location,
                                              date:$rocks[index].date,
                                              descriptionLink:$rocks[index].descriptionLink
                                    )
                                    /*.onTapGesture {
                                        openedEvent = rocks[index].id
                                        openEvent(eventId:openedEvent)
                                        show = "home"
                                    }*/
                                }
                            }
                            //.scrollDisabled(true)
                            //.scaledToFit()
                            .frame(width: geometry.size.width,height: geometry.size.height)
                        }
                        //.frame(height: .infinity)
                    }
                }
                //.frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(x: show == "list" ? 0 : -UIScreen.screenWidth)
            }
            if show == "leaderboard"{
                VStack(alignment: .leading) {
                    Form{
                        Section(footer: Text("Your username may appear on the leaderboard.")) {
                            TextField("Username", text: $newUsername)
                                .font(Font.system(size: 15))
                                .fontWeight(.semibold)
                                .frame(width: nil, height: nil, alignment: .leading)
                                .onChange(of: newUsername) {
                                    //verifiable = false
                                }
                            Button("Save", action: {
                                Task {
                                    do {
                                        let querySnapshot = try await db.collection("leaders").whereField("username", isEqualTo: newUsername)
                                          .getDocuments()
                                        for document in querySnapshot.documents {
                                          print("\(document.documentID) => \(document.data())")
                                        }
                                        if querySnapshot.documents.isEmpty {
                                            print("saving username")
                                            let leaderRef = db.collection("leaders").document(Auth.auth().currentUser?.uid ?? "")
                                            
                                            // Set the "username" field of the leader 'newUsername'
                                            do {
                                                try await leaderRef.updateData([
                                                    "username": newUsername
                                                ])
                                                print("Document successfully updated")
                                            } catch {
                                                print("Error updating document: \(error)")
                                            }
                                        } else {
                                            print("username already exists")
                                        }
                                    } catch {
                                    print("Error getting documents: \(error)")
                                    }
                                }
                            })
                        }
                    }
                    Text("Update Leaderboard")
                        .font(Font.system(size: 15))
                        .fontWeight(.semibold)
                        .frame(width: nil, height: nil, alignment: .leading)
                        .onTapGesture {
                            getLeaders()
                        }
                        .padding(10)
                    
                    GeometryReader { geometry in
                        ScrollView {
                            List {
                                ForEach ($leaders.indices, id: \.self){ index in
                                    LeaderView(username:$leaders[index].username,eventsAttended:$leaders[index].eventsAttended
                                    )
                                }
                            }
                            .frame(width: geometry.size.width,
                                   height: geometry.size.height)
                        }
                        //.frame(height: .infinity)
                    }
                }
                //.frame(maxWidth: .infinity, maxHeight: .infinity)
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
                Toggle("Hide camera", isOn: $deniedCamera)
                    .padding(10)
                if deniedCamera {
                    Text(alertCamera)
                        .font(.system(size: 36))
                } else {
                    CodeScannerView(codeTypes: [.qr], simulatedData: "PUCYMbQTTVlmTitXH8nO") { response in
                        switch response {
                        case .success(let result):
                            openEvent(eventId: result.string)
                            attendEvent(eventId: result.string)
                        case .failure(let error):
                            deniedCamera = true
                            alertCamera = error.localizedDescription + ". Try again."
                            print(error.localizedDescription)
                        }
                    }
                }
            }
            Text(show != "home" ? "back" : "logout")
                .font(Font.system(size: 15))
                .fontWeight(.semibold)
                .frame(width: nil, height: nil, alignment: .leading)
                .onTapGesture {
                    
                    if show == "home"{
                        loggedin = false
                        verifiable = false
                        signOut()
                    } else {
                        show = "home"
                    }
                }
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    if newPhase == .active {
                        print("Active")
                        Task {
                            let status = AVCaptureDevice.authorizationStatus(for: .video)
                            
                            // Determine if the user previously authorized camera access.
                            var isAuthorized = status == .denied
                            
                            // If the system hasn't determined the user's authorization status,
                            // explicitly prompt them for approval.
                            if status == .notDetermined {
                                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
                            }
                            //deniedCamera = !isAuthorized
                        }
                    } else if newPhase == .inactive {
                        print("Inactive")
                    } else if newPhase == .background {
                        print("Background")
                        deniedCamera = true
                        alertCamera = "Go to Settings, Passport, and then Allow Passport to Access: Camera"
                    }
                }
        }
    }
}


#Preview {
    ContentView()
}


