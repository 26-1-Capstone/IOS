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
    @State private var completedReviewOrderIds: Set<Int> = []
    
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
                    Text("🔐")
                        .font(.system(size: 48))
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

            if reviewableOrders.isEmpty {
                EmptyStateView(
                    title: "작성할 리뷰가 없습니다.",
                    description: "배송 완료된 주문이 생기면 이곳에서 리뷰를 관리할 수 있어요."
                )
            } else {
                ForEach(reviewableOrders) { order in
                    reviewCard(for: order)
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

            Text("배송 완료 주문만 리뷰를 남길 수 있어요.")
                .font(.system(size: NSFont.sm))
                .foregroundColor(.nsTextSecondary)

            HStack(spacing: NSSpacing.sm) {
                reviewStatPill(
                    title: "작성 가능",
                    value: reviewPendingOrders.count,
                    tint: .nsPrimary
                )
                reviewStatPill(
                    title: "작성 완료",
                    value: reviewCompletedOrders.count,
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

    private func reviewCard(for order: OrderSummary) -> some View {
        VStack(alignment: .leading, spacing: NSSpacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(order.summary ?? "주문 상품")
                        .font(.system(size: NSFont.base, weight: .semibold))
                        .foregroundColor(.nsTextPrimary)
                    Text(order.orderDate ?? order.createdAt ?? "")
                        .font(.system(size: NSFont.xs))
                        .foregroundColor(.nsTextSecondary)
                    Text("주문번호 \(order.orderId)")
                        .font(.system(size: NSFont.xs))
                        .foregroundColor(.nsTextDisabled)
                }
                Spacer()
                reviewStatusBadge(for: order)
            }

            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { score in
                    Button(action: {
                        reviewRatings[order.orderId] = score
                    }) {
                        Image(systemName: (reviewRatings[order.orderId] ?? 0) >= score ? "star.fill" : "star")
                            .font(.system(size: 16))
                            .foregroundColor(.nsPrimary)
                    }
                    .buttonStyle(.plain)
                }
            }

            TextField(
                "상품은 만족스러웠나요? 후기를 남겨주세요.",
                text: Binding(
                    get: { reviewTexts[order.orderId] ?? "" },
                    set: { reviewTexts[order.orderId] = $0 }
                ),
                axis: .vertical
            )
            .lineLimit(3...5)
            .padding(NSSpacing.sm)
            .background(Color.nsGray100)
            .cornerRadius(NSRadius.sm)

            HStack {
                if completedReviewOrderIds.contains(order.orderId) {
                    Text("현재는 앱 내부 임시 저장만 지원합니다.")
                        .font(.system(size: NSFont.xs))
                        .foregroundColor(.nsTextSecondary)
                } else {
                    Text("별점과 간단한 후기를 남겨보세요.")
                        .font(.system(size: NSFont.xs))
                        .foregroundColor(.nsTextSecondary)
                }
                Spacer()
                Button(action: {
                    submitReview(for: order)
                }) {
                    Text(completedReviewOrderIds.contains(order.orderId) ? "수정 저장" : "리뷰 등록")
                        .font(.system(size: NSFont.xs, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, NSSpacing.md)
                        .padding(.vertical, 7)
                        .background(Color.nsPrimary)
                        .cornerRadius(NSRadius.sm)
                }
                .buttonStyle(.plain)
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

    private func reviewStatusBadge(for order: OrderSummary) -> some View {
        let isCompleted = completedReviewOrderIds.contains(order.orderId)

        return Text(isCompleted ? "작성 완료" : "작성 가능")
            .font(.system(size: NSFont.xs, weight: .bold))
            .foregroundColor(isCompleted ? .nsSecondaryDark : .nsPrimaryDark)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((isCompleted ? Color.nsSecondary : Color.nsPrimary).opacity(0.18))
            .cornerRadius(NSRadius.sm)
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
                    NavigationLink(destination: GroupDetailView(groupId: p.groupPurchaseId ?? p.groupId ?? 0)) {
                        VStack(alignment: .leading, spacing: NSSpacing.sm) {
                            HStack {
                                Text(p.title ?? "")
                                    .font(.system(size: NSFont.base, weight: .medium))
                                    .foregroundColor(.nsTextPrimary)
                                Spacer()
                                if let status = p.status {
                                    StatusBadgeView(status: status)
                                }
                            }
                            if let productName = p.productName {
                                Text(productName)
                                    .font(.system(size: NSFont.sm))
                                    .foregroundColor(.nsTextSecondary)
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
            await MainActor.run {
                orders = ordersRes.data ?? []
                participations = participationsRes.data ?? []
            }
        } catch {
            print("Failed to load mypage: \(error)")
        }
        await MainActor.run { isLoading = false }
    }

    private var reviewableOrders: [OrderSummary] {
        orders.filter { isReviewEligible($0) }
    }

    private var reviewPendingOrders: [OrderSummary] {
        reviewableOrders.filter { !completedReviewOrderIds.contains($0.orderId) }
    }

    private var reviewCompletedOrders: [OrderSummary] {
        reviewableOrders.filter { completedReviewOrderIds.contains($0.orderId) }
    }

    private func isReviewEligible(_ order: OrderSummary) -> Bool {
        guard let status = order.status?.uppercased() else { return false }
        return status == "DELIVERED"
    }

    private func submitReview(for order: OrderSummary) {
        guard (reviewRatings[order.orderId] ?? 0) > 0 else {
            errorMessage = "별점을 선택해주세요."
            showingErrorAlert = true
            return
        }

        let trimmedText = (reviewTexts[order.orderId] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            errorMessage = "리뷰 내용을 입력해주세요."
            showingErrorAlert = true
            return
        }

        reviewTexts[order.orderId] = trimmedText
        completedReviewOrderIds.insert(order.orderId)
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
