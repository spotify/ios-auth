import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var showAlert = false

    var body: some View {
        VStack(spacing: 20) {
            Text("Connect your Spotify account")
            connectButton
        }
        .padding()
        .onOpenURL { url in
            viewModel.open(url: url)
        }
        .onChange(of: viewModel.state) { _, newState in
            showAlert = newState != .idle
        }
        .alert(
            viewModel.alertTitle,
            isPresented: $showAlert,
            actions: {
                Button(viewModel.alertButtonTitle, role: .cancel) {
                    viewModel.setStateIdle()
                }
            }
        )
    }

    private var connectButton: some View {
        Button(action: {
            viewModel.startAuthorizationCodeProcess()
        }) {
            Text("CONNECT")
                .font(.headline)
                .kerning(2.0)
                .foregroundColor(.white)
                .padding(.horizontal, 32)
                .padding(.vertical, 12)
                .background(Color.spotifyGreen)
                .cornerRadius(20)
        }
    }
}

private extension Color {
    static let spotifyGreen = Color(red: 29/255, green: 185/255, blue: 84/255)
}

private extension ContentViewModel {
    var alertTitle: String {
        switch state {
        case .idle:
            return ""
        case .failure(let errorMessage):
            return errorMessage
        case .success(let successMessage):
            return successMessage
        }
    }

    var alertButtonTitle: String {
        switch state {
        case .idle:
            return ""
        case .failure:
            return "Bummer"
        case .success:
            return "Nice"
        }
    }
}

#Preview {
    ContentView()
}
