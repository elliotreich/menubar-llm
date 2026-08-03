import SwiftUI

struct ChatView: View {
    @EnvironmentObject var viewModel: ChatViewModel

    var body: some View {
        VStack(spacing: 0) {
            // MARK: Toolbar
            HStack(spacing: 12) {
                Button(action: { viewModel.toggleMode() }) {
                    Text(viewModel.currentMode == "fast" ? "⚡ Fast" : "🧠 Reasoning")
                        .font(.caption.bold())
                        .frame(minWidth: 80)
                }
                .buttonStyle(.borderedProminent)
                .tint(viewModel.currentMode == "fast" ? .blue : .purple)

                Spacer()

                Button(action: { viewModel.clearChat() }) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("Clear chat")

                Button(action: { viewModel.showSettings = true }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.borderless)
                .help("Settings")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.windowBackgroundColor))

            Divider()

            // MARK: Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                        }

                        if viewModel.isLoading {
                            HStack {
                                Spacer()
                                Text(viewModel.currentMode == "reasoning" ? "🧠 Reasoning..." : "⚡ ...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(8)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(8)
                                Spacer()
                            }
                        }
                        
                        if viewModel.lastSearchCount > 0 {
                            HStack {
                                Image(systemName: "globe")
                                    .font(.caption2)
                                Text("\(viewModel.lastSearchCount) web sources")
                                    .font(.caption2)
                                Spacer()
                            }
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                        }

                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onChange(of: viewModel.isLoading) { _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }

            // MARK: Error Banner
            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.05))
            }

            Divider()

            // MARK: Input
            HStack(spacing: 8) {
                TextField("Ask anything...", text: $viewModel.inputText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        viewModel.sendMessage()
                    }

                Button(action: { viewModel.sendMessage() }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(
                    viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || viewModel.isLoading
                )
                .buttonStyle(.borderless)
            }
            .padding()
            .background(Color(.windowBackgroundColor))
        }
        .frame(width: 400, height: 500)
        // NOTE: .sheet doesn't work inside NSPopover (no parent window).
        // Instead, swap the entire popover content when settings is shown.
        .overlay {
            if viewModel.showSettings {
                SettingsView()
                    .environmentObject(viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.windowBackgroundColor))
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.showSettings)
    }
}

struct MessageBubble: View {
    let message: Message

    var body: some View {
        HStack {
            if message.role == "user" { Spacer() }

            VStack(alignment: message.role == "user" ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(10)
            .background(
                message.role == "user"
                    ? Color.blue.opacity(0.15)
                    : Color.secondary.opacity(0.1)
            )
            .cornerRadius(10)
            .frame(maxWidth: 300, alignment: message.role == "user" ? .trailing : .leading)

            if message.role == "assistant" { Spacer() }
        }
    }
}
