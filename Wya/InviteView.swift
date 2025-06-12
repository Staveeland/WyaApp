import SwiftUI
import CloudKit

struct InviteView: UIViewControllerRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let manager = CloudKitLocationManager.shared
        if let share = manager.share {
            let controller = UICloudSharingController(share: share, container: manager.container)
            controller.delegate = context.coordinator
            return controller
        } else {
            let controller = UICloudSharingController { _, preparationCompletion in
                manager.createShare { share, error in
                    DispatchQueue.main.async {
                        preparationCompletion(share, manager.container, error)
                    }
                }
            }
            controller.delegate = context.coordinator
            return controller
        }
    }

    func updateUIViewController(_ controller: UICloudSharingController, context: Context) {}

    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        func cloudSharingController(_ c: UICloudSharingController, failedToSaveShareWithError error: Error) {}
        func itemTitle(for c: UICloudSharingController) -> String? { "Wya Invite" }
        func cloudSharingControllerDidSaveShare(_ c: UICloudSharingController) {}
        func cloudSharingControllerDidStopSharing(_ c: UICloudSharingController) {}
    }
}
