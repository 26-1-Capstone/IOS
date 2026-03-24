import SwiftUI
#Preview{
    MyPageView();
}

enum MyPageTab: Int {
    case orders
    case reviews
    case participations
}

struct MyPageView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var profile: UserProfile?
    @State private var orders: [OrderSummary] = []
    @State private var participations: [Participation] = []
    @State private var isLoading = true
    @State private var activeTab: MyPageTab = .orders
    @State private var reviewRatings: [Int: Int] = [:]
    @State private var reviewTexts: [Int: String] = [:]
    @State private var completedReviewParticipationIds: Set<Int> = []
    @State private var isSubmittingReview = false
    
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let profile = profile {
                ScrollView {
                    VStack(spacing: NSSpacing.xl) {
                        // Profile Header
                        profileHeader(profile)

                        // Savings card
                        savingsCard(profile)

                        // Tabs
                        tabSection

                        // Content
                        if activeTab == .orders {
                            ordersSection
                        } else if activeTab == .reviews {
                            reviewsSection
                        } else {
                            participationsSection
                        }

                        // Logout
                        Button(action: logout) {
                            Text("로그아웃")
                                .font(.system(size: NSFont.base))
                                .foregroundColor(.nsError)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, NSSpacing.md)
                        }
                        .padding(.top, NSSpacing.xl)
                    }
                    .padding(.bottom, NSSpacing.xxl)
                }
                .background(Color.nsBg)
                .navigationTitle("")
                .alert("안내", isPresented: $showingErrorAlert) {
                    Button("확인", role: .cancel) { }
                } message: {
                    Text(errorMessage)
                }
            } else {
                VStack(spacing: NSSpacing.base) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundColor(.nsTextPrimary)
                    Text("로그인이 필요해요")
                        .font(.system(size: NSFont.md, weight: .semibold))
                    Text("소셜 로그인 후 마이페이지를 이용할 수 있어요.")
                        .font(.system(size: NSFont.sm))
                        .foregroundColor(.nsTextSecondary)

                    Button(action: logout) {
                        Text("로그인 화면으로 이동")
                            .font(.system(size: NSFont.sm, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, NSSpacing.lg)
                            .padding(.vertical, NSSpacing.sm)
                            .background(Color.nsPrimary)
                            .cornerRadius(NSRadius.md)
                    }
                    .padding(.top, NSSpacing.sm)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            Task {
                await loadData()
            }
        }
    }

    // MARK: - Profile Header
    private func profileHeader(_ profile: UserProfile) -> some View {
        HStack(spacing: NSSpacing.base) {
            AsyncImage(url: URL(string: profile.profileImageUrl ?? "")) { image in
                image.resizable()
            } placeholder: {
                Circle()
                    .fill(Color.nsGray200)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.nsGray400)
                            .font(.system(size: 24))
                    )
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text("\(profile.nickname ?? "사용자")님")
                    .font(.system(size: NSFont.lg, weight: .bold))
                Text(profile.email ?? "")
                    .font(.system(size: NSFont.sm))
                    .foregroundColor(.nsTextSecondary)
                if let district = profile.address?.districtDisplay {
                    Text(district)
                        .font(.system(size: NSFont.xs, weight: .semibold))
                        .foregroundColor(.nsPrimaryDark)
                }
            }

            Spacer()

            NavigationLink(destination: ProfileEditView()) {
                Text("수정")
                    .font(.system(size: NSFont.sm, weight: .semibold))
                    .foregroundColor(.nsPrimary)
                    .padding(.horizontal, NSSpacing.base)
                    .padding(.vertical, NSSpacing.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: NSRadius.md)
                            .stroke(Color.nsPrimary, lineWidth: 1.5)
                    )
            }
        }
        .padding(NSSpacing.base)
    }

    // MARK: - Savings Card
    private func savingsCard(_ profile: UserProfile) -> some View {
        VStack(spacing: 4) {
            Text("이번 달 공동구매로 절약한 금액")
                .font(.system(size: NSFont.sm))
                .foregroundColor(.nsTextSecondary)
            Text("\((profile.totalSavings ?? 0).formatted())원")
                .font(.system(size: NSFont.xxl, weight: .bold))
                .foregroundColor(.nsPrimaryDark)
            Text("혼자 샀을 때보다 훨씬 이득이에요!")
                .font(.system(size: NSFont.xs))
                .foregroundColor(.nsTextSecondary)
        }
        .padding(NSSpacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [.nsPrimaryBg, .nsSurface],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(NSRadius.lg)
        .padding(.horizontal, NSSpacing.base)
    }

    // MARK: - Tabs
    private var tabSection: some View {
        HStack(spacing: 0) {
            tabButton("주문", tab: .orders)
            tabButton("리뷰", tab: .reviews)
            tabButton("참여공구", tab: .participations)
        }
        .background(Color.nsGray100)
        .cornerRadius(NSRadius.md)
        .padding(.horizontal, NSSpacing.base)
    }

    private func tabButton(_ label: String, tab: MyPageTab) -> some View {
        Button(action: { withAnimation { activeTab = tab } }) {
            Text(label)
                .font(.system(size: NSFont.xs, weight: activeTab == tab ? .bold : .medium))
                .foregroundColor(activeTab == tab ? .white : .nsTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, NSSpacing.md)
                .background(activeTab == tab ? Color.nsPrimary : Color.clear)
                .cornerRadius(NSRadius.md)
        }
    }

    // MARK: - Orders
    private var ordersSection: some View {
        VStack(spacing: NSSpacing.md) {
            if orders.isEmpty {
                Text("주문 내역이 없습니다.")
                    .font(.system(size: NSFont.sm))
                    .foregroundColor(.nsTextSecondary)
                    .padding(.vertical, NSSpacing.xxxl)
            } else {
                ForEach(orders) { order in
                    SwipeToCancelOrderCard(
                        order: order,
                        onCancel: {
                            Task {
                                await cancelOrder(orderId: order.orderId)
                            }
                        }
                    )
                }
            }
        }
        .padding(.horizontal, NSSpacing.base)
    }

    // MARK: - Reviews
    private var reviewsSection: some View {
        VStack(spacing: NSSpacing.md) {
            reviewSummaryCard

            if participations.isEmpty {
                EmptyStateView(
                    title: "작성할 리뷰가 없습니다.",
                    description: "공동구매에 참여하면 이곳에서 리뷰를 관리할 수 있어요."
                )
            } else {
                ForEach(participations) { p in
                    reviewCard(for: p)
                }
            }
        }
        .padding(.horizontal, NSSpacing.base)
    }

    private var reviewSummaryCard: some View {
        VStack(alignment: .leading, spacing: NSSpacing.sm) {
            Text("리뷰 관리")
                .font(.system(size: NSFont.base, weight: .bold))
                .foregroundColor(.nsTextPrimary)

            Text("참여한 공동구매의 리뷰를 남겨보세요.")
                .font(.system(size: NSFont.sm))
                .foregroundColor(.nsTextSecondary)

            HStack(spacing: NSSpacing.sm) {
                reviewStatPill(
                    title: "작성 가능",
                    value: participations.filter { !completedReviewParticipationIds.contains($0.participationId) }.count,
                    tint: .nsPrimary
                )
                reviewStatPill(
                    title: "작성 완료",
                    value: completedReviewParticipationIds.count,
                    tint: .nsSecondaryDark
                )
            }
        }
        .padding(NSSpacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.nsSurface)
        .cornerRadius(NSRadius.lg)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private func reviewCard(for participation: Participation) -> some View {
        let pid = participation.participationId
        let isCompleted = completedReviewParticipationIds.contains(pid)

        return VStack(alignment: .leading, spacing: NSSpacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(participation.title ?? participation.productName ?? "공동구매 상품")
                        .font(.system(size: NSFont.base, weight: .semibold))
                        .foregroundColor(.nsTextPrimary)
                    Text(participation.createdAt?.prefix(10).description ?? "")
                        .font(.system(size: NSFont.xs))
                        .foregroundColor(.nsTextSecondary)
                    if let status = participation.status {
                        Text("상태: \(status)")
                            .font(.system(size: NSFont.xs))
                            .foregroundColor(.nsTextDisabled)
                    }
                }
                Spacer()
                Text(isCompleted ? "작성 완료" : "작성 가능")
                    .font(.system(size: NSFont.xs, weight: .bold))
                    .foregroundColor(isCompleted ? .nsSecondaryDark : .nsPrimaryDark)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background((isCompleted ? Color.nsSecondary : Color.nsPrimary).opacity(0.18))
                    .cornerRadius(NSRadius.sm)
            }

            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { score in
                    Button(action: {
                        reviewRatings[pid] = score
                    }) {
                        Image(systemName: (reviewRatings[pid] ?? 0) >= score ? "star.fill" : "star")
                            .font(.system(size: 16))
                            .foregroundColor(.nsPrimary)
                    }
                    .buttonStyle(.plain)
                    .disabled(isCompleted)
                }
            }

            TextField(
                "상품은 만족스러웠나요? 후기를 남겨주세요.",
                text: Binding(
                    get: { reviewTexts[pid] ?? "" },
                    set: { reviewTexts[pid] = $0 }
                ),
                axis: .vertical
            )
            .lineLimit(3...5)
            .padding(NSSpacing.sm)
            .background(Color.nsGray100)
            .cornerRadius(NSRadius.sm)
            .disabled(isCompleted)

            HStack {
                Text(isCompleted ? "리뷰가 등록되었습니다." : "별점과 간단한 후기를 남겨보세요.")
                    .font(.system(size: NSFont.xs))
                    .foregroundColor(.nsTextSecondary)
                Spacer()
                if !isCompleted {
                    Button(action: {
                        submitReview(for: participation)
                    }) {
                        Text(isSubmittingReview ? "등록 중..." : "리뷰 등록")
                            .font(.system(size: NSFont.xs, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, NSSpacing.md)
                            .padding(.vertical, 7)
                            .background(isSubmittingReview ? Color.nsGray400 : Color.nsPrimary)
                            .cornerRadius(NSRadius.sm)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSubmittingReview)
                }
            }
        }
        .padding(NSSpacing.base)
        .background(Color.nsSurface)
        .cornerRadius(NSRadius.lg)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }

    private func reviewStatPill(title: String, value: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: NSFont.xs, weight: .medium))
                .foregroundColor(.nsTextSecondary)
            Text("\(value)건")
                .font(.system(size: NSFont.base, weight: .bold))
                .foregroundColor(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(NSSpacing.md)
        .background(tint.opacity(0.08))
        .cornerRadius(NSRadius.md)
    }

    // MARK: - Participations
    private var participationsSection: some View {
        VStack(spacing: NSSpacing.md) {
            if participations.isEmpty {
                Text("참여 내역이 없습니다.")
                    .font(.system(size: NSFont.sm))
                    .foregroundColor(.nsTextSecondary)
                    .padding(.vertical, NSSpacing.xxxl)
            } else {
                ForEach(participations) { p in
                    let groupId = p.groupPurchaseId ?? p.groupId ?? 0

                    NavigationLink(destination: GroupDetailView(groupId: groupId)) {
                        VStack(alignment: .leading, spacing: NSSpacing.sm) {
                            HStack {
                                Text(p.title ?? "참여한 공동구매 #\(groupId)")
                                    .font(.system(size: NSFont.base, weight: .medium))
                                    .foregroundColor(.nsTextPrimary)
                                Spacer()
                                if let status = p.status {
                                    StatusBadgeView(status: status)
                                }
                            }
                            Text(p.productName ?? "상품 정보를 불러오는 중이에요.")
                                .font(.system(size: NSFont.sm))
                                .foregroundColor(.nsTextSecondary)

                            HStack(spacing: NSSpacing.sm) {
                                if let quantity = p.quantity {
                                    Label("\(quantity)개 참여", systemImage: "person.fill.checkmark")
                                        .font(.system(size: NSFont.xs, weight: .medium))
                                        .foregroundColor(.nsPrimaryDark)
                                }

                                if let createdAt = p.createdAt {
                                    Text(createdAt.prefix(10))
                                        .font(.system(size: NSFont.xs))
                                        .foregroundColor(.nsTextDisabled)
                                }
                            }

                            if let current = p.currentQuantity, let target = p.targetQuantity {
                                HStack {
                                    Text("모집 상태: \(current) / \(target)명")
                                        .font(.system(size: NSFont.xs, weight: .medium))
                                        .foregroundColor(.nsPrimary)
                                    Spacer()
                                }
                            }
                        }
                        .padding(NSSpacing.base)
                        .background(Color.nsSurface)
                        .cornerRadius(NSRadius.lg)
                        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, NSSpacing.base)
    }

    private func loadData() async {
        isLoading = true
        do {
            let profileResponse: ApiResponse<UserProfile> = try await APIService.shared.get("/users/me")
            await MainActor.run { profile = profileResponse.data }

            async let ordersTask: ApiResponse<[OrderSummary]> = APIService.shared.get("/users/me/orders")
            async let participationsTask: ApiResponse<[Participation]> = APIService.shared.get("/users/me/participations")
            let (ordersRes, participationsRes) = try await (ordersTask, participationsTask)
            let participationItems = participationsRes.data ?? []

            // 백엔드가 이미 title, productName, currentQuantity, targetQuantity를 제공
            // 누락된 경우에만 enrichParticipations로 보완
            let needsEnrich = participationItems.contains { $0.title == nil || $0.productName == nil }
            let finalParticipations = needsEnrich ? await enrichParticipations(participationItems) : participationItems

            await MainActor.run {
                orders = ordersRes.data ?? []
                participations = finalParticipations

                // 백엔드에서 reviewed/reviewRating/reviewComment 제공 시 프리로드
                for p in finalParticipations {
                    if p.reviewed == true {
                        completedReviewParticipationIds.insert(p.participationId)
                    }
                    if let rating = p.reviewRating, rating > 0 {
                        reviewRatings[p.participationId] = rating
                    }
                    if let comment = p.reviewComment, !comment.isEmpty {
                        reviewTexts[p.participationId] = comment
                    }
                }
            }
        } catch {
            print("Failed to load mypage: \(error)")
        }
        await MainActor.run { isLoading = false }
    }

    private func submitReview(for participation: Participation) {
        let pid = participation.participationId

        guard (reviewRatings[pid] ?? 0) > 0 else {
            errorMessage = "별점을 선택해주세요."
            showingErrorAlert = true
            return
        }

        let trimmedText = (reviewTexts[pid] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            errorMessage = "리뷰 내용을 입력해주세요."
            showingErrorAlert = true
            return
        }

        struct ReviewUpsertRequest: Encodable {
            let participationId: Int
            let rating: Int
            let comment: String
        }

        isSubmittingReview = true
        Task {
            do {
                let _: ApiResponse<ResourceResponse> = try await APIService.shared.post(
                    "/users/me/reviews",
                    body: ReviewUpsertRequest(
                        participationId: pid,
                        rating: reviewRatings[pid]!,
                        comment: trimmedText
                    )
                )
                await MainActor.run {
                    completedReviewParticipationIds.insert(pid)
                }
            } catch {
                print("Failed to submit review: \(error)")
                await MainActor.run {
                    errorMessage = "리뷰 등록에 실패했습니다."
                    showingErrorAlert = true
                }
            }
            await MainActor.run { isSubmittingReview = false }
        }
    }

    private func cancelOrder(orderId: Int) async {
        do {
            let _: ApiResponse<ResourceResponse> = try await APIService.shared.post("/orders/\(orderId)/cancel")
            await MainActor.run {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                    if let index = orders.firstIndex(where: { $0.orderId == orderId }) {
                        let current = orders[index]
                        orders[index] = OrderSummary(
                            orderId: current.orderId,
                            status: "CANCELED",
                            totalAmount: current.totalAmount,
                            createdAt: current.createdAt,
                            orderDate: current.orderDate,
                            summary: current.summary
                        )
                    }
                }
            }
        } catch let error as APIError {
            await MainActor.run {
                switch error {
                case .serverError(400), .serverError(409):
                    errorMessage = "취소할 수 없는 주문입니다."
                case .serverError(let code):
                    errorMessage = "주문 취소 중 서버 오류가 발생했습니다. (코드: \(code))"
                case .unauthorized:
                    errorMessage = "로그인이 필요합니다."
                default:
                    errorMessage = error.localizedDescription
                }
                showingErrorAlert = true
            }
        } catch {
            print("Failed to cancel order: \(error)")
            await MainActor.run {
                errorMessage = "주문 취소 중 오류가 발생했습니다."
                showingErrorAlert = true
            }
        }
    }

    private func logout() {
        authManager.removeToken()
    }

    private func enrichParticipations(_ items: [Participation]) async -> [Participation] {
        let groupIds = Array(Set(items.compactMap { $0.groupPurchaseId ?? $0.groupId }))
        guard !groupIds.isEmpty else { return items }

        let details = await fetchGroupDetails(for: groupIds)

        return items.map { item in
            guard let groupId = item.groupPurchaseId ?? item.groupId,
                  let detail = details[groupId] else {
                return item
            }

            return Participation(
                participationId: item.participationId,
                groupPurchaseId: item.groupPurchaseId ?? groupId,
                groupId: item.groupId ?? groupId,
                title: item.title ?? detail.title,
                productName: item.productName ?? detail.productName,
                quantity: item.quantity,
                status: item.status,
                createdAt: item.createdAt,
                currentQuantity: item.currentQuantity ?? detail.currentQuantity,
                targetQuantity: item.targetQuantity ?? detail.targetQuantity,
                groupStatus: item.groupStatus,
                hostId: item.hostId,
                hostNickname: item.hostNickname,
                reviewEligible: item.reviewEligible,
                reviewed: item.reviewed,
                reviewRating: item.reviewRating,
                reviewComment: item.reviewComment
            )
        }
    }

    private func fetchGroupDetails(for groupIds: [Int]) async -> [Int: GroupPurchase] {
        await withTaskGroup(of: (Int, GroupPurchase?).self, returning: [Int: GroupPurchase].self) { group in
            for groupId in groupIds {
                group.addTask {
                    do {
                        let response: ApiResponse<GroupPurchase> = try await APIService.shared.get("/groups/\(groupId)")
                        return (groupId, response.data)
                    } catch {
                        print("Failed to load group detail \(groupId): \(error)")
                        return (groupId, nil)
                    }
                }
            }

            var details: [Int: GroupPurchase] = [:]
            for await (groupId, detail) in group {
                if let detail {
                    details[groupId] = detail
                }
            }
            return details
        }
    }
}

private struct SwipeToCancelOrderCard: View {
    let order: OrderSummary
    let onCancel: () -> Void

    @State private var dragOffset: CGFloat = 0
    private let actionThreshold: CGFloat = 96
    private let maxRevealOffset: CGFloat = 132

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: NSRadius.lg)
                .fill(isCancelable ? Color.nsWarning : Color.nsGray300)

            HStack(spacing: NSSpacing.sm) {
                Image(systemName: isCancelable ? "xmark.circle.fill" : "lock.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text(isCancelable ? "취소" : "취소 불가")
                    .font(.system(size: NSFont.sm, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.leading, NSSpacing.lg)
            .opacity(dragOffset > 12 ? 1 : 0)

            orderContent
                .offset(x: dragOffset)
        }
        .animation(.spring(response: 0.24, dampingFraction: 0.84), value: dragOffset)
        .gesture(
            DragGesture(minimumDistance: 12)
                .onChanged { value in
                    guard isCancelable else { return }
                    guard value.translation.width > 0,
                          abs(value.translation.width) > abs(value.translation.height) else {
                        return
                    }
                    dragOffset = min(value.translation.width, maxRevealOffset)
                }
                .onEnded { value in
                    guard isCancelable else {
                        dragOffset = 0
                        return
                    }
                    guard value.translation.width > 0,
                          abs(value.translation.width) > abs(value.translation.height) else {
                        dragOffset = 0
                        return
                    }

                    if value.translation.width >= actionThreshold {
                        dragOffset = maxRevealOffset
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                            onCancel()
                        }
                    } else {
                        dragOffset = 0
                    }
                }
        )
    }

    private var isCancelable: Bool {
        guard let status = order.status?.uppercased() else { return false }
        return status == "CREATED" || status == "PAYING"
    }

    private var orderContent: some View {
        VStack(alignment: .leading, spacing: NSSpacing.sm) {
            HStack {
                Text(order.orderDate ?? order.createdAt ?? "")
                    .font(.system(size: NSFont.xs))
                    .foregroundColor(.nsTextSecondary)
                Spacer()
                if let status = order.status {
                    StatusBadgeView(status: status)
                }
            }
            if let summary = order.summary {
                Text(summary)
                    .font(.system(size: NSFont.base, weight: .medium))
            }
            HStack {
                Spacer()
                PriceText(value: order.totalAmount, fontWeight: .bold, color: .nsPrimaryDark)
            }
            HStack {
                Text("주문번호: \(order.orderId)")
                    .font(.system(size: NSFont.xs))
                    .foregroundColor(.nsTextDisabled)
                Spacer()

            }
        }
        .padding(NSSpacing.base)
        .background(Color.nsSurface)
        .cornerRadius(NSRadius.lg)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}
