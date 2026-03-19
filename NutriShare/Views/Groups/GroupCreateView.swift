import SwiftUI
#Preview {
    GroupCreateView();
}
struct GroupCreateView: View {
    @Environment(\.dismiss) var dismiss

    // Form state
    @State private var selectedProductId: Int?
    @State private var title = ""
    @State private var targetQuantity = ""
    @State private var dueDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var discountPercent = 10.0
    @State private var isSubmitting = false
    @State private var toastMessage = ""

    // Products from API
    @State private var products: [Product] = []
    @State private var isLoadingProducts = true
    @State private var searchText = ""
    
    private var filteredProducts: [Product] {
        if searchText.isEmpty {
            return products
        } else {
            return products.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private var selectedProduct: Product? {
        products.first { $0.id == selectedProductId }
    }

    private var unitPrice: Int {
        guard let basePrice = selectedProduct?.price else { return 0 }
        let discountedPrice = Double(basePrice) * (1 - discountPercent / 100)
        return max(Int(discountedPrice.rounded()), 0)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: NSSpacing.xl) {
                Text("이웃과 나누고 싶은 생필품을 선택해 모집글을 작성해 보세요.")
                    .font(.system(size: NSFont.sm))
                    .foregroundColor(.nsTextSecondary)

                // MARK: - 1. Product Selection
                productSelectionSection

                // MARK: - 2. Pricing Preview (shown when product selected)
                if selectedProduct != nil {
                    pricingSection
                }

                // MARK: - 3. Title
                VStack(alignment: .leading, spacing: NSSpacing.sm) {
                    sectionLabel("모집 제목 (필수)")
                    TextField("예) 마트보다 싼 라면 1박스 같이 사실 분!", text: $title)
                        .textFieldStyle(.roundedBorder)
                }

                // MARK: - 4. Target & Due Date
                VStack(alignment: .leading, spacing: NSSpacing.md) {
                    sectionLabel("모집 조건")

                    VStack(alignment: .leading, spacing: NSSpacing.xs) {
                        Text("목표 인원")
                            .font(.system(size: NSFont.xs))
                            .foregroundColor(.nsTextSecondary)
                        TextField("최소 5명", text: $targetQuantity)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numberPad)
                    }

                    VStack(alignment: .leading, spacing: NSSpacing.xs) {
                        Text("모집 마감일")
                            .font(.system(size: NSFont.xs))
                            .foregroundColor(.nsTextSecondary)
                        DatePicker("", selection: $dueDate, in: Date()..., displayedComponents: .date)
                            .labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(NSSpacing.base)
                .background(Color.nsSurface)
                .cornerRadius(NSRadius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: NSRadius.lg)
                        .stroke(Color.nsBorder, lineWidth: 1)
                )

                // MARK: - 5. Summary Preview
                if let product = selectedProduct, !title.isEmpty {
                    summarySection(product)
                }

                // MARK: - 6. Guide
                VStack(alignment: .leading, spacing: NSSpacing.sm) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.nsPrimary)
                        Text("공동구매 주최 가이드")
                            .font(.system(size: NSFont.base, weight: .bold))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        guideRow("목표 인원을 달성해야만 공동구매 주문이 확정됩니다.")
                        guideRow("마감일 이전에 인원이 모두 모이면 즉시 결제가 진행될 수 있습니다.")
                        guideRow("부적절한 내용이나 목적과 맞지 않는 글은 무통보 삭제될 수 있습니다.")
                    }
                }
                .padding(NSSpacing.base)
                .background(Color.nsPrimaryBg.opacity(0.5))
                .cornerRadius(NSRadius.lg)

                // MARK: - Submit
                Button(action: submit) {
                    Text(isSubmitting ? "진행 중..." : "모집 시작하기")
                        .font(.system(size: NSFont.md, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, NSSpacing.md)
                        .background(isSubmitting ? Color.nsGray400 : Color.nsPrimary)
                        .cornerRadius(NSRadius.md)
                }
                .disabled(isSubmitting)
            }
            .padding(NSSpacing.base)
        }
        .background(Color.nsBg)
        .navigationTitle("공동구매 열기")
        .navigationBarTitleDisplayMode(.inline)
        .toast($toastMessage, type: .success)
        .task {
            await loadProducts()
        }
    }

    // MARK: - Product Selection Section
    private var productSelectionSection: some View {
        VStack(alignment: .leading, spacing: NSSpacing.sm) {
            
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.nsGray400)
                TextField("어떤 상품을 검색하시겠어요?", text: $searchText)
                    .font(.system(size: NSFont.sm))
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.nsGray400)
                    }
                }
            }
            .padding(10)
            .background(Color.nsSurface)
            .cornerRadius(NSRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: NSRadius.md)
                    .stroke(Color.nsBorder, lineWidth: 1)
            )
            .padding(.bottom, NSSpacing.xs)

            if isLoadingProducts {
                HStack { Spacer(); ProgressView(); Spacer() }
                    .padding(.vertical, NSSpacing.xl)
            } else if filteredProducts.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundColor(.nsGray300)
                    Text("검색 결과가 없습니다")
                        .font(.system(size: NSFont.sm))
                        .foregroundColor(.nsTextSecondary)

                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, NSSpacing.xl)
            } else {
                ForEach(filteredProducts) { product in
                    productRow(product)
                }
            }
        }
    }

    private func productRow(_ product: Product) -> some View {
        let isSelected = selectedProductId == product.id

        return Button(action: { withAnimation { selectedProductId = product.id } }) {
            HStack(spacing: NSSpacing.md) {
                // Product image
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    default:
                        Rectangle().fill(Color.nsGray100)
                            .overlay(Image(systemName: "photo.fill").foregroundColor(.nsGray300))
                    }
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: NSRadius.sm))

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    Text(product.name)
                        .font(.system(size: NSFont.sm, weight: .medium))
                        .foregroundColor(.nsTextPrimary)
                        .lineLimit(1)

                    Text("\(product.price.formatted())원")
                        .font(.system(size: NSFont.sm, weight: .bold))
                        .foregroundColor(.nsPrimaryDark)

                    if let stock = product.stockQuantity {
                        Text("재고 \(stock)개")
                            .font(.system(size: NSFont.xs))
                            .foregroundColor(stock > 0 ? .nsTextSecondary : .nsError)
                    }
                }

                Spacer()

                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .nsPrimary : .nsGray300)
            }
            .padding(NSSpacing.md)
            .background(isSelected ? Color.nsPrimaryBg.opacity(0.4) : Color.nsSurface)
            .cornerRadius(NSRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: NSRadius.md)
                    .stroke(isSelected ? Color.nsPrimary : Color.nsBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .onChange(of: selectedProductId) { newValue in
            if newValue != nil {
                discountPercent = 10.0
            }
        }
    }

    // MARK: - Pricing Section
    private var pricingSection: some View {
        VStack(spacing: NSSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("판매가")
                        .font(.system(size: NSFont.xs))
                        .foregroundColor(.nsTextSecondary)
                    Text("\(selectedProduct!.price.formatted())원")
                        .font(.system(size: NSFont.lg, weight: .bold))
                        .foregroundColor(.nsPrimaryDark)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("공동구매가")
                        .font(.system(size: NSFont.xs))
                        .foregroundColor(.nsTextSecondary)
                    Text("\(unitPrice.formatted())원")
                        .font(.system(size: NSFont.lg, weight: .bold))
                        .foregroundColor(.nsPrimaryDark)
                }
            }

            VStack(alignment: .leading, spacing: NSSpacing.xs) {
                HStack {
                    Text("할인율")
                        .font(.system(size: NSFont.sm, weight: .semibold))
                        .foregroundColor(.nsTextPrimary)
                    Spacer()
                    Text("\(Int(discountPercent))%")
                        .font(.system(size: NSFont.sm, weight: .bold))
                        .foregroundColor(.nsPrimary)
                }

                Slider(value: $discountPercent, in: 0...30, step: 1)
                    .tint(.nsPrimary)

                HStack {
                    Text("0%")
                    Spacer()
                    Text("15%")
                    Spacer()
                    Text("30%")
                }
                .font(.system(size: NSFont.xs))
                .foregroundColor(.nsTextSecondary)
            }
        }
        .padding(NSSpacing.base)
        .background(
            LinearGradient(
                colors: [.nsPrimaryBg.opacity(0.6), .nsSurface],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(NSRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: NSRadius.lg)
                .stroke(Color.nsPrimary.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Summary Section
    private func summarySection(_ product: Product) -> some View {
        VStack(alignment: .leading, spacing: NSSpacing.md) {
            HStack(spacing: 8) {
                Image(systemName: "list.bullet.clipboard")
                    .foregroundColor(.nsSecondaryDark)
                Text("모집 요약")
                    .font(.system(size: NSFont.base, weight: .bold))
            }

            VStack(spacing: NSSpacing.sm) {
                summaryRow("상품", product.name)
                summaryRow("모집 제목", title)
                summaryRow("공동구매가", "\(unitPrice.formatted())원")
                summaryRow("목표 인원", targetQuantity.isEmpty ? "미입력" : "\(targetQuantity)명")

                let formatter = DateFormatter()
                let _ = formatter.dateFormat = "yyyy년 M월 d일"
                summaryRow("마감일", formatter.string(from: dueDate))
            }
        }
        .padding(NSSpacing.base)
        .background(Color.nsSecondary.opacity(0.1))
        .cornerRadius(NSRadius.lg)
    }

    private func summaryRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.system(size: NSFont.sm))
                .foregroundColor(.nsTextSecondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.system(size: NSFont.sm, weight: .medium))
                .foregroundColor(.nsTextPrimary)
            Spacer()
        }
    }

    // MARK: - Helpers
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: NSFont.sm, weight: .semibold))
            .foregroundColor(.nsTextSecondary)
    }

    private func guideRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text("•")
                .foregroundColor(.nsTextSecondary)
            Text(text)
                .font(.system(size: NSFont.sm))
                .foregroundColor(.nsTextSecondary)
        }
    }

    // MARK: - Data
    private func loadProducts() async {
        isLoadingProducts = true
        do {
            let response: ApiResponse<PagedData<Product>> = try await APIService.shared.get(
                "/products",
                queryItems: [URLQueryItem(name: "size", value: "50")]
            )
            await MainActor.run {
                products = response.data?.content ?? []
            }
        } catch {
            print("Failed to load products: \(error)")
        }
        await MainActor.run { isLoadingProducts = false }
    }

    private func submit() {
        guard let productId = selectedProductId,
              !title.isEmpty,
              let qty = Int(targetQuantity), qty >= 1 else {
            toastMessage = "상품, 제목, 목표 인원을 모두 입력해주세요."
            return
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let endAtStr = dateFormatter.string(from: dueDate)

        isSubmitting = true
        Task {
            do {
                let payload = GroupCreateRequest(
                    productId: productId,
                    title: title,
                    targetQuantity: qty,
                    unitPrice: unitPrice,
                    endAt: endAtStr
                )
                let _: ApiResponse<ResourceResponse> = try await APIService.shared.post("/groups", body: payload)
                await MainActor.run {
                    toastMessage = "공동구매 모집이 시작되었습니다!"
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run { dismiss() }
            } catch {
                print("Failed to create group: \(error)")
                await MainActor.run { toastMessage = "공동구매 생성에 실패했습니다." }
            }
            await MainActor.run { isSubmitting = false }
        }
    }
}
