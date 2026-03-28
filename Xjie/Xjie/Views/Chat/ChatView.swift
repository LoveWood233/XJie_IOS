import SwiftUI

/// AI 聊天页面 — 对应小程序 pages/chat/chat
struct ChatView: View {
    @StateObject private var vm = ChatViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 消息列表
                messageList

                // 推荐问题
                if let lastAssistant = vm.messages.last(where: { $0.role == "assistant" }),
                   let followups = lastAssistant.followups, !followups.isEmpty {
                    followupsBar(followups)
                }

                // 输入栏
                inputBar
            }
            .navigationTitle("AI 助手")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("+ 新对话") { vm.newChat() }
                        .font(.subheadline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { vm.showHistory.toggle() } label: {
                        Label("历史", systemImage: "clock.arrow.circlepath")
                    }
                    .font(.subheadline)
                }
            }
            .sheet(isPresented: $vm.showHistory) {
                historySheet
            }
        }
        .task { await vm.loadConversations() }
        .alert("错误", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    // MARK: - 消息列表

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if vm.messages.isEmpty {
                        welcomeMessage
                    }

                    ForEach(Array(vm.messages.enumerated()), id: \.offset) { _, msg in
                        messageBubble(msg)
                    }

                    if vm.sending {
                        HStack {
                            Text("思考中...")
                                .font(.subheadline)
                                .foregroundColor(.appMuted)
                                .padding(12)
                                .background(Color.appCardBg)
                                .cornerRadius(12)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                    }

                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(.vertical, 8)
            }
            .onChange(of: vm.messages.count) { _, _ in
                withAnimation {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    private var welcomeMessage: some View {
        VStack(spacing: 8) {
            Image(systemName: "brain")
                .font(.system(size: 40))
                .foregroundColor(.appPrimary)
            Text("你好！我是你的健康AI助手。")
                .font(.headline)
            Text("可以问我关于血糖、膳食、健康管理的问题。")
                .font(.subheadline)
                .foregroundColor(.appMuted)
        }
        .padding(24)
        .accessibilityElement(children: .combine)
    }

    private func messageBubble(_ msg: ChatMessageItem) -> some View {
        HStack {
            if msg.role == "user" { Spacer() }
            Text(msg.content)
                .font(.subheadline)
                .padding(12)
                .background(msg.role == "user" ? Color.appPrimary : Color.appCardBg)
                .foregroundColor(msg.role == "user" ? .white : .appText)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            if msg.role != "user" { Spacer() }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - 推荐问题

    private func followupsBar(_ items: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { q in
                    Button {
                        vm.inputValue = q
                        Task { await vm.sendMessage() }
                    } label: {
                        Text(q)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.appPrimary.opacity(0.1))
                            .foregroundColor(.appPrimary)
                            .cornerRadius(16)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
        }
    }

    // MARK: - 输入栏

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("输入消息...", text: $vm.inputValue)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.send)
                .onSubmit { Task { await vm.sendMessage() } }

            Button {
                Task { await vm.sendMessage() }
            } label: {
                Text("发送")
                    .font(.subheadline.bold())
                    .foregroundColor(!vm.inputValue.isEmpty && !vm.sending ? .appPrimary : .appMuted)
            }
            .disabled(vm.inputValue.isEmpty || vm.sending)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.appCardBg)
    }

    // MARK: - 历史会话

    private var historySheet: some View {
        NavigationStack {
            List {
                ForEach(vm.conversations) { conv in
                    Button {
                        Task {
                            await vm.loadConversation(id: conv.id)
                            vm.showHistory = false
                        }
                    } label: {
                        VStack(alignment: .leading) {
                            Text(conv.title ?? "对话")
                                .foregroundColor(.appText)
                            Text("\(conv.message_count ?? 0) 条消息")
                                .font(.caption)
                                .foregroundColor(.appMuted)
                        }
                    }
                }
                // PERF-03: 加载更多会话
                if vm.hasMoreConversations {
                    Button {
                        Task { await vm.loadMoreConversations() }
                    } label: {
                        Text("加载更多")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("历史对话")
            .navigationBarTitleDisplayMode(.inline)
            .overlay {
                if vm.conversations.isEmpty {
                    Text("暂无历史对话")
                        .foregroundColor(.appMuted)
                }
            }
        }
    }
}

