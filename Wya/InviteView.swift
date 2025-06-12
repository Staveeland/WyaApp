import SwiftUI
import MultipeerConnectivity

struct InviteView: UIViewControllerRepresentable {
    @EnvironmentObject var viewModel: WyaViewModel

    func makeUIViewController(context: Context) -> MCBrowserViewController {
        viewModel.multipeerSession.browserViewController()
    }

    func updateUIViewController(_ uiViewController: MCBrowserViewController, context: Context) {}
}
