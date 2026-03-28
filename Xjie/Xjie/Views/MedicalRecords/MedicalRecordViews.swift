import SwiftUI

/// 病例列表 — 对应小程序 pages/medical-records/list
struct MedicalRecordListView: View {
    @StateObject private var vm = MedicalRecordListViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // 上传按钮
                Button { vm.showDocumentPicker = true } label: {
                    HStack {
                        Image(systemName: "camera")
                        Text("上传病例").foregroundColor(.appText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.appPrimary.opacity(0.1))
                    .cornerRadius(10)
                }

                if vm.items.isEmpty && !vm.loading {
                    emptyState
                } else {
                    ForEach(vm.items) { item in
                        NavigationLink(destination: MedicalRecordDetailView(docId: item.id)) {
                            documentRow(item)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(Color.appBackground)
        .navigationTitle("历史病例")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.fetchList() }
        .refreshable { await vm.fetchList() }
        .overlay { if vm.loading { ProgressView() } }
        .sheet(isPresented: $vm.showDocumentPicker) {
            DocumentPickerView { data, fileName in
                Task { await vm.uploadRecord(data: data, fileName: fileName) }
            }
        }
        .alert("确认删除", isPresented: $vm.showDeleteAlert) {
            Button("删除", role: .destructive) { Task { await vm.confirmDelete() } }
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后无法恢复，确定吗？")
        }
        .alert("错误", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    /// CODE-01: 使用共享标签组件
    private func documentRow(_ item: HealthDocument) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name ?? "未命名")
                    .font(.subheadline).bold()
                    .foregroundColor(.appText)
                HStack(spacing: 6) {
                    SourceTag(sourceType: item.source_type)
                    StatusTag(status: item.extraction_status)
                    if let date = item.doc_date {
                        Text(date).font(.caption2).foregroundColor(.appMuted)
                    }
                }
            }
            Spacer()
            Button {
                vm.deleteId = item.id
                vm.showDeleteAlert = true
            } label: {
                Text("删除")
                    .font(.caption)
                    .foregroundColor(.appDanger)
            }
        }
        .cardStyle()
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "doc.text",
            title: "暂无病例记录",
            subtitle: "点击上方按钮上传病例"
        )
    }
}

/// 病例详情 — 对应小程序 pages/medical-records/detail
struct MedicalRecordDetailView: View {
    let docId: String
    @StateObject private var vm = DocumentDetailViewModel()

    var body: some View {
        ScrollView {
            if let doc = vm.doc {
                VStack(alignment: .leading, spacing: 12) {
                    // 标题 — CODE-01: 使用共享标签组件
                    VStack(alignment: .leading, spacing: 4) {
                        Text(doc.name ?? "病例详情").font(.title3).bold()
                        HStack(spacing: 6) {
                            SourceDetailTag(sourceType: doc.source_type)
                            StatusDetailTag(status: doc.extraction_status)
                        }
                    }
                    .cardStyle()

                    // CSV 数据表格 — CODE-01: 使用共享 CSVTableView
                    if let csv = doc.csv_data, let columns = csv.columns, let rows = csv.rows {
                        CSVTableView(title: "病例数据", icon: "tablecells", columns: columns, rows: rows)
                    } else {
                        Text("暂无提取数据（LLM 处理中）")
                            .foregroundColor(.appMuted)
                            .cardStyle()
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .background(Color.appBackground)
        .navigationTitle("病例详情")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.fetchDetail(id: docId) }
        .overlay { if vm.loading { ProgressView() } }
    }
}
