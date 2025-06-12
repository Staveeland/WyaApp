import Foundation
import AuthenticationServices
import CloudKit

final class UserSession: NSObject, ObservableObject {
    @Published var isSignedIn: Bool
    @Published var userName: String?
    private let defaults = UserDefaults.standard
    static let shared = UserSession()

    var userID: String? {
        defaults.string(forKey: "appleUserID")
    }

    override init() {
        self.isSignedIn = defaults.string(forKey: "appleUserID") != nil
        self.userName = defaults.string(forKey: "appleUserName")
        super.init()
    }

    func startSignInWithAppleFlow(request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    func handleAuthorization(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else { return }
            let userID = credential.user
            let name = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            defaults.set(userID, forKey: "appleUserID")
            defaults.set(name, forKey: "appleUserName")
            self.userName = name
            self.isSignedIn = true
            CloudKitUserDataManager.shared.save(userID: userID, name: name, people: [], alerts: [])
        case .failure(let error):
            print("Authorization failed: \(error)")
        }
    }

    func signOut() {
        defaults.removeObject(forKey: "appleUserID")
        defaults.removeObject(forKey: "appleUserName")
        isSignedIn = false
        userName = nil
    }
}
