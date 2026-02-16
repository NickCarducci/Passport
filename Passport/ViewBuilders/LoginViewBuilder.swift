import SwiftUI

extension ContentView {
    @ViewBuilder
    var loginView: some View {
        VStack(spacing: 20) {
            logo
                .resizable()
                .scaledToFit()
                .frame(width: 200)
                .padding(.bottom, 50)

            Text("Monmouth University Passport")
                .font(.title2)
                .fontWeight(.bold)

            QuietButton(action: { signIn() }) {
                HStack {
                    Image(systemName: "envelope.fill")
                    Text(isSigningIn ? "Opening Microsoft..." : "Sign in with Microsoft")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .disabled(isSigningIn)

            QuietButton(action: { signIn(prompt: "select_account") }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Switch Account")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .secondarySystemBackground))
                .foregroundColor(.blue)
                .cornerRadius(10)
            }
            .padding(.horizontal, 40)
            .disabled(isSigningIn)

            Text("Auth: \(authDebug)")
                .font(.caption2)
                .foregroundColor(.secondary)

            Text("Please use your student email to sign in.")
                .font(.caption)
                .foregroundColor(.secondary)

            QuietButton(action: {
                withAnimation {
                    testing = true
                    loggedin = true
                }
            }) {
                Text("Preview (TDD)")
            }
            .padding(.top, 20)
            .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}
