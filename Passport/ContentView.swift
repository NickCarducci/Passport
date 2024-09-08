//
//  ContentView.swift
//  Passport
//
//  Created by Nicholas Carducci on 9/7/24.
//
import Foundation
import PromiseKit
import SwiftUI
import FirebaseCore
import FirebaseAuth
//import FirebaseMessaging

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
    
    init() {
        // Use Firebase library to configure APIs
        FirebaseApp.configure()
        
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
    
    var body: some View {
        if Auth.auth().currentUser == nil {
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
                        let _ = PhoneAuthProvider.provider(auth: Auth.auth())
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
                        }
                        /*firstly {
                            signUp(phoneNumber: countryCodeNumber + phoneNumber)
                        }.done(on: DispatchQueue.main) { id in
                            verificationId = id
                        }.catch { (error) in
                            print(error.localizedDescription)
                        }*/
                    } else {
                        let credential = PhoneAuthProvider.provider().credential(
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
                        }
                    }
                    
                    
                })
            }
        }
        if(testing){
            Text(countryCodeNumber + phoneNumber)
        }
        if Auth.auth().currentUser != nil {
            Text("logout")
                .font(Font.system(size: 15))
                .fontWeight(.semibold)
                .frame(width: nil, height: nil, alignment: .leading)
                .onTapGesture {
                    signOut()
                }
        }
    }
}


#Preview {
    ContentView()
}


