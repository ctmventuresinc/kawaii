import SwiftUI

struct BubuOnboardingView: View {
    @State private var inviteCode: String = ""
    @State private var navigate: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 20/255, green: 20/255, blue: 26/255) // dark background
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer(minLength: 40)

                    // Logo panel
                    LogoPanel()

                    // Tagline
                    Text("sims for social media")
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
