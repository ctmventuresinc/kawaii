import SwiftUI
import AVKit
import AVFoundation

struct BubuOnboardingView: View {
    @State private var inviteCode: String = ""
    @State private var navigate: Bool = false
    @State private var player: AVPlayer?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 20/255, green: 20/255, blue: 26/255) // dark background
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    // Video panel replacing logo
                    if let player = player {
                        VideoPlayerView(player: player)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 220, height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 60))
                            .allowsHitTesting(false)
                            .onAppear {
                                player.play()
                            }
                    } else {
                        ProgressView("Loading…")
                            .frame(width: 220, height: 160)
                    }

                    // Tagline
                    Text("badbubu")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(Color.gray.opacity(0.7))
                        .padding(.top, 8)

                    // Invite input + button
                    VStack(spacing: 16) {
                        TextField("Please enter the invite code", text: $inviteCode)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.gray.opacity(0.25))
                            .cornerRadius(8)
                            .disableAutocorrection(true)
                            .textInputAutocapitalization(.never)

                        Button(action: {
                            navigate = true
                        }) {
                            Text("let's go")
                                .font(.system(size: 22, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(inviteCode.isEmpty ? Color.gray.opacity(0.4) : Color.white)
                                .foregroundColor(inviteCode.isEmpty ? Color.white.opacity(0.8) : Color.black)
                                .cornerRadius(8)
                        }
                        .disabled(inviteCode.isEmpty)
                    }
                    .padding(.horizontal, 24)

                    // Terms text
                    Text("By continuing, you agree to our Terms of Use and Privacy Policy")
                        .font(.footnote)
                        .foregroundColor(Color.gray.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    // Discord link
                    Link("join our discord server for the code", destination: URL(string: "https://discord.gg")!)
                        .font(.footnote.bold())
                        .foregroundColor(Color.yellow)

                    Spacer()

                    // Login link button
                    Button(action: {
                        // TODO: handle login flow
                    }) {
                        Text("already have an account? log in here")
                            .font(.footnote)
                            .foregroundColor(Color.gray)
                    }
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
}

private struct LogoPanel: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 60)
                .fill(Color.black)
                .frame(width: 220, height: 160)
                .overlay(
                    RoundedRectangle(cornerRadius: 60)
                        .stroke(Color.black, lineWidth: 2)
                )

            HStack(spacing: 0) {
                Text("status")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Circle()
                    .fill(Color.blue)
                    .frame(width: 14, height: 14)
                    .offset(x: -8, y: -20)
            }
        }
    }
}

#Preview {
    BubuOnboardingView()
}
