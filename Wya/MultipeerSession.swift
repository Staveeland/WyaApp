import Foundation
import MultipeerConnectivity
import CoreLocation

class MultipeerSession: NSObject, ObservableObject {
    private let serviceType = "wya-location"
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser

    @Published var connectedPeers: [MCPeerID] = []
    var receivedLocation: ((MCPeerID, CLLocationCoordinate2D) -> Void)?

    override init() {
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        super.init()
        session.delegate = self
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
    }

    func browserViewController() -> MCBrowserViewController {
        let browser = MCBrowserViewController(serviceType: serviceType, session: session)
        browser.delegate = self
        return browser
    }

    func send(location: CLLocationCoordinate2D) {
        guard !session.connectedPeers.isEmpty else { return }
        let dict = ["lat": location.latitude, "lon": location.longitude]
        if let data = try? JSONSerialization.data(withJSONObject: dict, options: []) {
            try? session.send(data, toPeers: session.connectedPeers, with: .reliable)
        }
    }
}

extension MultipeerSession: MCSessionDelegate, MCBrowserViewControllerDelegate, MCNearbyServiceAdvertiserDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            self?.connectedPeers = session.connectedPeers
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Double],
           let lat = dict["lat"], let lon = dict["lon"] {
            let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            DispatchQueue.main.async { [weak self] in
                self?.receivedLocation?(peerID, coord)
            }
        }
    }

    // unused delegate methods
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {}

    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true)
    }

    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true)
    }
}
