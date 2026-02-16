import SwiftUI
import FirebaseAuth

extension ContentView {
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                withAnimation(.spring()) {
                    rocks = []
                    leaders = []
                    showEventDetail = false
                    selectedEvent = nil
                    eventTitle = "Scholarship week"
                    eventBody = ""
                    fullName = ""
                    username = ""
                    addressLine1 = ""
                    addressLine2 = ""
                    city = ""
                    state = ""
                    zipCode = ""
                    address = ""
                    testing = false
                    underlayMode = .home
                    loggedin = false
                    defaults.removeObject(forKey: "Address")
                    defaults.removeObject(forKey: "FullName")
                }
            }
        } catch {
            print(error)
            authErrorMessage = error.localizedDescription
            showAuthErrorAlert = true
        }
    }

    func signIn(prompt: String? = nil) {
        isSigningIn = true
        authDebug = "starting"
        let provider = OAuthProvider(providerID: "microsoft.com")
        microsoftProvider = provider
        if let prompt = prompt {
            provider.customParameters = ["tenant": "organizations", "prompt": prompt]
        } else {
            provider.customParameters = ["tenant": "organizations"]
        }

        guard let viewController = UIApplication.topViewController() else {
            isSigningIn = false
            microsoftProvider = nil
            authUIDelegate = nil
            authDebug = "no presenter"
            authErrorMessage = "Could not present the sign-in screen. Please try again."
            showAuthErrorAlert = true
            return
        }

        let uiDelegate = AuthUIPresenter(presentingViewController: viewController)
        authUIDelegate = uiDelegate
        authDebug = "presenting web auth"
        provider.getCredentialWith(uiDelegate) { credential, error in
            DispatchQueue.main.async {
                isSigningIn = false
                microsoftProvider = nil
                authUIDelegate = nil
                authDebug = "callback received"
            }
            if let error = error {
                print("Microsoft Sign-In Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    authErrorMessage = error.localizedDescription
                    showAuthErrorAlert = true
                }
                return
            }

            if let credential = credential {
                DispatchQueue.main.async {
                    authDebug = "signing into Firebase"
                }
                Auth.auth().signIn(with: credential) { _, error in
                    if let error = error {
                        print("Firebase Auth Error: \(error.localizedDescription)")
                        DispatchQueue.main.async {
                            authErrorMessage = error.localizedDescription
                            showAuthErrorAlert = true
                        }
                    }
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            if isSigningIn {
                isSigningIn = false
                microsoftProvider = nil
                authUIDelegate = nil
                authDebug = "timeout before web auth"
                authErrorMessage = "Sign-in did not start. Please try again."
                showAuthErrorAlert = true
            }
        }
    }
}
