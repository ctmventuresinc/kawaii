import SwiftUI
import AVKit
import AVFoundation
import FirebaseRemoteConfig

struct BubuOnboardingView: View {
    @State private var inviteCode: String = ""
    @State private var navigate: Bool = false
    @State private var player: AVPlayer?
    @State private var showWrongCode = false

    @ObservedObject private var rcStore = RemoteConfigStore.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 20/255, green: 20/255, blue: 26/255) // dark background
                    .ignoresSafeArea()

                // Video layer similar to Kawaii onboarding
                // background remains solid; video will be in VStack below

                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    // Video panel
                    if let player = player {
                        VideoPlayerView(player: player)
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .frame(height: UIScreen.main.bounds.height * 0.35)
                            .clipShape(RoundedRectangle(cornerRadius: 40))
                            .allowsHitTesting(false)
                            .onAppear { player.play() }
                    } else {
                        ProgressView("Loading…")
                            .frame(height: UIScreen.main.bounds.height * 0.35)
                    }

                    // Invite input + button
                    VStack(spacing: 16) {
                        ZStack(alignment: .leading) {
                            if inviteCode.isEmpty {
                                Text("please enter the invite code")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Color.white.opacity(0.6))
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }

                            TextField("", text: $inviteCode)
                                .padding()
                                .foregroundColor(.white)
                                .background(Color.gray.opacity(0.25))
                                .cornerRadius(8)
                                .disableAutocorrection(true)
                                .textInputAutocapitalization(.never)
                        }

                        Button(action: {
                            if rcStore.inviteCodes.contains(inviteCode) {
                                showWrongCode = false
                                navigate = true
                            } else {
                                showWrongCode = true
                            }
                        }) {
                            Text("let's go")
                                .font(.system(size: 22, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(inviteCode.isEmpty ? Color.gray.opacity(0.4) : Color.white)
                                .foregroundColor(inviteCode.isEmpty ? Color.white.opacity(0.8) : Color.black)
                                .cornerRadius(8)
                        }
                        .disabled(inviteCode.isEmpty || !rcStore.isLoaded)

                        if showWrongCode {
                            Text("Wrong code")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal, 24)

                    // Terms text link (blue)
                    Link("By continuing, you agree to our Terms of Use and Privacy Policy", destination: URL(string: "https://www.notion.so/Legal-250f451e369c8090988cf0b241803e7f?source=copy_link")!)
                        .font(.footnote)
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    // Discord link bigger, underlined
                    Link(destination: URL(string: "https://discord.gg/AEvEcDXd")!) {
                        Text("join our discord server for the code")
                            .font(.title3)
                            .underline()
                            .foregroundColor(Color.yellow)
                    }

                    Spacer()

                    // Bottom link
                    Link("dangertesting.com", destination: URL(string: "https://dangertesting.com")!)
                        .font(.footnote)
                        .foregroundColor(Color.gray)
                        .padding(.bottom, 24)
                }
            }
            .navigationDestination(isPresented: $navigate) {
                bubuview()
                    .navigationBarBackButtonHidden()
            }
        }
        .onAppear {
            setupPlayer()
            if !rcStore.isLoaded { rcStore.refresh() }
        }
    }

    private func setupPlayer() {
        guard let videoURL = Bundle.main.url(forResource: "los_facetime", withExtension: "mp4") else {
            print("Could not find los_facetime.mp4 in bundle")
            return
        }

        player = AVPlayer(url: videoURL)

        // Configure for auto-play audio category
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session: \(error)")
        }

        // Loop video
        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem, queue: .main) { _ in
            player?.seek(to: .zero)
            player?.play()
        }
    }

    // removed fetchInviteCodes (handled globally)
}

#Preview {
    BubuOnboardingView()
}
