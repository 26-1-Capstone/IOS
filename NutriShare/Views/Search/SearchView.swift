import SwiftUI

struct SearchView: View {
    @State private var searchText = ""
    @State private var results: [Product] = []
    @State private var isLoading = false
    @State private var hasSearched = false

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack(spacing: NSSpacing.sm) {
                HStack(spacing: NSSpacing.sm) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.nsGray500)
                    TextField("찾으시는 상품을 입력하세요", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit { performSearch() }
                }
                .padding(NSSpacing.md)
                .background(Color.nsGray100)
                .cornerRadius(NSRadius.md)

                Button("검색") { performSearch() }
                    .font(.system(size: NSFont.base, weight: .semibold))
                    .foregroundColor(.nsPrimary)
            }
            .padding(.horizontal, NSSpacing.base)
            .padding(.vertical, NSSpacing.sm)

            // Results
            ScrollView {
                if isLoading {
                    ProgressView()
                        .padding(.top, NSSpacing.xxxl)
                } else if hasSearched && results.isEmpty {
                    EmptyStateView(
                        title: "검색 결과가 없습니다.",
                        description: "다른 검색어 필터를 사용해 보세요."
                    )
                    .padding(.top, NSSpacing.xxl)
                } else if !results.isEmpty {
                    VStack(alignment: .leading, spacing: NSSpacing.md) {
                        Text("'\(searchText)' 검색 결과 \(results.count)건")
                            .font(.system(size: NSFont.sm, weight: .medium))
                            .foregroundColor(.nsTextSecondary)
                            .padding(.horizontal, NSSpacing.base)

                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: NSSpacing.md),
                            GridItem(.flexible(), spacing: NSSpacing.md)
                        ], spacing: NSSpacing.base) {
                            ForEach(results) { product in
                                NavigationLink(destination: ProductDetailView(productId: product.id)) {
                                    ProductCardView(product: product)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, NSSpacing.base)
                    }
                    .padding(.top, NSSpacing.base)
                } else {
                    VStack(spacing: NSSpacing.base) {
                        Image(systemName: "magnifyingglass.circle")
                            .font(.system(size: 46, weight: .medium))
                            .foregroundColor(.nsGray400)
                        Text("검색어를 입력해 맛있는 생필품을 찾아보세요!")
                            .font(.system(size: NSFont.sm))
                            .foregroundColor(.nsTextSecondary)
                    }
                    .padding(.top, NSSpacing.xxxl * 2)
                }
            }
        }
        .background(Color.nsBg)
        .navigationTitle("검색")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        hasSearched = true
        isLoading = true

        Task {
            do {
                let response: ApiResponse<PagedData<Product>> = try await APIService.shared.get(
                    "/products/search",
                    queryItems: [
                        URLQueryItem(name: "q", value: searchText),
                        URLQueryItem(name: "size", value: "50")
                    ]
                )
                await MainActor.run {
                    results = response.data?.content ?? []
                }
            } catch {
                print("Search failed: \(error)")
            }
            await MainActor.run { isLoading = false }
        }
    }
}
