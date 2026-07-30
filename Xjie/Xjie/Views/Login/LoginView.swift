import SwiftUI
import UIKit

private enum LoginFocusField: Hashable {
    case phone
    case username
    case age
    case height
    case weight
    case password
}

private enum SignupLegalDocument: String, Identifiable {
    case userAgreement
    case privacyPolicy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .userAgreement: "用户协议"
        case .privacyPolicy: "隐私政策"
        }
    }
}

/// 登录页面 — 对应小程序 pages/login/login
struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var vm: LoginViewModel
    /// Canvas 预览会关闭受试者目录加载，避免在 Xcode 中访问真实后端。
    private let loadsSubjects: Bool
    @State private var showReset = false
    @State private var showLegalConsentConfirmation = false
    @State private var presentedLegalDocument: SignupLegalDocument?
    @State private var isSubmittingCredentials = false
    @State private var isSubmittingSubject = false
    @FocusState private var focusedField: LoginFocusField?

    init() {
        loadsSubjects = true
        _vm = StateObject(wrappedValue: LoginViewModel())
    }

    #if DEBUG
    /// Canvas 专用入口：保留完整登录布局与本地输入交互，但不加载远程受试者目录。
    init(previewMode: Bool) {
        loadsSubjects = !previewMode
        _vm = StateObject(wrappedValue: LoginViewModel())
    }
    #endif

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Logo 区域
                logoArea

                // Debug UI 验证改由 UI 自动化启动参数触发，登录页不再展示入口。
                // #if DEBUG
                // debugValidationEntry
                // #endif

                // 受试者 ID 登录（科研内测专用）入口暂时停用。
                // modeSwitch

                if vm.mode == .subject {
                    subjectSection
                } else {
                    emailSection
                }

            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Color.appBackground)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button("上一项") { moveFocus(by: -1) }
                    .disabled(!canMoveFocus(by: -1))
                Button("下一项") { moveFocus(by: 1) }
                    .disabled(!canMoveFocus(by: 1))
                Spacer()
                Button("完成") { dismissKeyboard() }
            }
        }
        .task {
            guard loadsSubjects else { return }
            await vm.loadSubjects()
        }
        .alert("提示", isPresented: $vm.showAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(vm.alertMessage)
        }
        .alert("请先阅读并同意协议", isPresented: $showLegalConsentConfirmation) {
            Button("暂不注册", role: .cancel) {}
            Button("确认同意并注册") {
                vm.hasAcceptedUserAgreement = true
                vm.hasAcceptedPrivacyPolicy = true
                submitCredentials()
            }
        } message: {
            Text("注册前请阅读《用户协议》和《隐私政策》。点击“确认同意并注册”即表示你已阅读并同意两份协议。")
        }
        .sheet(isPresented: $showReset) {
            PasswordResetSheet()
        }
        .sheet(item: $presentedLegalDocument) { document in
            SignupLegalDocumentView(document: document)
        }
    }

    // MARK: - Logo

    private var logoArea: some View {
        VStack(spacing: 12) {
            Image("Logo")
                .resizable()
                .scaledToFill()
                .frame(width: 96, height: 96)
                .clipShape(Circle())
                .accessibilityLabel("小捷 Logo")

            Text("小捷")
                .font(.title).bold()
                .foregroundColor(.appText)

            Text("智能代谢健康管理")
                .font(.subheadline)
                .foregroundColor(.appMuted)
        }
        .padding(.top, 40)
    }

    // MARK: - 模式切换

    private var modeSwitch: some View {
        VStack(spacing: 12) {
            Divider()
            Button {
                dismissKeyboard()
                vm.mode = vm.mode == .subject ? .email : .subject
            } label: {
                Text(vm.mode == .subject ? "使用手机号登录" : "使用受试者 ID 登录")
                    .foregroundColor(.appPrimary)
                    .font(.subheadline)
            }
            .accessibilityIdentifier("login.mode.switch")
        }
    }

    // MARK: - 受试者登录

    private var subjectSection: some View {
        VStack(spacing: 16) {
            Text("选择受试者")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            if vm.subjects.isEmpty {
                Text("暂无可用受试者")
                    .foregroundColor(.appMuted)
                    .font(.subheadline)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(vm.subjects) { subject in
                            Button {
                                vm.selectedSubject = subject.subject_id
                            } label: {
                                HStack {
                                    Text(subject.subject_id)
                                        .foregroundColor(.appText)
                                    Spacer()
                                    Text(subject.cohort == "cgm" ? "CGM" : "肝脏")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(subject.cohort == "cgm" ? Color.appPrimary.opacity(0.1) : Color.appSuccess.opacity(0.1))
                                        .foregroundColor(subject.cohort == "cgm" ? .appPrimary : .appSuccess)
                                        .cornerRadius(4)
                                }
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(vm.selectedSubject == subject.subject_id ? Color.appPrimary : Color.gray.opacity(0.2), lineWidth: vm.selectedSubject == subject.subject_id ? 2 : 1)
                                )
                            }
                        }
                    }
                }
                .frame(maxHeight: 250)
            }

            Button {
                guard !vm.loading, !isSubmittingSubject else { return }
                isSubmittingSubject = true
                Task {
                    await vm.loginSubject(authManager: authManager)
                    isSubmittingSubject = false
                }
            } label: {
                Text("登录")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [Color.appGradientStart, Color.appGradientEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(vm.selectedSubject.isEmpty || vm.loading || isSubmittingSubject)
            .opacity(vm.selectedSubject.isEmpty ? 0.5 : 1)
        }
    }

    #if DEBUG
    private var debugValidationEntry: some View {
        Button {
            authManager.startUIValidationSession()
        } label: {
            Text("UI 验证入口")
                .font(.subheadline.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(colors: [Color.appGradientStart.opacity(0.88), Color.appGradientEnd.opacity(0.88)], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .accessibilityIdentifier("xjie.debug.uiValidationLogin")
    }
    #endif

    // MARK: - 手机号登录

    private var emailSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("手机号").font(.subheadline).foregroundColor(.appMuted)
                TextField("请输入手机号", text: $vm.phone)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .textInputAutocapitalization(.never)
                    .focused($focusedField, equals: .phone)
                    .submitLabel(.next)
                    .onSubmit { moveFocus(by: 1) }
                    .accessibilityIdentifier("login.phone")
            }

            if vm.isSignup {
                VStack(alignment: .leading, spacing: 6) {
                    Text("用户名").font(.subheadline).foregroundColor(.appMuted)
                    TextField("请输入用户名", text: $vm.username)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .username)
                        .submitLabel(.next)
                        .onSubmit { moveFocus(by: 1) }
                        .accessibilityIdentifier("login.username")
                }

                signupProfileSection
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("密码").font(.subheadline).foregroundColor(.appMuted)
                PasswordRevealField(
                    "至少 8 位",
                    text: $vm.password,
                    textContentType: vm.isSignup ? .newPassword : .password,
                    focus: passwordFocusBinding,
                    submitLabel: vm.isSignup ? .done : .go,
                    onSubmit: submitCredentials
                )
                .accessibilityIdentifier("login.password")
            }

            if vm.isSignup {
                // 健康需求暂不在注册页收集，保留组件与既有注册后处理逻辑以便后续恢复。
                // onboardingNeedsSection
                legalConsentSection
            }

            Button {
                submitCredentials()
            } label: {
                HStack {
                    if vm.loading { ProgressView().tint(.white) }
                    Text(vm.isSignup ? "注册" : "登录")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(colors: [Color.appGradientStart, Color.appGradientEnd], startPoint: .topLeading, endPoint: .bottomTrailing)
                )
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .accessibilityIdentifier("login.submit")
            .disabled(vm.loading || isSubmittingCredentials)

            Button {
                dismissKeyboard()
                vm.isSignup.toggle()
            } label: {
                Text(vm.isSignup ? "已有账号？去登录" : "没有账号？去注册")
                    .foregroundColor(.appPrimary)
                    .font(.subheadline)
            }
            .accessibilityIdentifier("login.signup.toggle")

            if !vm.isSignup {
                Button {
                    dismissKeyboard()
                    showReset = true
                } label: {
                    Text("忘记密码？")
                        .foregroundColor(.appPrimary)
                        .font(.caption)
                }
            }
        }
    }

    private var signupProfileSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("基本数据").font(.subheadline.bold()).foregroundColor(.appText)
            Text("性别").font(.caption).foregroundColor(.appMuted)
            Picker("性别", selection: $vm.sex) {
                Text("女").tag("female")
                Text("男").tag("male")
                Text("其他").tag("other")
            }
            .pickerStyle(.segmented)
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("年龄（岁）").font(.caption).foregroundColor(.appMuted)
                    TextField("请输入年龄", text: $vm.age)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .age)
                        .submitLabel(.next)
                        .onSubmit { moveFocus(by: 1) }
                        .accessibilityIdentifier("login.age")
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("身高（cm）").font(.caption).foregroundColor(.appMuted)
                    TextField("请输入身高", text: $vm.heightCm)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .height)
                        .submitLabel(.next)
                        .onSubmit { moveFocus(by: 1) }
                        .accessibilityIdentifier("login.height")
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("体重（kg）").font(.caption).foregroundColor(.appMuted)
                    TextField("请输入体重", text: $vm.weightKg)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .weight)
                        .submitLabel(.next)
                        .onSubmit { moveFocus(by: 1) }
                        .accessibilityIdentifier("login.weight")
                }
            }
        }
    }

    private var onboardingNeedsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("最后一步：健康需求").font(.subheadline.bold()).foregroundColor(.appText)
            Picker("目标", selection: $vm.onboardingTarget) {
                ForEach(["控糖稳定", "减重控脂", "改善睡眠", "提升体能", "综合健康"], id: \.self) { item in
                    Text(item).tag(item)
                }
            }
            .pickerStyle(.menu)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                onboardingChip("fitness", "健身")
                onboardingChip("diet_control", "饮食控制")
                onboardingChip("sleep", "睡眠")
                onboardingChip("hydration", "饮水")
                onboardingChip("medication", "用药")
                onboardingChip("glucose", "血糖追踪")
            }

            if vm.onboardingContents.contains("medication") {
                Toggle("确认有用药需求", isOn: $vm.medicationNeeded)
                    .font(.caption)
            }
            Toggle("注册后帮我生成首个健康计划", isOn: $vm.onboardingGeneratePlan)
                .font(.caption)
            Text("这些选择会保存到账号中，用于首页代谢状态、计划生成和后续 Agent 干预。")
                .font(.caption)
                .foregroundColor(.appMuted)
        }
        .padding(12)
        .background(Color.appCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var legalConsentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            legalConsentRow(
                accepted: $vm.hasAcceptedUserAgreement,
                document: .userAgreement,
                identifier: "login.legal.userAgreement"
            )
            legalConsentRow(
                accepted: $vm.hasAcceptedPrivacyPolicy,
                document: .privacyPolicy,
                identifier: "login.legal.privacyPolicy"
            )
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("login.legal.consents")
    }

    private func legalConsentRow(
        accepted: Binding<Bool>,
        document: SignupLegalDocument,
        identifier: String
    ) -> some View {
        HStack(alignment: .center, spacing: 6) {
            Button {
                accepted.wrappedValue.toggle()
            } label: {
                Image(systemName: accepted.wrappedValue ? "checkmark.square.fill" : "square")
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(accepted.wrappedValue ? Color.appPrimary : Color.appMuted)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("同意\(document.title)")
            .accessibilityValue(accepted.wrappedValue ? "已同意" : "未同意")
            .accessibilityIdentifier(identifier)

            Text("我已阅读并同意")
                .font(.caption)
                .foregroundStyle(Color.appMuted)

            Button {
                dismissKeyboard()
                presentedLegalDocument = document
            } label: {
                Text("《\(document.title)》")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("\(identifier).document")

            Spacer(minLength: 0)
        }
    }

    private func onboardingChip(_ key: String, _ label: String) -> some View {
        let selected = vm.onboardingContents.contains(key)
        return Button {
            if selected {
                vm.onboardingContents.remove(key)
                if key == "medication" { vm.medicationNeeded = false }
            } else {
                vm.onboardingContents.insert(key)
            }
        } label: {
            Text(label)
                .font(.caption.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selected ? Color.appPrimary.opacity(0.14) : Color.gray.opacity(0.08))
                .foregroundColor(selected ? .appPrimary : .appText)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var focusOrder: [LoginFocusField] {
        if vm.mode == .subject {
            return []
        }
        if vm.isSignup {
            return [.phone, .username, .age, .height, .weight, .password]
        }
        return [.phone, .password]
    }

    private var passwordFocusBinding: Binding<Bool> {
        Binding(
            get: { focusedField == .password },
            set: { isFocused in
                if isFocused {
                    focusedField = .password
                } else if focusedField == .password {
                    focusedField = nil
                }
            }
        )
    }

    private func canMoveFocus(by offset: Int) -> Bool {
        guard let focusedField,
              let currentIndex = focusOrder.firstIndex(of: focusedField)
        else { return false }
        return focusOrder.indices.contains(currentIndex + offset)
    }

    private func moveFocus(by offset: Int) {
        guard let focusedField,
              let currentIndex = focusOrder.firstIndex(of: focusedField)
        else {
            self.focusedField = focusOrder.first
            return
        }

        let targetIndex = currentIndex + offset
        guard focusOrder.indices.contains(targetIndex) else {
            dismissKeyboard()
            return
        }
        self.focusedField = focusOrder[targetIndex]
    }

    private func dismissKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

    private func submitCredentials() {
        guard !vm.loading, !isSubmittingCredentials else { return }
        if vm.isSignup && !vm.hasAcceptedRequiredLegalAgreements {
            dismissKeyboard()
            showLegalConsentConfirmation = true
            return
        }
        isSubmittingCredentials = true
        dismissKeyboard()
        Task {
            await vm.loginPhone(authManager: authManager)
            isSubmittingCredentials = false
        }
    }
}

private struct SignupLegalDocumentView: View {
    let document: SignupLegalDocument
    @Environment(\.dismiss) private var dismiss

    private var sections: [(title: String, content: String)] {
        switch document {
        case .userAgreement:
            [
                ("服务说明", "“小捷”提供健康档案、健康数据记录、趋势展示、提醒和健康管理相关服务。应用中的健康管理内容仅供参考，不构成诊断、处方、治疗建议或紧急医疗服务。"),
                ("账号与使用", "请使用真实、合法的信息注册并妥善保管账号和密码。不得利用本服务发布违法、有害或侵犯他人权益的内容，也不得干扰服务的正常运行。"),
                ("健康信息与服务边界", "你应自行判断录入、上传和同步的信息是否准确、完整。出现紧急症状、身体明显不适或需要诊疗时，请及时联系医疗机构或当地急救服务。"),
                ("服务变更与终止", "我们可能基于服务运营、安全或法律要求更新功能或协议，并通过应用内合理方式告知。你可随时停止使用服务、退出登录或按页面指引申请注销账号。"),
                ("联系我们", "如对本协议、账号或服务有疑问，可通过应用内意见反馈或 support@xjie-health.com 联系我们。")
            ]
        case .privacyPolicy:
            XAgeSupportComplianceContract.privacyPolicySections.map {
                (title: $0.title, content: $0.content)
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("请在注册前仔细阅读")
                        .font(.subheadline)
                        .foregroundStyle(Color.appMuted)

                    ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.title)
                                .font(.headline)
                                .foregroundStyle(Color.appText)
                            Text(section.content)
                                .font(.subheadline)
                                .foregroundStyle(Color.appMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.appBackground)
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .accessibilityIdentifier("login.legal.document.\(document.id)")
    }
}

struct PasswordRevealField: View {
    private enum FocusTarget: Hashable {
        case secure
        case visible
    }

    let placeholder: String
    @Binding var text: String
    var textContentType: UITextContentType?
    private var externalFocus: Binding<Bool>?
    private var submitLabel: SubmitLabel
    private var onSubmit: (() -> Void)?
    @State private var isVisible = false
    @State private var isSwitchingVisibility = false
    @FocusState private var localFocus: FocusTarget?

    init(
        _ placeholder: String,
        text: Binding<String>,
        textContentType: UITextContentType? = nil,
        focus: Binding<Bool>? = nil,
        submitLabel: SubmitLabel = .done,
        onSubmit: (() -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self._text = text
        self.textContentType = textContentType
        self.externalFocus = focus
        self.submitLabel = submitLabel
        self.onSubmit = onSubmit
    }

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                SecureField(placeholder, text: $text)
                    .focused($localFocus, equals: .secure)
                    .textContentType(isVisible ? nil : textContentType)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(submitLabel)
                    .onSubmit { onSubmit?() }
                    .opacity(isVisible ? 0 : 1)
                    .allowsHitTesting(!isVisible)
                    .accessibilityHidden(isVisible)

                TextField(placeholder, text: $text)
                    .focused($localFocus, equals: .visible)
                    .textContentType(isVisible ? textContentType : nil)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(submitLabel)
                    .onSubmit { onSubmit?() }
                    .opacity(isVisible ? 1 : 0)
                    .allowsHitTesting(isVisible)
                    .accessibilityHidden(!isVisible)
            }

            Button {
                toggleVisibility()
            } label: {
                Text(isVisible ? "隐藏" : "显示密码")
                    .font(.caption2.bold())
                    .foregroundColor(.appPrimary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .disabled(isSwitchingVisibility)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color(.separator).opacity(0.45), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .onAppear {
            syncLocalFocus(with: externalFocusValue)
        }
        .onChange(of: externalFocusValue) { _, shouldFocus in
            syncLocalFocus(with: shouldFocus)
        }
        .onChange(of: localFocus) { _, target in
            if target == nil, isSwitchingVisibility {
                return
            }
            externalFocus?.wrappedValue = target != nil
        }
    }

    private var externalFocusValue: Bool {
        externalFocus?.wrappedValue ?? false
    }

    private func syncLocalFocus(with shouldFocus: Bool) {
        if shouldFocus {
            let target: FocusTarget = isVisible ? .visible : .secure
            if localFocus != target {
                localFocus = target
            }
        } else if localFocus != nil {
            localFocus = nil
        }
    }

    private func toggleVisibility() {
        let shouldRestoreFocus = localFocus != nil || externalFocusValue
        isSwitchingVisibility = shouldRestoreFocus
        isVisible.toggle()

        guard shouldRestoreFocus else { return }
        let target: FocusTarget = isVisible ? .visible : .secure
        localFocus = target
        externalFocus?.wrappedValue = true
        Task { @MainActor in
            await Task.yield()
            localFocus = target
            externalFocus?.wrappedValue = true
            isSwitchingVisibility = false
        }
    }
}

#if DEBUG
/// 登录页 Canvas 宿主：认证状态与页面数据均为本地实例，不读取真实登录态。
private struct LoginPreviewHost: View {
    @StateObject private var authManager = AuthManager.makeTestingInstance()

    var body: some View {
        LoginView(previewMode: true)
            .environmentObject(authManager)
    }
}

#Preview("登录页") {
    LoginPreviewHost()
}
#endif
