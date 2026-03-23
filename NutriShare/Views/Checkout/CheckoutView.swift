import SwiftUI

struct CheckoutView: View {
    let items: [CheckoutItem]

    @Environment(\.dismiss) var dismiss
    @State private var zipCode = ""
    @State private var addressLine1 = ""
    @State private var addressLine2 = ""
    @State private var isSubmitting = false
    @State private var toastMessage = ""
    @State private var completedOrderId: Int?
    @State private var showComplete = false

    private var totalAmount: Int {
        items.reduce(0) { $0 + $1.product.price * $1.quantity }
    }

    var body: some View {
        if showComplete, let orderId = completedOrderId {
            OrderCompleteView(orderId: orderId)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: NSSpacing.xl) {
                    // Order Items
                    sectionCard(title: "주문 상품 정보") {
                        ForEach(items) { item in
                            HStack {
                                Text(item.product.name)
                                    .font(.system(size: NSFont.base))
                                    .lineLimit(1)
                                Spacer()
                                Text("\(item.quantity)개")
                                    .font(.system(size: NSFont.sm))
                                    .foregroundColor(.nsTextSecondary)
                                PriceText(value: item.product.price * item.quantity, fontSize: NSFont.sm)
                            }
                            if item.id != items.last?.id {
                                Divider()
                            }
                        }
                    }

                    sectionCard(title: "배송 방식") {
                        HStack(spacing: NSSpacing.md) {
                            Image(systemName: "truck.box.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.nsPrimaryDark)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("배송")
                                    .font(.system(size: NSFont.sm, weight: .bold))
                                    .foregroundColor(.nsTextPrimary)
                                Text("입력한 주소로 배송됩니다.")
                                    .font(.system(size: NSFont.xs))
                                    .foregroundColor(.nsTextSecondary)
                            }

                            Spacer()
                        }
                        .padding(NSSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.nsPrimaryBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: NSRadius.md)
                                .stroke(Color.nsPrimary, lineWidth: 1.5)
                        )
                        .cornerRadius(NSRadius.md)
                    }

                    sectionCard(title: "배송지 입력") {
                        VStack(spacing: NSSpacing.md) {
                            HStack(spacing: NSSpacing.sm) {
                                TextField("우편번호", text: $zipCode)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 120)
                                Button("주소 찾기") {
                                    // Simulate address lookup
                                    zipCode = "06236"
                                    addressLine1 = "서울 강남구 테헤란로 152"
                                }
                                .font(.system(size: NSFont.sm, weight: .medium))
                                .foregroundColor(.nsPrimary)
                                .padding(.horizontal, NSSpacing.md)
                                .padding(.vertical, NSSpacing.sm)
                                .background(Color.nsGray100)
                                .cornerRadius(NSRadius.sm)
                            }
                            TextField("기본 주소", text: $addressLine1)
                                .textFieldStyle(.roundedBorder)
                            TextField("상세 주소를 입력해주세요", text: $addressLine2)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    // Summary
                    sectionCard(title: "주문 요약") {
                        VStack(spacing: NSSpacing.md) {
                            HStack {
                                Text("상품 총액").foregroundColor(.nsTextSecondary)
                                Spacer()
                                PriceText(value: totalAmount)
                            }
                            HStack {
                                Text("배송비").foregroundColor(.nsTextSecondary)
                                Spacer()
                                Text("무료 (공동구매 특가)")
                                    .font(.system(size: NSFont.sm))
                                    .foregroundColor(.nsSecondaryDark)
                            }
                            Divider()
                            HStack {
                                Text("예상 주문 금액")
                                    .font(.system(size: NSFont.md, weight: .bold))
                                Spacer()
                                PriceText(value: totalAmount, fontWeight: .bold, fontSize: NSFont.xl, color: .nsPrimaryDark)
                            }
                        }
                    }

                    sectionCard(title: "결제 안내") {
                        VStack(alignment: .leading, spacing: NSSpacing.sm) {
                            Text("주문 접수 후 가상결제(MOCK)로 자동 처리됩니다.")
                                .font(.system(size: NSFont.sm, weight: .semibold))
                                .foregroundColor(.nsTextPrimary)

                            Text("실제 카드 정보를 입력하지 않아도 주문 및 결제 흐름이 정상적으로 완료됩니다.")
                                .font(.system(size: NSFont.xs))
                                .foregroundColor(.nsTextSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    // Submit Button
                    Button(action: submitOrder) {
                        Text(isSubmitting ? "주문 접수 중..." : "\(totalAmount.formatted())원 주문 접수하기")
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
            .navigationTitle("주문")
            .navigationBarTitleDisplayMode(.inline)
            .toast($toastMessage)
        }
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: NSSpacing.md) {
            Text(title)
                .font(.system(size: NSFont.md, weight: .bold))
                .foregroundColor(.nsTextPrimary)
            content()
        }
        .padding(NSSpacing.base)
        .background(Color.nsSurface)
        .cornerRadius(NSRadius.lg)
    }

    private func submitOrder() {
        guard !zipCode.isEmpty, !addressLine1.isEmpty else {
            toastMessage = "주문에 사용할 배송지를 먼저 입력해주세요."
            return
        }

        isSubmitting = true
        let payload = OrderCreateRequest(
            shippingAddress: ShippingAddress(
                zipCode: zipCode,
                line1: addressLine1,
                line2: addressLine2
            ),
            items: items.map {
                OrderItemRequest(
                    productId: $0.product.id,
                    productName: $0.product.name,
                    unitPrice: $0.product.price,
                    quantity: $0.quantity
                )
            }
        )
        let amount = totalAmount

        Task {
            do {
                // 1. 주문 생성
                let orderResponse: ApiResponse<ResourceResponse> = try await APIService.shared.post("/orders", body: payload)
                guard let orderId = orderResponse.data?.resourceId else {
                    throw APIError.invalidResponse
                }

                // 2. 결제 확정 (MOCK)
                struct PaymentConfirmRequest: Encodable {
                    let orderId: Int
                    let amount: Int
                    let paymentProvider: String
                    let providerPaymentKey: String
                }
                let payKey = "MOCK-\(orderId)-\(Int(Date().timeIntervalSince1970))"
                let _: ApiResponse<ResourceResponse> = try await APIService.shared.post(
                    "/payments/confirm",
                    body: PaymentConfirmRequest(
                        orderId: orderId,
                        amount: amount,
                        paymentProvider: "MOCK",
                        providerPaymentKey: payKey
                    )
                )

                await MainActor.run {
                    completedOrderId = orderId
                    showComplete = true
                }
            } catch {
                print("Order/Payment failed: \(error)")
                await MainActor.run {
                    toastMessage = "주문 접수에 실패했습니다."
                }
            }
            await MainActor.run { isSubmitting = false }
        }
    }
}
