import SwiftUI
import CloudKit

struct InviteCodeView: View {
    @State private var inviteCode: String = ""
    @State private var inputCode: String = ""
    @State private var alertMessage: String = ""
    @State private var showAlert = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Your Code")) {
                    if inviteCode.isEmpty {
                        Button("Generate Code") {
                            CloudKitLocationManager.shared.prepareShare { share in
                                if let url = share?.url {
                                    inviteCode = url.absoluteString
                                }
                            }
                        }
                    } else {
                        Text(inviteCode)
                            .textSelection(.enabled)
                        Button("Copy") {
                            UIPasteboard.general.string = inviteCode
                        }
                    }
                }

                Section(header: Text("Enter Code")) {
                    TextField("Paste code", text: $inputCode)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                    Button("Accept") {
                        guard let url = URL(string: inputCode) else { return }
                        CloudKitLocationManager.shared.acceptShare(from: url) { success in
                            alertMessage = success ? "Invite accepted!" : "Failed to accept invite"
                            showAlert = true
                            if success { dismiss() }
                        }
                    }
                }
            }
            .navigationTitle("Invites")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert(alertMessage, isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            }
        }
    }
}

struct InviteCodeView_Previews: PreviewProvider {
    static var previews: some View {
        InviteCodeView()
    }
}
