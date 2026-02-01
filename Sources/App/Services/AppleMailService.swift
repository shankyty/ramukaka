import Foundation
import ScriptingBridge

// MARK: - ScriptingBridge Protocols
// Defining minimal protocols to interface with Apple Mail via ScriptingBridge.

@objc protocol MailApplication {
    @objc optional var inbox: MailMailbox { get }
}

@objc protocol MailMailbox {
    @objc optional func messages() -> SBElementArray
}

@objc protocol MailMessage {
    @objc optional var id: Int { get }
    @objc optional var sender: String { get }
    @objc optional var subject: String { get }
    @objc optional var content: String { get }
    @objc optional var dateReceived: Date { get }
    @objc optional var readStatus: Bool { get }
}

// Extend SBApplication to conform to our protocol for casting.
extension SBApplication: MailApplication {}

// MARK: - Service Implementation

class AppleMailService: MailService {

    func fetchUnreadEmails(limit: Int) async throws -> [Email] {
        // SB operations should technically be on the main thread or a dedicated thread,
        // but here we wrap in a Task to adhere to async protocol.
        // Warning: ScriptingBridge is not thread-safe. In a real app, ensure this runs on MainActor or specific queue.
        return try await MainActor.run {
            guard let mailApp = SBApplication(bundleIdentifier: "com.apple.mail") else {
                throw NSError(domain: "AppleMailService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not access Mail app"])
            }

            // Check if running
            if !mailApp.isRunning {
                // In a real app, we might decide whether to launch it.
                // For now, fail if not running to avoid unexpected launch.
                // throw NSError(domain: "AppleMailService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Mail app is not running"])
            }

            guard let inbox = mailApp.inbox,
                  let sbMessages = inbox.messages?() else {
                return []
            }

            // Efficiently filtering in SB requires NSPredicate usually,
            // but SBElementArray filtering with predicates can be tricky in Swift without dynamic dispatch.
            // We will fetch object by object for this v1 (slow but functional for small inbox).
            // A better approach would be: sbMessages.filtered(using: predicate)

            var emails: [Email] = []
            let count = sbMessages.count

            // Iterate backwards to get newest first
            // PERFORMANCE NOTE: We limit the scan to the last 500 messages to prevent locking up the UI
            // since iterating SBElementArray is slow. A better approach for "Read All" would be
            // to use a dedicated background process or NSPredicate filtering if robustly supported.
            let scanLimit = 500
            for i in 0..<min(count, scanLimit) {
                guard let msg = sbMessages.object(at: count - 1 - i) as? MailMessage else { continue }

                if let isRead = msg.readStatus, isRead == false {
                    if let sender = msg.sender,
                       let subject = msg.subject,
                       let body = msg.content,
                       let date = msg.dateReceived {

                        let email = Email(
                            id: UUID().uuidString, // SB objects have ephemeral IDs, safer to generate one or use persistent ID if available
                            sender: sender,
                            subject: subject,
                            body: body,
                            date: date
                        )
                        emails.append(email)

                        if emails.count >= limit {
                            break
                        }
                    }
                }
            }

            return emails
        }
    }
}
