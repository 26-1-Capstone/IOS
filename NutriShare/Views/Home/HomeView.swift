import SwiftUI
#Preview {
    HomeView()
        .environmentObject(CartStore())
        .environmentObject(WishlistStore())
}
struct HomeView: View {
    @State private var products: [Product] = []
    @State private var isLoading = true

    // Banner State
    @State private var currentBannerIndex = 0
    let scrollTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    // Banner Model
    struct BannerItem: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let actionText: String
        let gradientColors: [Color]
    }
    
    private let banners = [
        BannerItem(title: "득템 찬스!\n함께 사면 배송비 0원", subtitle: "NutriShare 생필품 공동구매로\n생활비를 절약하세요.", actionText: "", gradientColors: [.nsPrimaryBg, .nsSurface]),
        BannerItem(title: "공동구매 모집 중\n이웃과 함께 절약", subtitle: "진행 중인 공구를 둘러보고\n지금 바로 참여해보세요.", actionText: "", gradientColors: [.indigo.opacity(0.1), .nsSurface]),
        BannerItem(title: "장바구니 담기\n한 번에 편하게", subtitle: "필요한 상품을 담고\n배송으로 받아보세요.", actionText: "", gradientColors: [.orange.opacity(0.1), .nsSurface])
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Custom Header (matches web frontend)
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "leaf.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.nsPrimary)
                        Text("NutriShare")
                            .font(.system(size: NSFont.lg, weight: .bold))
                            .foregroundColor(.nsPrimary)
                    }
                    Spacer()
                    HStack(spacing: 16) {
                        NavigationLink(destination: SearchView()) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 20))
                                .foregroundColor(.nsTextPrimary)
                        }
                        
                        NavigationLink(destination: NotificationView()) {
                            Image(systemName: "bell")
                                .font(.system(size: 20))
                                .foregroundColor(.nsTextPrimary)
                                .overlay(
                                    Circle()
                                        .fill(Color.nsError)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 8, y: -8)
                                )
                        }
                    }
                }
                .padding(.horizontal, NSSpacing.base)
                .padding(.vertical, NSSpacing.md)
                .background(Color.nsSurface)

                // Hero Section
                heroSection

                // Product Grid
                productSection
            }
        }
        .background(Color.nsBg)
        .navigationBarHidden(true)
        .task {
            await loadProducts()
        }
    }


    // MARK: - Hero Section
    private var heroSection: some View {
        TabView(selection: $currentBannerIndex) {
            ForEach(0..<banners.count, id: \.self) { index in
                let banner = banners[index]
                VStack(alignment: .leading, spacing: NSSpacing.md) {
                    Text(banner.title)
                        .font(.system(size: NSFont.xxl, weight: .bold))
                        .foregroundColor(.nsTextPrimary)

                    Text(banner.subtitle)
                        .font(.system(size: NSFont.sm))
                        .foregroundColor(.nsTextSecondary)
                }
                .padding(NSSpacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: banner.gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .tag(index)
            }
        }
        .frame(height: 260)
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .onReceive(scrollTimer) { _ in
            withAnimation {
                currentBannerIndex = (currentBannerIndex + 1) % banners.count
            }
        }
    }

    // MARK: - Product Section
    private var productSection: some View {
        VStack(alignment: .leading, spacing: NSSpacing.base) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "cart.fill")
                        .foregroundColor(.nsPrimary)
                    Text("NutriShare 특가 생필품")
                        .font(.system(size: NSFont.lg, weight: .bold))
                }
                Spacer()
            }
            .padding(.horizontal, NSSpacing.base)

            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, NSSpacing.xxxl)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: NSSpacing.md),
                    GridItem(.flexible(), spacing: NSSpacing.md)
                ], spacing: NSSpacing.base) {
                    ForEach(products, id: \.id) { product in
                        NavigationLink(destination: ProductDetailView(productId: product.id)) {
                            ProductCardView(product: product)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, NSSpacing.base)
            }
        }
        .padding(.vertical, NSSpacing.xl)
    }

    // MARK: - Data Loading
    private func loadProducts() async {
        isLoading = true
        do {
            let response: ApiResponse<PagedData<Product>> = try await APIService.shared.get(
                "/products",
                queryItems: [URLQueryItem(name: "size", value: "50")]
            )
            if let data = response.data {
                await MainActor.run {
                    products = data.content
                }
            }
        } catch {
            print("Failed to load products: \(error)")
        }
        await MainActor.run {
            isLoading = false
        }
    }
}
