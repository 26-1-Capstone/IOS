import SwiftUI

/// Product card used in home & search grids
struct ProductCardView: View {
    let product: Product
    @EnvironmentObject private var cartStore: CartStore
    @EnvironmentObject private var wishlistStore: WishlistStore

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack(alignment: .topLeading) {
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { phase in
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
                            .aspectRatio(1, contentMode: .fill)
                            .overlay(ProgressView())
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: NSRadius.md))

                if let category = product.categoryName, !category.isEmpty {
                    Text(category)
                        .font(.system(size: NSFont.xs, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(NSRadius.sm)
                        .padding(8)
                }
                
                // Favorite Button
                VStack {
                    HStack {
                        Spacer()
                        let isFav = wishlistStore.contains(StoreProduct(id: product.id))
                        Image(systemName: isFav ? "heart.fill" : "heart")
                            .font(.system(size: 20))
                            .foregroundColor(isFav ? .nsError : .white)
                            .shadow(radius: 2, y: 1)
                            .padding(8)
                            .onTapGesture {
                                wishlistStore.toggle(StoreProduct(id: product.id))
                            }
                    }
                    Spacer()
                }
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: NSFont.sm, weight: .medium))
                    .foregroundColor(.nsTextPrimary)
                    .lineLimit(2)

                // Rating & Review Info
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                    Text("4.8")
                        .font(.system(size: NSFont.xs, weight: .bold))
                        .foregroundColor(.nsTextPrimary)
                    Text("(124)")
                        .font(.system(size: NSFont.xs))
                        .foregroundColor(.nsTextSecondary)
                }

                HStack {
                    PriceText(value: product.price, fontWeight: .bold, fontSize: NSFont.md, color: .nsPrimaryDark)
                    
                    Spacer()
                    
                    // Add to Cart Button
                    let inCart = cartStore.contains(StoreProduct(id: product.id))
                    Image(systemName: inCart ? "cart.fill" : "cart.badge.plus")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.nsPrimary) // Always primary blue
                        .clipShape(Circle())
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                cartStore.add(StoreProduct(id: product.id))
                            }
                        }
                }
            }
            .padding(.vertical, NSSpacing.sm)
        }
    }

    private var fallbackImage: some View {
        Rectangle()
            .fill(Color.nsGray100)
            .aspectRatio(1, contentMode: .fill)
            .overlay(
                Image(systemName: "photo.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.nsGray300)
            )
    }
}

/// Group buying card used in group list
struct GroupBuyingCardView: View {
    let group: GroupPurchase
    
    @State private var remainingText = ""
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var isClosed: Bool {
        let status = group.status?.uppercased()
        return status == "CLOSED" || remainingText == "마감" || group.currentQuantity >= group.targetQuantity
    }

    private var isClosingSoon: Bool {
        return remainingText.contains("시간") || remainingText.contains("분")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NSSpacing.md) {
            // Header
            HStack(alignment: .top) {
                Text(group.title)
                    .font(.system(size: NSFont.md, weight: .semibold))
                    .foregroundColor(isClosed ? .nsTextSecondary : .nsTextPrimary)
                    .lineLimit(2)
                
                Spacer()
                
                if !remainingText.isEmpty {
                    Text(remainingText)
                        .font(.system(size: NSFont.xs, weight: .bold))
                        .foregroundColor(isClosed ? .nsTextSecondary : isClosingSoon ? .nsError : .nsTextSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isClosed ? Color.nsGray200 : isClosingSoon ? Color.nsError.opacity(0.1) : Color.nsGray100)
                        .cornerRadius(NSRadius.sm)
                }
            }

            // Product & Price Layout
            HStack(alignment: .center, spacing: NSSpacing.md) {
                // Product Image
                ZStack {
                    AsyncImage(url: URL(string: group.imageUrl ?? "")) { phase in
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
                                .aspectRatio(1, contentMode: .fill)
                                .overlay(ProgressView())
                        }
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: NSRadius.sm))

                    if isClosed {
                        RoundedRectangle(cornerRadius: NSRadius.sm)
                            .fill(Color.black.opacity(0.35))
                            .frame(width: 60, height: 60)

                        Text("SOLD\nOUT")
                            .font(.system(size: 10, weight: .heavy))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                    }
                }
                
                // Product Name & Price
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.productName ?? "")
                        .font(.system(size: NSFont.sm))
                        .foregroundColor(isClosed ? .nsTextDisabled : .nsTextSecondary)
                        .lineLimit(1)
    
                    HStack {
                        Text("공동구매가")
                            .font(.system(size: NSFont.sm))
                            .foregroundColor(isClosed ? .nsTextDisabled : .nsTextSecondary)
                        PriceText(
                            value: group.typePrice ?? 0,
                            fontWeight: .bold,
                            fontSize: NSFont.lg,
                            color: isClosed ? .nsTextSecondary : .nsPrimary
                        )
                    }
                }
                
                Spacer()
            }

            // Progress
            VStack(spacing: 6) {
                HStack {
                    Text("현재 ")
                        .font(.system(size: NSFont.xs))
                        .foregroundColor(isClosed ? .nsTextDisabled : .nsTextSecondary)
                    + Text("\(group.currentQuantity)")
                        .font(.system(size: NSFont.xs, weight: .bold))
                        .foregroundColor(isClosed ? .nsTextSecondary : .nsPrimaryDark)
                    + Text("명 참여")
                        .font(.system(size: NSFont.xs))
                        .foregroundColor(isClosed ? .nsTextDisabled : .nsTextSecondary)

                    Spacer()

                    Text("목표 \(group.targetQuantity)명")
                        .font(.system(size: NSFont.xs))
                        .foregroundColor(isClosed ? .nsTextDisabled : .nsTextSecondary)
                }

                ProgressBarView(value: group.currentQuantity, max: group.targetQuantity)
            }
        }
        .padding(NSSpacing.base)
        .background(isClosed ? Color.nsGray100 : Color.nsSurface)
        .cornerRadius(NSRadius.lg)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
        .opacity(isClosed ? 0.92 : 1)
        .onAppear {
            updateCountdown()
        }
        .onReceive(timer) { _ in
            updateCountdown()
        }
    }
    
    private func updateCountdown() {
        guard let endStr = group.endAt ?? group.dueDate else {
            remainingText = "마감"
            return
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let altFormatter = DateFormatter()
        altFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"

        guard let endDate = formatter.date(from: endStr) ?? altFormatter.date(from: endStr) else {
            remainingText = "마감"
            return
        }

        let diff = endDate.timeIntervalSinceNow
        if diff <= 0 {
            remainingText = "마감"
            return
        }

        let days = Int(diff / (60 * 60 * 24))
        let hours = Int(diff.truncatingRemainder(dividingBy: 60 * 60 * 24) / (60 * 60))
        let mins = Int(diff.truncatingRemainder(dividingBy: 60 * 60) / 60)

        if days > 0 {
            remainingText = "\(days)일 남음"
        } else if hours > 0 {
            remainingText = "\(hours)시간 \(mins)분 남음"
        } else {
            remainingText = "\(mins)분 남음"
        }
    }
    
    // MARK: - Properties
    private var fallbackImage: some View {
        Rectangle()
            .fill(Color.nsGray100)
            .aspectRatio(1, contentMode: .fill)
            .overlay(
                Image(systemName: "photo.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.nsGray300)
            )
    }
}
