import Testing
import VMCore
import VMNetworking
@testable import VZEngine

@MainActor
@Suite struct BridgedAttachmentTests {
    @Test func anUnavailableBridgeFailsInsteadOfLookingForTheNATNetwork() throws {
        let interface = NetworkInterfaceConfiguration(bridgedInterfaceIdentifier: "tctl-missing-interface")
        #expect(throws: BridgedNetworking.Failure.self) {
            try VZBackendProvider.attachment(for: interface, sharedNetwork: nil)
        }
    }
}
