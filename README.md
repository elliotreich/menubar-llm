# menubar-llm

macOS menubar-only LLM chat client. Lives in the status bar, supports streaming completions, web search via Tavily, and a global hotkey (Cmd+Shift+Space).

## Features

- **Two modes**: Fast (default) and Reasoning — switch between cheap/quick models and powerful reasoning models
- **Streaming responses**: Real-time token-by-token display
- **Web search**: Optional Tavily integration — injects live search results into the LLM context
- **Global hotkey**: `Cmd+Shift+Space` toggles the popover from anywhere
- **OpenAI-compatible**: Works with any API speaking the OpenAI chat completions format — Cerebras, DeepSeek, OpenAI, Groq, OpenRouter, or a local Ollama server
- **Minimal UI**: No dock icon, no window chrome — pure menubar popover

## Defaults

The app ships pointed at DeepSeek, with **no API key** — nothing works until you
enter one in Settings:

- Base URL: `https://api.deepseek.com/v1`
- Fast model: `deepseek-v4-flash`
- Reasoning model: `deepseek-v4-pro`

These are only defaults. Every field — including the base URL — is editable in
Settings and persists to UserDefaults, so the app works with any
OpenAI-compatible provider without rebuilding.

## Recommended: Cerebras (free, very fast)

If you want near-instant answers at no cost, point the app at
[Cerebras](https://cloud.cerebras.ai). It serves `gpt-oss-120b` at roughly
3000 tokens/sec — fast enough that responses feel immediate in a menubar popover.

| Field | Value |
|---|---|
| Base URL | `https://api.cerebras.ai/v1` |
| Fast Model | `gpt-oss-120b` |
| Reasoning Model | `gpt-oss-120b` |

**Free tier limits (per model):** 1M tokens/day, 2400 requests/day, 30k
tokens/min, and **5 requests/min**. The 5 RPM ceiling is the binding constraint
— fine for menubar-style use (a question here and there), but it makes Cerebras
a poor fit for agentic tools that fire many requests in quick succession.

A single request is also capped by the 30k tokens/min window: a prompt around
24k tokens or larger returns `429 token_quota_exceeded`.

Use `gpt-oss-120b` for both modes. Cerebras's larger `zai-glm-4.7` was
deprecated on 2026-08-17, leaving no second model worth assigning to Reasoning.

### Other providers

Anything speaking the OpenAI `/chat/completions` format works — OpenAI, Groq,
OpenRouter, Together, or a local Ollama/LM Studio server
(`http://localhost:11434/v1`). Groq is a reasonable free alternative with a more
forgiving 30 RPM, though its 200k tokens/day and 8k tokens/min are considerably
tighter than Cerebras.

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

## Launch at login

To start the app automatically when you log in:

**System Settings** → **General** → **Login Items** → **+** → select
`MenubarLLM.app`.

Or from the terminal:

```bash
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/MenubarLLM.app", hidden:false}'
```

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

## Tests

No automated test suite yet. Verification is via `swift build` and manual smoke test:

```bash
swift build -c release   # must succeed
swift run MenubarLLM     # check menubar appears, chat streams, Tavily search
```

A future `Tests/` target could cover `LLMService` request formatting and `TavilyService` parsing without network calls.

## Maintenance

- **Settings:** all fields (base URL, models, API keys) are in `UserDefaults` — no keychain yet. Changing providers needs no rebuild, just edit in Settings UI.
- **Providers:** update default base URL/models in `Sources/MenubarLLM/LLMService.swift` if defaults drift (e.g., Cerebras model deprecation already handled for `gpt-oss-120b`).
- **Build:** `swift build -c release` produces `.build/release/MenubarLLM`. To make an app bundle, wrap the binary in `MenubarLLM.app/Contents/MacOS/` and sign if distributing beyond this Mac.
