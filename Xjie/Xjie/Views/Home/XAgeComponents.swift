import AVFoundation
import Speech
import SwiftUI
import UIKit

struct XAgeSectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color(hex: "173F64"))
            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(hex: "6C8194"))
        }
    }
}

struct XAgeGlassTextField<Field: Hashable>: View {
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    let field: Field
    var focusedField: FocusState<Field?>.Binding
    var contentType: UITextContentType? = nil
    var capitalization: TextInputAutocapitalization = .sentences
    var submitLabel: SubmitLabel = .done
    var nextField: Field? = nil

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.system(size: 14, weight: .semibold))
            .keyboardType(keyboardType)
            .textContentType(contentType)
            .textInputAutocapitalization(capitalization)
            .disableAutocorrection(true)
            .focused(focusedField, equals: field)
            .submitLabel(submitLabel)
            .onSubmit {
                focusedField.wrappedValue = nextField
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .background(XAgeCapsuleFill())
    }
}

struct XAgeGradientActionLabel: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
            Text(title)
                .font(.system(size: 14, weight: .bold))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(
            Capsule()
                .fill(LinearGradient(colors: [Color(hex: "238AD6"), Color(hex: "20CDB1")], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
    }
}

struct CapsuleButton: View {
    let title: String
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(Color(hex: "365F80"))
                .frame(width: 56, height: 44)
                .background {
                    XAgeCapsuleFill()
                        .frame(height: 30)
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.42)
    }
}

struct XAgeGlassCardBackground: View {
    var cornerRadius: CGFloat

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.white.opacity(0.56))
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(0.84), lineWidth: 1)
            )
            .shadow(color: Color(hex: "73C8F0").opacity(0.18), radius: 28, x: 0, y: 14)
    }
}

struct XAgeCapsuleFill: View {
    var body: some View {
        Capsule()
            .fill(.white.opacity(0.58))
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.88), lineWidth: 1))
            .shadow(color: Color(hex: "7ACAF5").opacity(0.12), radius: 14, x: 0, y: 7)
    }
}

struct XAgeRoundedFieldBackground: View {
    var cornerRadius: CGFloat = 18

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)

        shape
            .fill(.white.opacity(0.58))
            .background(.ultraThinMaterial, in: shape)
            .overlay(shape.stroke(.white.opacity(0.88), lineWidth: 1))
            .shadow(color: Color(hex: "7ACAF5").opacity(0.12), radius: 14, x: 0, y: 7)
    }
}

struct XAgeLiquidBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "E8F7FF"), Color(hex: "D5ECFF"), Color(hex: "F7FCFF")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Circle()
                .fill(Color(hex: "61E7E1").opacity(0.28))
                .frame(width: 235, height: 235)
                .blur(radius: 26)
                .offset(x: -150, y: -260)
            Circle()
                .fill(Color(hex: "8CC8FF").opacity(0.32))
                .frame(width: 260, height: 300)
                .blur(radius: 30)
                .offset(x: 160, y: -320)
            Circle()
                .fill(Color(hex: "C9C2FF").opacity(0.22))
                .frame(width: 230, height: 260)
                .blur(radius: 34)
                .offset(x: 135, y: 150)
            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(width: 88)
                .blur(radius: 22)
                .rotationEffect(.degrees(5))
                .offset(x: -6)
        }
    }
}

#if DEBUG
private enum XAgeStylePreviewField: Hashable {
    case input
}

struct XAgeStyleComponentsPreview: View {
    @State private var text = ""
    @FocusState private var focusedField: XAgeStylePreviewField?

    var body: some View {
        VStack(spacing: 18) {
            XAgeGlassTextField(
                placeholder: "输入内容",
                text: $text,
                field: .input,
                focusedField: $focusedField
            )
            XAgeGradientActionLabel(title: "主要操作", icon: "checkmark")
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.clear)
                .frame(height: 96)
                .background(XAgeGlassCardBackground(cornerRadius: 24))
        }
        .padding(24)
        .background(XAgeLiquidBackground().ignoresSafeArea())
    }
}

/// 仅供 Canvas 调整三评分与说明卡视觉效果，不读取真实账号或服务端数据。
struct XAgeScoreDashboardPreview: View {
    @State private var pressure = 45
    @State private var recovery = 60
    @State private var inflammation = 41

    private var scores: XAgeCompositeScores {
        Self.debugScores(pressure: pressure, recovery: recovery, inflammation: inflammation)
    }

    var body: some View {
        ZStack {
            XAgeLiquidBackground().ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("今日健康数据 · 调试")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(Color(hex: "123E67"))
                    HStack(spacing: 0) {
                        XAgeScoreRing(kind: .pressure, metric: scores.pressure)
                        XAgeScoreRing(kind: .recovery, metric: scores.recovery)
                        XAgeScoreRing(kind: .inflammation, metric: scores.inflammation)
                    }
                    .padding(.vertical, 12)
                    .background(XAgeGlassCardBackground(cornerRadius: 28))
                    XAgeScoreSummaryCard(compactProgress: 0, scores: scores)
                    VStack(spacing: 8) {
                        scoreControl("压力", value: $pressure, tint: XAgeDataKind.pressure.tint)
                        scoreControl("恢复", value: $recovery, tint: XAgeDataKind.recovery.tint)
                        scoreControl("炎症", value: $inflammation, tint: XAgeDataKind.inflammation.tint)
                    }
                }
                .padding(24)
            }
        }
    }

    static func debugScores(pressure: Int, recovery: Int, inflammation: Int) -> XAgeCompositeScores {
        XAgeCompositeScores(
            pressure: debugMetric(pressure, name: "压力", confidence: 72),
            recovery: debugMetric(recovery, name: "恢复", confidence: 86),
            inflammation: debugMetric(inflammation, name: "炎症", confidence: 64),
            xAge: XAgeTrustedScorePresentationPolicy.currentPresentation().xAge
        )
    }

    private static func debugMetric(_ value: Int, name: String, confidence: Int) -> XAgeMetricScore {
        XAgeMetricScore(
            value: min(100, max(0, value)), confidence: confidence, isReady: true,
            badgeLabel: "已评分", stateLabel: "\(name)稳定", summary: "Canvas 调试数据",
            simpleExplanation: "仅用于预览", explanation: "仅用于预览", nextAction: "仅用于预览",
            fields: [], drivers: [], isProxy: false
        )
    }

    private func scoreControl(_ title: String, value: Binding<Int>, tint: Color) -> some View {
        Stepper(value: value, in: 0...100) {
            HStack {
                Text(title).font(.system(size: 15, weight: .bold))
                Spacer()
                Text("\(value.wrappedValue)").foregroundStyle(tint)
            }
            .foregroundStyle(Color(hex: "173F64"))
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(XAgeGlassCardBackground(cornerRadius: 16))
    }
}

#Preview("XAGE 样式组件") {
    XAgeStyleComponentsPreview()
}

#Preview("首页三评分调试") {
    XAgeScoreDashboardPreview()
}
#endif
