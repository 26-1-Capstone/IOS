import SwiftUI

struct ProductDetailView: View {
    let productId: Int

    @State private var product: Product?
    @State private var isLoading = true
    @State private var quantity = 1
    @State private var toastMessage = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let product = product {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Product Image
                        AsyncImage(url: URL(string: product.imageUrl ?? "")) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fill)
                            default:
                                Rectangle()
                                    .fill(Color.nsGray100)
                                    .aspectRatio(1, contentMode: .fill)
                                    .overlay(
                                        Image(systemName: "leaf.fill")
                                            .font(.system(size: 48))
                                            .foregroundColor(.nsGray300)
                                    )
                            }
                        }

                        // Product Info
                        VStack(alignment: .leading, spacing: NSSpacing.base) {
                            if let category = product.categoryName {
                                Text(category)
                                    .font(.system(size: NSFont.xs, weight: .semibold))
                                    .foregroundColor(.nsPrimary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.nsPrimaryBg)
                                    .cornerRadius(NSRadius.sm)
                            }

                            Text(product.name)
                                .font(.system(size: NSFont.xxl, weight: .bold))
                                .foregroundColor(.nsTextPrimary)

                            PriceText(value: product.price, fontWeight: .bold, fontSize: NSFont.xxl, color: .nsPrimaryDark)

                            Divider()

                            Text("NutriShare 공동구매를 통해 더욱 저렴하게 만나보세요.\n신선하고 안전한 배송을 약속합니다.")
                                .font(.system(size: NSFont.sm))
                                .foregroundColor(.nsTextSecondary)

                            Divider()

                            // Quantity
                            let isSoldOut = product.stockQuantity == 0

                            HStack {
                                Text("수량")
                                    .font(.system(size: NSFont.base, weight: .medium))
                                Spacer()
                                if isSoldOut {
                                    Text("품절")
                                        .font(.system(size: NSFont.base, weight: .bold))
                                        .foregroundColor(.nsError)
                                } else {
                                    QuantitySelectorView(
                                        value: $quantity,
                                        max: product.stockQuantity ?? 99
                                    )
                                }
                            }

                            HStack {
                                Text("총 상품 금액")
                                    .font(.system(size: NSFont.md, weight: .medium))
                                Spacer()
                                PriceText(
                                    value: isSoldOut ? 0 : product.price * quantity,
                                    fontWeight: .bold,
                                    fontSize: NSFont.xl,
                                    color: .nsPrimaryDark
                                )
                            }
                            .padding(.top, NSSpacing.sm)
                        }
                        .padding(NSSpacing.xl)
                    }
                    .padding(.bottom, 100) // Space for bottom bar
                }

                // Bottom Action Bar
                bottomBar(product)
            } else {
                VStack(spacing: NSSpacing.base) {
                    Text("존재하지 않는 상품입니다.")
                        .font(.system(size: NSFont.md, weight: .semibold))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color.nsSurface)
        .navigationBarTitleDisplayMode(.inline)
        .toast($toastMessage, type: .success)
        .task {
            await loadProduct()
        }
    }

    private func bottomBar(_ product: Product) -> some View {
        let isSoldOut = product.stockQuantity == 0

        return HStack(spacing: NSSpacing.md) {
            Button(action: { addToCart() }) {
                Text("장바구니")
                    .font(.system(size: NSFont.base, weight: .semibold))
                    .foregroundColor(.nsPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, NSSpacing.md)
                    .background(Color.nsSurface)
                    .cornerRadius(NSRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: NSRadius.md)
                            .stroke(Color.nsPrimary, lineWidth: 1.5)
                    )
            }
            .disabled(isSoldOut)

            NavigationLink(destination: CheckoutView(items: [
                CheckoutItem(product: product, quantity: quantity)
            ])) {
                Text(isSoldOut ? "품절" : "바로 구매")
                    .font(.system(size: NSFont.base, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, NSSpacing.md)
                    .background(isSoldOut ? Color.nsGray400 : Color.nsPrimary)
                    .cornerRadius(NSRadius.md)
            }
            .disabled(isSoldOut)
        }
        .padding(.horizontal, NSSpacing.base)
        .padding(.vertical, NSSpacing.md)
        .background(
            Color.nsSurface
                .shadow(color: .black.opacity(0.08), radius: 8, y: -2)
        )
    }

    private func loadProduct() async {
        isLoading = true
        do {
            let response: ApiResponse<Product> = try await APIService.shared.get(
                "/products/\(productId)"
            )
            await MainActor.run {
                product = response.data
            }
        } catch {
            print("Failed to load product: \(error)")
        }
        await MainActor.run { isLoading = false }
    }

    private func addToCart() {
        guard AuthManager.shared.isAuthenticated else {
            toastMessage = "로그인이 필요합니다."
            return
        }

        Task {
            do {
                struct CartAddRequest: Encodable {
                    let productId: Int
                    let quantity: Int
                }
                let _: ApiResponse<ResourceResponse> = try await APIService.shared.post(
                    "/cart",
                    body: CartAddRequest(productId: productId, quantity: quantity)
                )
                await MainActor.run {
                    toastMessage = "장바구니에 \(quantity)개 담았습니다."
                }
            } catch {
                print("Failed to add to cart: \(error)")
                await MainActor.run {
                    toastMessage = "장바구니 추가에 실패했습니다."
                }
            }
        }
    }
}

/// Checkout item for passing between views
struct CheckoutItem: Identifiable {
    let id = UUID()
    let product: Product
    let quantity: Int
}
