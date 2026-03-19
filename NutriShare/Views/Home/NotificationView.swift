import SwiftUI

struct NotificationView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: NSSpacing.md) {
                notificationRow(
                    icon: "bell.badge.fill",
                    color: .nsPrimary,
                    title: "내가 찜한 상품의 공구가 열렸어요!",
                    time: "방금 전",
                    message: "'제주 삼다수 2L 12병' 공동구매가 방금 시작되었습니다. 지금 바로 참여해보세요."
                )
                
                notificationRow(
                    icon: "person.2.fill",
                    color: .nsSecondaryDark,
                    title: "공구 인원이 다 찼어요 🎉",
                    time: "1시간 전",
                    message: "참여하신 '진라면 매운맛 1박스' 공구의 목표 인원이 달성되어 결제가 진행됩니다."
                )
                
                notificationRow(
                    icon: "clock.fill",
                    color: .nsError,
                    title: "공구 마감 임박!",
                    time: "3시간 전",
                    message: "'크리넥스 3겹 화장지' 공구가 1시간 뒤에 마감됩니다. 아직 구매하지 않으셨다면 서둘러주세요!"
                )
            }
            .padding(NSSpacing.base)
        }
        .background(Color.nsBg)
        .navigationTitle("알림")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func notificationRow(icon: String, color: Color, title: String, time: String, message: String) -> some View {
        HStack(alignment: .top, spacing: NSSpacing.md) {
            Circle()
                .fill(color.opacity(0.1))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(color)
                        .font(.system(size: 20))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: NSFont.sm, weight: .bold))
                        .foregroundColor(.nsTextPrimary)
                    Spacer()
                    Text(time)
                        .font(.system(size: NSFont.xs))
                        .foregroundColor(.nsTextDisabled)
                }
                
                Text(message)
                    .font(.system(size: NSFont.sm))
                    .foregroundColor(.nsTextSecondary)
                    .lineSpacing(4)
            }
        }
        .padding(NSSpacing.base)
        .background(Color.nsSurface)
        .cornerRadius(NSRadius.lg)
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}

#Preview {
    NavigationView {
        NotificationView()
    }
}
