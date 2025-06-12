import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: UserSession

    var body: some View {
        if session.isSignedIn {
            ContentView(session: session)
                .environmentObject(session)
                .preferredColorScheme(.dark)
        } else {
            SignInView()
                .environmentObject(session)
        }
    }
}

