import SwiftUI
#Preview{
    CartView();
}
struct CartView: View {
    @State private var cartItems: [CartItem] = []
    @State private var totalAmount = 0
    @State private var isLoading = true
    @State private var toastMessage = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if cartItems.isEmpty {
                EmptyStateView(
                    title: "장바구니가 비어있습니다",
                    actionLabel: "쇼핑하러 가기"
                )
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        // Cart Items
                        ForEach(cartItems) { item in
                            cartItemRow(item)
                            Divider()
                                .padding(.horizontal, NSSpacing.base)
                        }

                        // Summary
                        VStack(spacing: NSSpacing.md) {
                            HStack {
                                Text("상품 금액")
                                    .foregroundColor(.nsTextSecondary)
                                Spacer()
                                PriceText(value: totalAmount)
                            }
                            HStack {
                                Text("배송비")
                                    .foregroundColor(.nsTextSecondary)
                                Spacer()
                                Text("무료")
                                    .font(.system(size: NSFont.base, weight: .medium))
                                    .foregroundColor(.nsSecondaryDark)
                            }
                            Divider()
                            HStack {
                                Text("결제 예상 금액")
                                    .font(.system(size: NSFont.md, weight: .bold))
                                Spacer()
                                PriceText(value: totalAmount, fontWeight: .bold, fontSize: NSFont.xl, color: .nsPrimaryDark)
                            }
                        }
                        .padding(NSSpacing.xl)
                        .background(Color.nsGray50)
                        .cornerRadius(NSRadius.lg)
                        .padding(NSSpacing.base)

                        Spacer().frame(height: 100)
                    }
                }

                // Checkout Button
                NavigationLink(destination: CheckoutView(
                    items: cartItems.map { item in
                        CheckoutItem(
                            product: Product(
                                id: item.productId,
                                name: item.productName,
                                price: item.typePrice,
                                categoryName: nil,
                                description: nil,
                                stockQuantity: nil,
                                categoryId: nil,
                                imageUrl: nil
                            ),
                            quantity: item.quantity
                        )
                    }
                )) {
                    Text("주문하기")
                        .font(.system(size: NSFont.md, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, NSSpacing.md)
                        .background(Color.nsPrimary)
                        .cornerRadius(NSRadius.md)
                }
                .padding(.horizontal, NSSpacing.base)
                .padding(.vertical, NSSpacing.md)
                .background(Color.nsSurface)
            }
        }
        .background(Color.nsBg)
        .navigationTitle("장바구니")
        .navigationBarTitleDisplayMode(.inline)
        .toast($toastMessage)
        .task {
            await loadCart()
        }
    }

    private func cartItemRow(_ item: CartItem) -> some View {
        HStack(alignment: .top, spacing: NSSpacing.md) {
            // Product Image
            AsyncImage(url: URL(string: item.imageUrl ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(1, contentMode: .fill)
                case .failure(_):
                    fallbackImage
                default:
                    Rectangle()
                        .fill(Color.nsGray100)
                        .overlay(ProgressView())
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: NSRadius.sm))

            VStack(alignment: .leading, spacing: NSSpacing.sm) {
                HStack {
                    Text(item.productName)
                        .font(.system(size: NSFont.base, weight: .medium))
                        .lineLimit(2)
                    Spacer()
                    Button(action: { removeItem(item.productId) }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14))
                            .foregroundColor(.nsGray500)
                    }
                }

                PriceText(value: item.typePrice, fontSize: NSFont.sm, color: .nsTextSecondary)

                HStack {
                    // Inline quantity controls
                    HStack(spacing: 0) {
                        Button {
                            if item.quantity > 1 {
                                updateQuantity(item.productId, item.quantity - 1)
                            }
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 12, weight: .bold))
                                .frame(width: 30, height: 30)
                                .foregroundColor(.nsTextPrimary)
                        }

                        Text("\(item.quantity)")
                            .font(.system(size: NSFont.sm, weight: .semibold))
                            .frame(minWidth: 32)

                        Button {
                            updateQuantity(item.productId, item.quantity + 1)
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .frame(width: 30, height: 30)
                                .foregroundColor(.nsTextPrimary)
                        }
                    }
                    .background(Color.nsGray100)
                    .cornerRadius(NSRadius.sm)

                    Spacer()

                    PriceText(value: item.totalPrice, fontWeight: .bold, color: .nsPrimaryDark)
                }
            }
        }
        .padding(NSSpacing.base)
    }

    private func loadCart() async {
        isLoading = true
        do {
            let response: ApiResponse<CartData> = try await APIService.shared.get("/cart")
            await MainActor.run {
                cartItems = response.data?.items ?? []
                totalAmount = response.data?.totalAmount ?? 0
            }
        } catch {
            print("Failed to load cart: \(error)")
        }
        await MainActor.run { isLoading = false }
    }

    private func updateQuantity(_ productId: Int, _ newQuantity: Int) {
        struct QtyUpdate: Encodable { let quantity: Int }
        Task {
            do {
                let _: ApiResponse<ResourceResponse> = try await APIService.shared.put(
                    "/cart/\(productId)",
                    body: QtyUpdate(quantity: newQuantity)
                )
                await loadCart()
            } catch {
                print("Failed to update quantity: \(error)")
            }
        }
    }

    private func removeItem(_ productId: Int) {
        Task {
            do {
                let _: ApiResponse<ResourceResponse> = try await APIService.shared.delete("/cart/\(productId)")
                await loadCart()
            } catch {
                print("Failed to remove item: \(error)")
            }
        }
    }

    private var fallbackImage: some View {
        Rectangle()
            .fill(Color.nsGray100)
            .frame(width: 80, height: 80)
            .overlay(
                Image(systemName: "photo.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.nsGray300)
            )
    }
}
