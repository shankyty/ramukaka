# Design Document: AI Assistance App for macOS

## Overview
This is a native macOS application designed to integrate seamlessly with Apple's ecosystem (Mail, Reminders, Calendar, Notes). It leverages Large Language Models (LLMs) to provide intelligent assistance, starting with email summarization and task management. The app features a "Spotlight-like" UI and supports Apple Shortcuts.

## Architecture
The application follows a **Clean Architecture** approach with **MVVM** for the UI layer.

### Core Components

1.  **UI Layer (`View`)**:
    *   **`SpotlightView`**: The main interface, a floating input bar similar to Spotlight or Raycast. It displays status and results.
    *   **`MacApp`**: Handles the application lifecycle, menu bar icon, and global hotkey registration.

2.  **Business Logic Layer (`Interactor` / `ViewModel`)**:
    *   **`AssistantInteractor`**: The central coordinator. It receives user input or triggers, orchestrates calls to services, and manages the state.

3.  **Service Layer (Interfaces)**:
    *   **`LLMService`**: Abstraction for LLM providers (e.g., OpenAI, Anthropic, Local LLMs).
    *   **`MailService`**: Abstraction for reading emails.
    *   **`ReminderService`**: Abstraction for managing reminders.
    *   **`CalendarService`**: Abstraction for calendar events (future).
    *   **`NotesService`**: Abstraction for notes (future).

4.  **Data Models**:
    *   `Email`: Represents an email message.
    *   `ReminderItem`: Represents a task to be created.
    *   `Summary`: The structured output from the LLM.

## Contracts (Swift Protocols)

These protocols define the interactions between components, ensuring loose coupling and testability.

### Mail Service
```swift
protocol MailService {
    /// Fetches unread emails from the inbox.
    func fetchUnreadEmails(limit: Int) async throws -> [Email]
}
```

### Reminder Service
```swift
protocol ReminderService {
    /// Creates a new reminder in the default list.
    func createReminder(title: String, notes: String?, dueDate: Date?) async throws
}
```

### LLM Service
```swift
protocol LLMService {
    /// Generates a summary and action items from a list of emails.
    func processEmails(_ emails: [Email]) async throws -> EmailAnalysis
}
```

## Data Models

```swift
struct Email: Identifiable {
    let id: String
    let sender: String
    let subject: String
    let body: String
    let date: Date
}

struct EmailAnalysis: Codable {
    let summary: String
    let actionItems: [ActionItem]
}

struct ActionItem: Codable {
    let title: String
    let description: String?
    let suggestedDueDate: Date?
}
```

## Data Flow (v1: Mail to Reminders)

1.  **Trigger**: User activates the app (via Hotkey or Shortcut).
2.  **Input**: User requests "Check my mail" or the system runs a scheduled check.
3.  **Fetch**: `AssistantInteractor` calls `MailService.fetchUnreadEmails()`.
    *   *Implementation Detail*: Uses `ScriptingBridge` to communicate with Apple Mail.
4.  **Process**: `AssistantInteractor` sends the email content to `LLMService.processEmails()`.
    *   *Implementation Detail*: Constructs a prompt containing email bodies and asks for a JSON response with summary and tasks.
5.  **Action**: `AssistantInteractor` receives `EmailAnalysis`.
    *   It displays the summary in the UI.
    *   It iterates through `actionItems` and calls `ReminderService.createReminder()`.
    *   *Implementation Detail*: Uses `EventKit` to add reminders to the user's database.

## Extensibility

*   **New LLM Providers**: Implement the `LLMService` protocol (e.g., `AnthropicService`, `LocalLlamaService`). The app can switch providers via dependency injection.
*   **New Tools**: Create new service protocols (e.g., `HomeKitService`) and inject them into the Interactor.
*   **Shortcuts**: The app will expose `AppIntents` which map directly to the `AssistantInteractor` methods, allowing Shortucts to invoke the same logic as the UI.

## Future Considerations
*   **Context Awareness**: Use a vector database to store email history for better context.
*   **Calendar Integration**: Check for conflicts before scheduling reminders.
