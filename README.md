# menubar-llm

macOS menubar-only LLM chat client. Lives in the status bar, supports streaming completions, web search via Tavily, and a global hotkey (Cmd+Shift+Space).

## Features

- **Two modes**: Fast (default) and Reasoning — switch between cheap/quick models and powerful reasoning models
- **Streaming responses**: Real-time token-by-token display
- **Web search**: Optional Tavily integration — injects live search results into the LLM context
- **Global hotkey**: `Cmd+Shift+Space` toggles the popover from anywhere
- **OpenAI-compatible**: Works with any API that speaks the OpenAI chat completions format (DeepSeek, OpenAI, Anthropic via proxy, etc.)
- **Minimal UI**: No dock icon, no window chrome — pure menubar popover

## Defaults

The app ships configured for DeepSeek:
- Base URL: `https://api.deepseek.com/v1`
- Fast model: `deepseek-v4-flash`
- Reasoning model: `deepseek-v4-pro`

All settings are configurable in-app and persist in UserDefaults.

## API Key Configuration

Open the Settings panel (gear icon in the popover toolbar) and enter:

| Field | Description |
|---|---|
| **API Key** | Your LLM provider API key |
| **Base URL** | API endpoint (e.g., `https://api.deepseek.com/v1` or `https://api.openai.com/v1`) |
| **Fast Model** | Model name for fast responses (e.g., `gpt-4o-mini`) |
| **Reasoning Model** | Model name for reasoning tasks (e.g., `o1-mini`) |
| **Tavily API Key** | (Optional) Key for web search — get one at [tavily.com](https://tavily.com) |
| **Enable Web Search** | Toggle web search on/off |

> **Security note**: API keys are stored in `UserDefaults` (plaintext). For production use, switch to the macOS Keychain.

## Hotkeys

| Shortcut | Action |
|---|---|
| `Cmd+Shift+Space` | Toggle popover (global) |
| `Cmd+Q` | Quit app |
| `Cmd+C` / `Cmd+V` / `Cmd+A` | Standard edit shortcuts |

**Accessibility permission required** for the global hotkey. If `Cmd+Shift+Space` doesn't work:
1. Go to **System Settings > Privacy & Security > Accessibility**
2. Add MenubarLLM.app to the list
3. Restart the app

## Build

Requires Swift 5.9+ and macOS 13+.

```bash
cd menubar-llm
swift build -c release
cp .build/release/MenubarLLM MenubarLLM.app/Contents/MacOS/MenubarLLM
```

The built binary is also deployed as `/Applications/MenubarLLM.app`.

## Tech Stack

- **Language**: Swift 5.9
- **UI**: SwiftUI + AppKit (NSStatusItem, NSPopover)
- **LLM API**: OpenAI-compatible streaming (SSE)
- **Web Search**: Tavily API
- **Minimum OS**: macOS 13 (Ventura)

## Caveats

- The settings view overlays the chat view (no separate window) — `.sheet()` doesn't work inside `NSPopover`
- Global hotkey requires Accessibility permissions
- API keys stored in UserDefaults, not the Keychain
