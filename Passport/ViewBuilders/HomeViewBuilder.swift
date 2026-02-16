import SwiftUI
import FirebaseAuth

extension ContentView {
    @ViewBuilder
    var homeView: some View {
        ZStack {
            if underlayMode == .home && cameraEnabled && !deniedCamera {
                CameraScannerView(
                    isActive: underlayMode == .home && cameraEnabled && !deniedCamera,
                    onScan: { rawValue in
                        let eventId = extractEventId(from: rawValue)
                        let savedAddress = defaults.object(forKey: "Address") as? String ?? ""
                        let savedFullName = defaults.object(forKey: "FullName") as? String ?? ""
                        if Auth.auth().currentUser != nil {
                            attendEvent(eventId: eventId, address: savedAddress, fullName: savedFullName)
                        }
                    },
                    onHint: { message in
                        updateScanHint(message)
                    },
                    onError: { message in
                        withAnimation(.spring()) {
                            deniedCamera = true
                            alertCamera = message
                            showScannerErrorAlert = true
                        }
                    }
                )
            } else {
                Color(uiColor: .systemBackground).edgesIgnoringSafeArea(.all)
            }

            VStack {
                Spacer()

                if !eventBody.isEmpty {
                    Text(eventBody)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.6))
                        )
                        .foregroundColor(.white)
                        .padding(.bottom, 40)
                }

                if underlayMode == .home && cameraEnabled && !deniedCamera {
                    Text(scanHint ?? "Point at a Passport event QR code")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black.opacity(0.6))
                        )
                        .foregroundColor(.white)
                        .padding(.bottom, 20)
                    Text("Screen scans off")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 8)
                }
            }
        }
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 50)
        }
        .overlay(alignment: .top) {
            headerView
                .padding()
        }
        .alert("Simulator Mode", isPresented: $showSimulatorAlert) {
            Button("OK") {
                withAnimation(.spring()) {
                    underlayMode = .list
                }
            }
        } message: {
            Text("Camera is not available on the simulator. Redirecting to event list.")
        }
        .alert("Enable Camera Access?", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Back to List", role: .cancel) {
                withAnimation(.spring()) {
                    underlayMode = .list
                }
            }
        } message: {
            Text("Camera access is required to scan QR codes.")
        }
        .alert("Scanner Error", isPresented: $showScannerErrorAlert) {
            Button("OK") {
                withAnimation(.spring()) {
                    underlayMode = .list
                }
            }
        } message: {
            Text(alertCamera)
        }
        .alert("Scanner Disabled", isPresented: $showDisabledAlert) {
            Button("Go to Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Back to List", role: .cancel) {
                withAnimation(.spring()) {
                    underlayMode = .list
                }
            }
        } message: {
            Text("You've previously disabled the camera from viewing QR codes.")
        }
    }
}
