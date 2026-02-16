//
//  ContentView.swift
//  Passport
//
//  Created by Nicholas Carducci on 9/7/24.
//
import Foundation
//import PromiseKit
import SwiftUI
import AVFoundation
import Firebase
import FirebaseAuth

let db = Firestore.firestore()
//import FirebaseMessaging
struct ContentView: View {
    //@AppStorage("username") var username: String = ""

    @Environment(\.scenePhase) var scenePhase
    @StateObject private var gestureState = GestureStateManager()

    @State var alertCamera = "Go to Settings, Passport, and then Allow Passport to Access: Camera"
    @State var address = ""
    @State var fullName = ""
    @State var username = ""
    @State var addressLine1 = ""
    @State var addressLine2 = ""
    @State var city = ""
    @State var state = ""
    @State var zipCode = ""
    #if targetEnvironment(simulator)
        @State var deniedCamera = true
    #else
        @State var deniedCamera = false
    #endif
    @State var loggedin = true
    @State var testing = false
    //@State var session: User = User(coder: NSCoder())!
    @State var showSimulatorAlert = false
    @State var showPermissionAlert = false
    @State var showScannerErrorAlert = false
    @State var showDisabledAlert = false
    @State var showLogoutConfirm = false
    @State var authListenerHandle: AuthStateDidChangeListenerHandle?
    @State var verticalDragOffset: CGFloat = 0
    @State var horizontalDragOffset: CGFloat = 0
    @State var isGestureStarted = false
    @State var isPullAllowed = false
    @State var scanHint: String? = nil
    @State var scanHintWorkItem: DispatchWorkItem?
    #if targetEnvironment(simulator)
    @State var cameraEnabled = false
    #else
    @State var cameraEnabled = true
    #endif
    @State var isAtTop = false
    @State var showAuthErrorAlert = false
    @State var authErrorMessage = "Sign-in failed. Please try again."
    @State var isSigningIn = false
    @State var microsoftProvider: OAuthProvider?
    @State var authUIDelegate: AuthUIPresenter?
    @State var authDebug = "idle"

    @State var rocks = [Event]()
    @State var leaders = [Leader]()
    @State var underlayMode: UnderlayMode = .home
    @State public var eventTitle: String = "Scholarship week"
    @State public var eventBody: String = ""
    @State var showEventDetail = false
    @State var selectedEvent: Event?

    init() {
        #if DEBUG
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                if FirebaseApp.app() == nil {
                    FirebaseApp.configure()
                }
            }
        #endif
    }

    let logo = Image("PassportWeek_Logo")
    let defaults = UserDefaults.standard
    var body: some View {
        ZStack(alignment: .bottom) {
            if loggedin {
                // Focal Architecture: Views are layered and moved via offsets
                profileView
                    .offset(x: profileOffsetX())
                    .zIndex(1)

                listView
                    .offset(x: listOffsetX(), y: listOffsetY())
                    .zIndex(2)

                homeView
                    .offset(y: homeOffsetY())
                    .zIndex(1)

                leaderboardView
                    .background(Color(uiColor: .systemBackground))
                    .offset(x: leaderboardOffsetX())
                    .zIndex(1)

            } else {
                loginView
                    .zIndex(4)
            }

            // Bottom fade: transparent to opaque white as it approaches the edge
            GeometryReader { proxy in
                let fadeHeight = 180 + proxy.safeAreaInsets.bottom
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.white.opacity(0.0), location: 0.0),
                        .init(color: Color.white.opacity(0.5), location: 0.6),
                        .init(color: Color.white.opacity(0.85), location: 1.0),
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: fadeHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .zIndex(3)

            GeometryReader { proxy in
                let fadeHeight = 180 + proxy.safeAreaInsets.bottom
                let tapHeight = max(0, fadeHeight - proxy.safeAreaInsets.bottom)
                QuietButton(action: {
                    withAnimation(.spring()) {
                        if underlayMode != .list {
                            underlayMode = .list
                        } else {
                            underlayMode = .home
                        }
                    }
                }) {
                    VStack(spacing: 8) {
                        Spacer()
                        if underlayMode != .home {
                            Text(underlayMode == .list ? "scan" : "back")
                                .font(Font.system(size: 15))
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                                .padding(.bottom, max(12, proxy.safeAreaInsets.bottom + 8))
                        }
                    }
                    .frame(height: tapHeight)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 0)
            }
            .zIndex(3)

        }
        .ignoresSafeArea()
        .environmentObject(gestureState)
        .onOpenURL { url in
            _ = Auth.auth().canHandle(url)
        }
        .onAppear {
            self.authListenerHandle = Auth.auth().addStateDidChangeListener { _, user in
                withAnimation {
                    loggedin = (user != nil)
                }
            }
        }
        .onDisappear {
            if let handle = self.authListenerHandle {
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    let hDrag = value.translation.width
                    let vDrag = value.translation.height

                    // LATCH LOGIC: Wait for meaningful movement before locking direction
                    if !isGestureStarted {
                        if abs(hDrag) > 5 || abs(vDrag) > 5 {
                            isGestureStarted = true
                            gestureState.startDrag()
                            let isVertical = abs(vDrag) > abs(hDrag)
                            let isDraggingDown = vDrag > 0 && isVertical
                            let isDraggingUp = vDrag < 0 && isVertical

                            // Allow vertical pulls only from list-top upward to bottom row, or from home downward
                            isPullAllowed =
                                (underlayMode == .list && isAtTop && isDraggingUp)
                                || (underlayMode == .home && isDraggingDown)
                        } else {
                            return
                        }
                    }

                    // If vertical becomes dominant after latch, re-evaluate pull allowance.
                    if abs(vDrag) > abs(hDrag) {
                        if underlayMode == .list && isAtTop && vDrag < 0 {
                            isPullAllowed = true
                        } else if underlayMode == .home && vDrag > 0 {
                            isPullAllowed = true
                        }
                    }

                    if abs(vDrag) > abs(hDrag) {
                        // Vertical Pull: List <-> Home
                        if isPullAllowed {
                            verticalDragOffset = vDrag
                        }
                    } else {
                        // Horizontal Swipe: Profile <-> List <-> Leaderboard
                        if underlayMode == .list {
                            horizontalDragOffset = hDrag
                        } else if underlayMode == .profile && hDrag < 0 {
                            horizontalDragOffset = hDrag
                        } else if underlayMode == .leaderboard && hDrag > 0 {
                            horizontalDragOffset = hDrag
                        }
                    }
                }
                .onEnded { value in
                    let hDrag = value.translation.width
                    let vDrag = value.translation.height
                    var didTriggerNavigation = false

                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        if abs(hDrag) > abs(vDrag) * 2.0 {
                            switch underlayMode {
                            case .list:
                                if hDrag > 80 {
                                    underlayMode = .profile
                                    didTriggerNavigation = true
                                } else if hDrag < -80 {
                                    underlayMode = .leaderboard
                                    didTriggerNavigation = true
                                }
                            case .profile:
                                if hDrag < -80 {
                                    underlayMode = .list
                                    didTriggerNavigation = true
                                }
                            case .leaderboard:
                                if hDrag > 80 {
                                    underlayMode = .list
                                    didTriggerNavigation = true
                                }
                            case .home:
                                break
                            }
                        } else if isPullAllowed {
                            if underlayMode == .list && vDrag < -120 {
                                underlayMode = .home
                                didTriggerNavigation = true
                            } else if underlayMode == .home && vDrag > 120 {
                                underlayMode = .list
                                didTriggerNavigation = true
                            }
                        }
                        verticalDragOffset = 0
                        horizontalDragOffset = 0
                        isGestureStarted = false
                        isPullAllowed = false
                    }
                    gestureState.endDrag(didTriggerNavigation: didTriggerNavigation)
                }
        )
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(newPhase)
        }
        .onChange(of: underlayMode) { _, newMode in
            // Reset edge state on mode change to prevent stale trackers.
            isAtTop = false
            if newMode == .home {
                checkCameraPermissions()
            }
        }
        .onChange(of: loggedin) { _, isLoggedIn in
            if isLoggedIn && underlayMode == .home {
                checkCameraPermissions()
            }
            if isLoggedIn {
                getEvents()
                getLeaders()
            }
        }
        .alert("Sign-In Error", isPresented: $showAuthErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(authErrorMessage)
        }
    }

}

#Preview {
    ContentView()
}
