import SwiftUI

struct OrderCompleteView: View {
    let orderId: Int

    var body: some View {
        VStack(spacing: NSSpacing.xl) {
            Spacer()

            // Success icon
            Image(systemName: "checkmark.circle")
                .font(.system(size: 72))
                .foregroundColor(.nsSecondary)

            Text("주문이 접수되었어요!")
                .font(.system(size: NSFont.xxl, weight: .bold))
                .foregroundColor(.nsTextPrimary)

            VStack(spacing: 4) {
                Text("주문 번호: \(orderId)")
                    .font(.system(size: NSFont.base, weight: .semibold))
                    .foregroundColor(.nsTextPrimary)
                Text("현재는 가상결제 기준으로 주문 흐름을 테스트하고 있습니다.")
                    .font(.system(size: NSFont.sm))
                    .foregroundColor(.nsTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: NSSpacing.md) {
                NavigationLink(destination: MyPageView()) {
                    Text("주문 내역 보기")
                        .font(.system(size: NSFont.base, weight: .semibold))
                        .foregroundColor(.nsPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, NSSpacing.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: NSRadius.md)
                                .stroke(Color.nsPrimary, lineWidth: 1.5)
                        )
                }

                NavigationLink(destination: HomeView()) {
                    Text("홈으로 돌아가기")
                        .font(.system(size: NSFont.base, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, NSSpacing.md)
                        .background(Color.nsPrimary)
                        .cornerRadius(NSRadius.md)
                }
            }
            .padding(.horizontal, NSSpacing.xl)
            .padding(.bottom, NSSpacing.xxl)
        }
        .frame(maxWidth: .infinity)
        .background(Color.nsSurface)
        .navigationBarBackButtonHidden(true)
    }
}
