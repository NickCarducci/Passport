import SwiftUI
import Firebase
import FirebaseAuth

extension ContentView {
    @ViewBuilder
    var profileView: some View {
        ZStack {
            VStack(alignment: .leading) {
                Text("Profile").font(.title).bold().padding()
                Form {
                    Section(footer: Text("Your username is shown on the leaderboard.")) {
                        TextField("Username", text: $username)
                            .font(Font.system(size: 15))
                            .fontWeight(.semibold)
                    }
                    Section(footer: Text("Enter your mailing address in case you win a gift card."))
                    {
                        TextField(
                            "Full Name \(defaults.object(forKey: "FullName") as? String ?? "Jane Doe")",
                            text: $fullName
                        )
                        .font(Font.system(size: 15))
                        .fontWeight(.semibold)
                        HStack {
                            Text("Student ID")
                            Spacer()
                            Text(
                                Auth.auth().currentUser?.email?.components(separatedBy: "@").first
                                    ?? "Not Signed In"
                            )
                            .foregroundColor(.secondary)
                        }
                        TextField("Line 1", text: $addressLine1)
                            .font(Font.system(size: 15))
                            .fontWeight(.semibold)
                        TextField("Line 2", text: $addressLine2)
                            .font(Font.system(size: 15))
                            .fontWeight(.semibold)
                        TextField("City", text: $city)
                            .font(Font.system(size: 15))
                            .fontWeight(.semibold)
                        TextField("State", text: $state)
                            .font(Font.system(size: 15))
                            .fontWeight(.semibold)
                        TextField("Zip Code", text: $zipCode)
                            .font(Font.system(size: 15))
                            .fontWeight(.semibold)
                    }
                    Section {
                        QuietButton(action: {
                            if addressLine2 == "" {
                                address = "\(addressLine1), \(city), \(state) \(zipCode)"
                            } else {
                                address =
                                    "\(addressLine1), \(addressLine2), \(city), \(state) \(zipCode)"
                            }
                            defaults.set(address, forKey: "Address")
                            defaults.set(fullName, forKey: "FullName")
                            let slug =
                                Auth.auth().currentUser?.email?.components(separatedBy: "@").first
                                ?? ""
                            if !slug.isEmpty {
                                db.collection("leaders").document(slug).setData(
                                    ["username": username], merge: true)
                            }
                        }) {
                            Text("Save")
                        }
                    }
                    Section {
                        #if targetEnvironment(simulator)
                            Toggle("Enable Camera", isOn: .constant(false))
                                .disabled(true)
                        #else
                            Toggle("Enable Camera", isOn: $cameraEnabled)
                        #endif
                        QuietButton(action: {
                            showLogoutConfirm = true
                        }) {
                            Text("Logout")
                                .foregroundColor(.red)
                        }
                    }
                    Section {
                        Color.clear.frame(height: 40)
                    }
                }
            }

            if testing {
                QuietButton(action: { signOut() }) {
                    Color(red: 0.0, green: 0.27, blue: 0.51).opacity(0.28)
                        .overlay(
                            VStack(spacing: 8) {
                                Text("Scholarship Week")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                Text("at Monmouth University")
                                    .font(.subheadline)
                                Text("Exit Preview Mode")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .ignoresSafeArea(.container, edges: [.top, .bottom])
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(Color(uiColor: .systemBackground))
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 50)
        }
        .confirmationDialog(
            "Log out of Passport?",
            isPresented: $showLogoutConfirm,
            titleVisibility: .visible
        ) {
            Button("Log Out", role: .destructive) {
                signOut()
            }
            Button("Cancel", role: .cancel) {}
        }
        .padding(.bottom, 10)
        .onAppear { loadUsername() }
    }
}
