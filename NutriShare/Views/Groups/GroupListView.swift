import SwiftUI
#Preview {
    GroupListView();
}
struct GroupListView: View {
    @State private var groups: [GroupPurchase] = []
    @State private var isLoading = true

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: NSSpacing.base) {
                    HStack(spacing: 6) {
                        Text("🤝")
                            .font(.system(size: 24))
                        Text("공동구매")
                            .font(.system(size: NSFont.lg, weight: .bold))
                            .foregroundColor(.nsTextPrimary)
                        Spacer()
                    }
                    .padding(.horizontal, NSSpacing.base)
                    .padding(.top, NSSpacing.sm)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("함께 사면 더 저렴한 공동구매")
                            .font(.system(size: NSFont.xxl, weight: .bold))
                        Text("진행 중인 공구를 확인하고 바로 참여해보세요.")
                            .font(.system(size: NSFont.sm))
                            .foregroundColor(.nsTextSecondary)
                    }
                    .padding(.horizontal, NSSpacing.base)

                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, NSSpacing.xxxl)
                    } else if groups.isEmpty {
                        EmptyStateView(
                            title: "진행 중인 공동구매가 없습니다.",
                            description: "새 공동구매를 열어서 첫 참여자를 모아보세요."
                        )
                    } else {
                        LazyVStack(spacing: NSSpacing.base) {
                            ForEach(groups) { group in
                                NavigationLink(destination: GroupDetailView(groupId: group.id)) {
                                    GroupBuyingCardView(group: group)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, NSSpacing.base)
                    }
                }
                .padding(.top, NSSpacing.md)
                .padding(.bottom, NSSpacing.xxl)
            }
            .background(Color.nsBg)
            .task {
                await loadGroups()
            }
            .refreshable {
                await loadGroups()
            }

            NavigationLink(destination: GroupCreateView()) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.nsPrimary)
                    .clipShape(Circle())
                    .shadow(color: .nsPrimary.opacity(0.4), radius: 8, y: 4)
            }
            .padding(.trailing, NSSpacing.xl)
            .padding(.bottom, NSSpacing.xl)
        }
        .navigationBarHidden(true)
    }

    @MainActor
    private func loadGroups() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: ApiResponse<PagedData<GroupPurchase>> = try await APIService.shared.get(
                "/groups",
                queryItems: [URLQueryItem(name: "size", value: "50")]
            )
            groups = response.data?.content ?? []
        } catch {
            print("Failed to load groups: \(error)")
            groups = []
        }
    }
}
