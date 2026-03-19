import SwiftUI

struct GroupDetailView: View {
    let groupId: Int

    @State private var group: GroupPurchase?
    @State private var isLoading = true
    @State private var remainingText = ""
    @State private var quantity = 1
    @State private var toastMessage = ""

    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var isClosed: Bool {
        let status = group?.status?.uppercased()
        return status == "CLOSED" || remainingText == "마감" || (group?.currentQuantity ?? 0) >= (group?.targetQuantity ?? 1)
    }

    private var isClosingSoon: Bool {
        remainingText.contains("시간") || remainingText.contains("분")
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, NSSpacing.xxxl)
                } else if let group {
                    VStack(alignment: .leading, spacing: NSSpacing.lg) {
                        heroSection(group)
                        summaryCard(group)
                        descriptionCard(group)
                        noticeCard
                    }
                    .padding(NSSpacing.base)
                    .padding(.bottom, 120)
                } else {
                    EmptyStateView(
                        title: "공동구매 정보를 불러올 수 없습니다.",
                        description: "잠시 후 다시 시도해주세요."
                    )
                    .padding(.top, NSSpacing.xxxl)
                }
            }
            .background(Color.nsBg)

            if let group, !isLoading {
                bottomBar(group)
            }
        }
        .background(Color.nsBg)
        .navigationBarTitleDisplayMode(.inline)
        .toast($toastMessage, type: .info)
        .task {
            await loadGroupDetail()
        }
        .onReceive(timer) { _ in
            updateCountdown()
        }
    }

    private func heroSection(_ group: GroupPurchase) -> some View {
        VStack(alignment: .leading, spacing: NSSpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: NSSpacing.sm) {
                    if !remainingText.isEmpty {
                        Text(remainingText)
                            .font(.system(size: NSFont.xs, weight: .bold))
                            .foregroundColor(isClosed ? .nsTextSecondary : isClosingSoon ? .nsError : .nsTextSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isClosed ? Color.nsGray200 : isClosingSoon ? Color.nsError.opacity(0.12) : Color.nsGray100)
                            .cornerRadius(NSRadius.sm)
                    }

                    Text(group.title)
                        .font(.system(size: NSFont.xxxl, weight: .bold))
                        .foregroundColor(.nsTextPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(group.productName ?? "상품 정보 없음")
                        .font(.system(size: NSFont.base))
                        .foregroundColor(.nsTextSecondary)
                }

                Spacer()
            }

            HStack(spacing: NSSpacing.md) {
                ZStack {
                    AsyncImage(url: URL(string: group.imageUrl ?? "")) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(1, contentMode: .fill)
                        default:
                            RoundedRectangle(cornerRadius: NSRadius.lg)
                                .fill(Color.nsGray100)
                                .overlay(
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 34))
                                        .foregroundColor(.nsGray300)
                                )
                        }
                    }
                    .frame(width: 104, height: 104)
                    .clipShape(RoundedRectangle(cornerRadius: NSRadius.lg))

                    if isClosed {
                        RoundedRectangle(cornerRadius: NSRadius.lg)
                            .fill(Color.black.opacity(0.35))
                            .frame(width: 104, height: 104)

                        Text("CLOSED")
                            .font(.system(size: NSFont.sm, weight: .heavy))
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: NSSpacing.sm) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("공동구매가")
                            .font(.system(size: NSFont.xs))
                            .foregroundColor(.nsTextSecondary)
                        PriceText(
                            value: group.typePrice ?? 0,
                            fontWeight: .bold,
                            fontSize: NSFont.xxl,
                            color: .nsPrimary
                        )
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("현재 ")
                                .font(.system(size: NSFont.xs))
                                .foregroundColor(.nsTextSecondary)
                            + Text("\(group.currentQuantity)")
                                .font(.system(size: NSFont.xs, weight: .bold))
                                .foregroundColor(.nsPrimaryDark)
                            + Text("명 참여")
                                .font(.system(size: NSFont.xs))
                                .foregroundColor(.nsTextSecondary)

                            Spacer()

                            Text("목표 \(group.targetQuantity)명")
                                .font(.system(size: NSFont.xs))
                                .foregroundColor(.nsTextSecondary)
                        }

                        ProgressBarView(value: group.currentQuantity, max: group.targetQuantity, height: 10)
                    }
                }
            }
        }
        .padding(NSSpacing.lg)
        .background(
            LinearGradient(
                colors: [.nsPrimaryBg.opacity(0.7), .nsSurface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(NSRadius.xl)
    }

    private func summaryCard(_ group: GroupPurchase) -> some View {
        VStack(alignment: .leading, spacing: NSSpacing.md) {
            Text("공구 정보")
                .font(.system(size: NSFont.md, weight: .bold))
                .foregroundColor(.nsTextPrimary)

            HStack(spacing: NSSpacing.sm) {
                infoChip(title: "상태", value: statusText(for: group))
                infoChip(title: "달성률", value: "\(progressPercent(for: group))%")
            }

            VStack(spacing: NSSpacing.md) {
                detailRow(title: "상품", value: group.productName ?? "-")
                detailRow(title: "모집 인원", value: "\(group.currentQuantity) / \(group.targetQuantity)명")
                detailRow(title: "마감일", value: formattedDueDate(group))
                detailRow(title: "남은 시간", value: remainingText.isEmpty ? "-" : remainingText)
            }
        }
        .padding(NSSpacing.base)
        .background(Color.nsSurface)
        .cornerRadius(NSRadius.lg)
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
    }

    private func descriptionCard(_ group: GroupPurchase) -> some View {
        VStack(alignment: .leading, spacing: NSSpacing.sm) {
            Text("설명")
                .font(.system(size: NSFont.md, weight: .bold))
                .foregroundColor(.nsTextPrimary)

            Text(group.description?.isEmpty == false ? group.description! : "작성된 설명이 없습니다.")
                .font(.system(size: NSFont.sm))
                .foregroundColor(.nsTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(NSSpacing.base)
        .background(Color.nsSurface)
        .cornerRadius(NSRadius.lg)
        .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
    }

    private var noticeCard: some View {
        VStack(alignment: .leading, spacing: NSSpacing.sm) {
            Text("안내")
                .font(.system(size: NSFont.md, weight: .bold))
                .foregroundColor(.nsTextPrimary)

            noticeRow("목표 인원 달성 시 공동구매가 확정됩니다.")
            noticeRow("마감 직전에는 참여 인원이 빠르게 변동될 수 있습니다.")
            noticeRow("이미지와 실제 상품 구성은 판매처 사정에 따라 달라질 수 있습니다.")
        }
        .padding(NSSpacing.base)
        .background(Color.nsPrimaryBg.opacity(0.45))
        .cornerRadius(NSRadius.lg)
    }

    private func bottomBar(_ group: GroupPurchase) -> some View {
        VStack(spacing: NSSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("예상 결제 금액")
                        .font(.system(size: NSFont.xs))
                        .foregroundColor(.nsTextSecondary)
                    PriceText(value: (group.typePrice ?? 0) * quantity, fontWeight: .bold, fontSize: NSFont.lg, color: .nsTextPrimary)
                }

                Spacer()

                QuantitySelectorView(value: $quantity, min: 1, max: max(1, group.targetQuantity - group.currentQuantity))
            }

            Button(action: handleJoinTap) {
                Text(isClosed ? "마감된 공동구매" : "이 공동구매 참여하기")
                    .font(.system(size: NSFont.base, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, NSSpacing.md)
                    .background(isClosed ? Color.nsGray400 : Color.nsPrimary)
                    .cornerRadius(NSRadius.md)
            }
            .disabled(isClosed)
        }
        .padding(.horizontal, NSSpacing.base)
        .padding(.top, NSSpacing.md)
        .padding(.bottom, NSSpacing.lg)
        .background(
            Color.nsSurface
                .shadow(color: .black.opacity(0.08), radius: 10, y: -2)
        )
    }

    private func infoChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: NSFont.xs))
                .foregroundColor(.nsTextSecondary)
            Text(value)
                .font(.system(size: NSFont.sm, weight: .bold))
                .foregroundColor(.nsTextPrimary)
        }
        .padding(.horizontal, NSSpacing.md)
        .padding(.vertical, NSSpacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.nsGray100)
        .cornerRadius(NSRadius.md)
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.system(size: NSFont.sm, weight: .semibold))
                .foregroundColor(.nsTextDisabled)
                .frame(width: 72, alignment: .leading)

            Text(value)
                .font(.system(size: NSFont.sm))
                .foregroundColor(.nsTextPrimary)

            Spacer()
        }
    }

    private func noticeRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .foregroundColor(.nsTextSecondary)
            Text(text)
                .font(.system(size: NSFont.sm))
                .foregroundColor(.nsTextSecondary)
        }
    }

    private func progressPercent(for group: GroupPurchase) -> Int {
        guard group.targetQuantity > 0 else { return 0 }
        return min(Int((Double(group.currentQuantity) / Double(group.targetQuantity) * 100).rounded()), 100)
    }

    private func formattedDueDate(_ group: GroupPurchase) -> String {
        let raw = group.endAt ?? group.dueDate ?? ""
        guard !raw.isEmpty else { return "-" }

        let parser = ISO8601DateFormatter()
        if let date = parser.date(from: raw) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = "M월 d일 a h:mm"
            return formatter.string(from: date)
        }

        return raw
    }

    private func statusText(for group: GroupPurchase) -> String {
        switch group.status?.uppercased() {
        case "OPEN": return "모집 중"
        case "CLOSED": return "모집 완료"
        default: return group.status ?? "-"
        }
    }

    private func handleJoinTap() {
        toastMessage = "참여 기능은 아직 연결 중입니다."
    }

    private func updateCountdown() {
        guard let rawDate = group?.endAt ?? group?.dueDate else {
            remainingText = ""
            return
        }

        let parser = ISO8601DateFormatter()
        guard let endDate = parser.date(from: rawDate) else {
            remainingText = ""
            return
        }

        let remaining = Int(endDate.timeIntervalSinceNow)
        if remaining <= 0 {
            remainingText = "마감"
            return
        }

        let days = remaining / 86_400
        let hours = (remaining % 86_400) / 3_600
        let minutes = (remaining % 3_600) / 60

        if days > 0 {
            remainingText = "\(days)일 남음"
        } else if hours > 0 {
            remainingText = "\(hours)시간 \(minutes)분 남음"
        } else {
            remainingText = "\(max(minutes, 1))분 남음"
        }
    }

    @MainActor
    private func loadGroupDetail() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: ApiResponse<GroupPurchase> = try await APIService.shared.get("/groups/\(groupId)")
            group = response.data
            quantity = 1
            updateCountdown()
        } catch {
            print("Failed to load group detail: \(error)")
            group = nil
        }
    }
}
