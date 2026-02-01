# MacAssistant

**MacAssistant** is a native macOS application that seamlessly integrates with Apple Mail and Reminders to provide AI-powered assistance. It reads your unread emails, generates a summary using an LLM (OpenAI), and automatically creates actionable reminders for you.

![Screenshot Placeholder](https://via.placeholder.com/800x450.png?text=MacAssistant+UI+Screenshot)
*(Note: Replace with actual screenshot of the Spotlight-like UI)*

## Features

*   **Native Integration**: Works directly with the Apple Mail app and Reminders via Apple Scripting Bridge and EventKit.
*   **AI-Powered**: Summarizes email content and extracts action items using OpenAI's GPT models.
*   **Spotlight UI**: A clean, floating input bar that feels like a native part of the OS.
*   **Shortcuts Support**: Includes an "Check Mail and Summarize" action that can be used in Apple Shortcuts workflows.

## Prerequisites

*   **macOS 14.0 (Sonoma)** or later.
*   **Xcode 15.0** or later (for building).
*   **OpenAI API Key**: Required for the LLM service to function.

## Installation

### Method 1: Build from Source (Command Line)

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/yourusername/MacAssistant.git
    cd MacAssistant
    ```

2.  **Build the project**:
    ```bash
    swift build -c release
    ```

3.  **Run**:
    The executable will be in `.build/release/MacAssistant`.
    ```bash
    ./.build/release/MacAssistant
    ```
    *Note: You may need to grant permissions for Mail and Reminders when prompted.*

### Method 2: Xcode (Recommended for Development)

1.  Open the folder in Xcode or generate a project file:
    ```bash
    swift package generate-xcodeproj
    open MacAssistant.xcodeproj
    ```
2.  Select the `MacAssistant` scheme.
3.  Set your OpenAI API Key in the code (or modify `MacApp.swift` to read from an environment variable/Settings).
4.  Run (Cmd+R).

## Configuration

### API Key
Currently, the `OpenAILLMService` expects the API key to be passed during initialization. In `Sources/App/MacApp.swift`, verify the initialization:

```swift
@StateObject var interactor = AssistantInteractor(
    // ...
    llmService: OpenAILLMService(apiKey: "YOUR_API_KEY_HERE") // OR use MockLLMService() for testing
)
```
*Security Note: Do not commit your real API key.*

### Permissions
The first time you run the app, macOS will ask for permission to:
*   Control "Mail"
*   Access "Reminders"

You must **Allow** these for the app to function. If you deny them, you can reset them in **System Settings > Privacy & Security > Automation**.

## Usage

1.  **Launch the App**. You will see a small floating bar.
2.  **Type a command**: e.g., "Check my mail".
3.  **Wait for Analysis**: The app will fetch the last 500 unread emails (limit configurable), send them to the LLM, and display a summary.
4.  **Action Items**: If the LLM identifies tasks, they will be automatically added to your default Reminders list.

### Shortcuts
1.  Open the **Shortcuts** app on macOS.
2.  Search for **MacAssistant**.
3.  Add the **Check Mail and Summarize** action to your workflow.

## Troubleshooting

*   **App crashes immediately**: Ensure `Info.plist` is correctly embedded if you are building a proper `.app` bundle, or that you are running from a context that handles entitlements.
*   **"Mail app is not running"**: The Mail app must be running (background or foreground) for the ScriptingBridge to work.
*   **No emails found**: Ensure you have unread emails in your inbox.
