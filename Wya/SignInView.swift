import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var session: UserSession

    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            Text("Welcome to Wya")
                .font(.largeTitle)
            SignInWithAppleButton { request in
                session.startSignInWithAppleFlow(request: request)
            } onCompletion: { result in
                session.handleAuthorization(result: result)
            }
            .signInWithAppleButtonStyle(.whiteOutline)
            .frame(height: 50)
            Spacer()
        }
        .padding()
    }
}
