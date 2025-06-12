import SwiftUI
import CloudKit

struct InviteView: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIViewController(context: Context) -> UICloudSharingController {
        print("InviteView launched")
        let manager = CloudKitLocationManager.shared

        guard let share = manager.share else {
            fatalError("Share should be ready before presenting InviteView")
        }

        let controller = UICloudSharingController(share: share, container: manager.container)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: UICloudSharingController, context: Context) {}

    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        func cloudSharingController(_ c: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("Failed to save share: \(error)")
        }

        func itemTitle(for c: UICloudSharingController) -> String? {
            "Wya Invite"
        }

        func cloudSharingControllerDidSaveShare(_ c: UICloudSharingController) {
            print("Share saved")
        }

        func cloudSharingControllerDidStopSharing(_ c: UICloudSharingController) {
            print("Stopped sharing")
        }
    }
}
