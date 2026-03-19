import SwiftUI

/// Format price in Korean Won
struct PriceText: View {
    let value: Int
    var fontWeight: Font.Weight = .semibold
    var fontSize: CGFloat = NSFont.base
    var color: Color = .nsTextPrimary

    var body: some View {
        Text("\(value.formatted())원")
            .font(.system(size: fontSize, weight: fontWeight))
            .foregroundColor(color)
    }
}

/// Quantity Selector (+/-) component
struct QuantitySelectorView: View {
    @Binding var value: Int
    var min: Int = 1
    var max: Int = 99
    var onChange: ((Int) -> Void)?

    var body: some View {
        HStack(spacing: 0) {
            Button {
                if value > min {
                    value -= 1
                    onChange?(value)
                }
            } label: {
                Image(systemName: "minus")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 36, height: 36)
                    .foregroundColor(value <= min ? .nsGray400 : .nsTextPrimary)
            }
            .disabled(value <= min)

            Text("\(value)")
                .font(.system(size: NSFont.base, weight: .semibold))
                .frame(minWidth: 40)
                .multilineTextAlignment(.center)

            Button {
                if value < max {
                    value += 1
                    onChange?(value)
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 36, height: 36)
                    .foregroundColor(value >= max ? .nsGray400 : .nsTextPrimary)
            }
            .disabled(value >= max)
        }
        .background(Color.nsGray100)
        .cornerRadius(NSRadius.sm)
    }
}

/// Progress bar component
struct ProgressBarView: View {
    let value: Int
    let max: Int
    var height: CGFloat = 8

    private var progress: Double {
        guard max > 0 else { return 0 }
        return Swift.min(Double(value) / Double(max), 1.0)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.nsGray200)
                    .frame(height: height)

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(
                        LinearGradient(
                            colors: [.nsPrimary, .nsPrimaryLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * progress, height: height)
                    .animation(.easeOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: height)
    }
}

/// Status badge component
struct StatusBadgeView: View {
    let status: String

    private var displayText: String {
        switch status.uppercased() {
        // Order
        case "CREATED": return "결제 대기"
        case "PAYING": return "결제 진행중"
        case "PAID": return "결제 완료"
        case "SHIPPED": return "배송중"
        case "DELIVERED": return "배송완료"
        // GroupPurchase
        case "OPEN": return "모집 중"
        case "CLOSED": return "모집 완료"
        // Participation
        case "REQUESTED": return "참여 요청"
        case "ACCEPTED": return "참여 확정"
        case "ORDERED": return "주문 완료"
        // General
        case "CANCELED", "CANCELLED": return "취소"
        default: return status
        }
    }

    private var backgroundColor: Color {
        switch status.uppercased() {
        case "OPEN", "ACTIVE": return .nsSecondary.opacity(0.2)
        case "CREATED", "PAYING", "REQUESTED": return .nsPrimary.opacity(0.2)
        case "PAID", "ACCEPTED", "ORDERED": return .nsSecondaryDark.opacity(0.2)
        case "SHIPPED": return .nsInfo.opacity(0.2)
        case "DELIVERED", "CLOSED", "COMPLETED": return .nsGray200
        case "CANCELED", "CANCELLED": return .nsError.opacity(0.2)
        default: return .nsGray200
        }
    }

    private var textColor: Color {
        switch status.uppercased() {
        case "OPEN", "ACTIVE": return .nsSecondaryDark
        case "CREATED", "PAYING", "REQUESTED": return .nsPrimaryDark
        case "PAID", "ACCEPTED", "ORDERED": return .nsSecondaryDark
        case "SHIPPED": return .nsInfo
        case "CANCELED", "CANCELLED": return .nsError
        default: return .nsTextSecondary
        }
    }

    var body: some View {
        Text(displayText)
            .font(.system(size: NSFont.xs, weight: .semibold))
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .cornerRadius(NSRadius.sm)
    }
}

/// Empty state placeholder
struct EmptyStateView: View {
    let title: String
    var description: String?
    var actionLabel: String?
    var onAction: (() -> Void)?

    var body: some View {
        VStack(spacing: NSSpacing.base) {
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.nsGray400)

            Text(title)
                .font(.system(size: NSFont.md, weight: .semibold))
                .foregroundColor(.nsTextPrimary)
                .multilineTextAlignment(.center)

            if let description = description {
                Text(description)
                    .font(.system(size: NSFont.sm))
                    .foregroundColor(.nsTextSecondary)
                    .multilineTextAlignment(.center)
            }

            if let label = actionLabel, let action = onAction {
                Button(action: action) {
                    Text(label)
                        .font(.system(size: NSFont.base, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, NSSpacing.xl)
                        .padding(.vertical, NSSpacing.md)
                        .background(Color.nsPrimary)
                        .cornerRadius(NSRadius.md)
                }
            }
        }
        .padding(NSSpacing.xxxl)
        .frame(maxWidth: .infinity)
    }
}

/// Toast notification overlay
struct ToastView: View {
    let message: String
    var type: ToastType = .info

    enum ToastType {
        case info, success, error
    }

    private var bgColor: Color {
        switch type {
        case .info: return .nsGray800
        case .success: return .nsSecondaryDark
        case .error: return .nsError
        }
    }

    var body: some View {
        Text(message)
            .font(.system(size: NSFont.sm, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, NSSpacing.lg)
            .padding(.vertical, NSSpacing.md)
            .background(bgColor)
            .cornerRadius(NSRadius.lg)
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }
}

/// Toast modifier for easy usage
struct ToastModifier: ViewModifier {
    @Binding var message: String
    var type: ToastView.ToastType = .info

    func body(content: Content) -> some View {
        ZStack(alignment: .bottom) {
            content
            if !message.isEmpty {
                ToastView(message: message, type: type)
                    .padding(.bottom, 100)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation { message = "" }
                        }
                    }
            }
        }
        .animation(.spring(), value: message)
    }
}

extension View {
    func toast(_ message: Binding<String>, type: ToastView.ToastType = .info) -> some View {
        modifier(ToastModifier(message: message, type: type))
    }
}
