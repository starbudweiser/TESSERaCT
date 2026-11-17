import Foundation
import GuestAgentMac

// tctl-agent: the TESSERaCT guest agent for macOS guests. It runs inside a virtual machine, not on the
// Mac that runs TESSERaCT, and is put there by the guest tools installer.

exit(AgentCommand.run(Array(CommandLine.arguments.dropFirst())))
