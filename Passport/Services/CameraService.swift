import SwiftUI
import AVFoundation

extension ContentView {
    func handleScenePhaseChange(_ newPhase: ScenePhase) {
        if newPhase == .active {
            print("Active")
            if underlayMode == .home {
                checkCameraPermissions()
            }
            verticalDragOffset = 0
            horizontalDragOffset = 0
            isGestureStarted = false
            isPullAllowed = false
        } else if newPhase == .inactive {
            print("Inactive")
        } else if newPhase == .background {
            print("Background")
        }
    }

    func checkCameraPermissions() {
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)

            if !cameraEnabled {
                await MainActor.run {
                    deniedCamera = true
                    showDisabledAlert = true
                }
                return
            }

            #if targetEnvironment(simulator)
                await MainActor.run {
                    showSimulatorAlert = true
                }
            #else
                let status = AVCaptureDevice.authorizationStatus(for: .video)
                if status == .authorized {
                    await MainActor.run {
                        withAnimation(.spring()) {
                            deniedCamera = false
                        }
                    }
                } else if status == .notDetermined {
                    let granted = await AVCaptureDevice.requestAccess(for: .video)
                    await MainActor.run {
                        withAnimation(.spring()) {
                            deniedCamera = !granted
                            if !granted {
                                showPermissionAlert = true
                            }
                        }
                    }
                } else {
                    await MainActor.run {
                        withAnimation(.spring()) {
                            deniedCamera = true
                            showPermissionAlert = true
                        }
                    }
                }
            #endif
        }
    }

    func updateScanHint(_ message: String) {
        scanHint = message
        scanHintWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            scanHint = nil
        }
        scanHintWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: workItem)
    }
}
