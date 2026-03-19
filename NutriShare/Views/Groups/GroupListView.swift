import SwiftUI
#Preview {
    GroupListView();
}
struct GroupListView: View {
    @State private var groups: [GroupPurchase] = []
    @State private var neighborhoodText = "내 동네 설정 필요"
    @State private var isLoading = true

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: NSSpacing.base) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.nsPrimary)
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
                        Text("\(neighborhoodText) 기준으로 진행 중인 공구를 확인해보세요.")
                            .font(.system(size: NSFont.sm))
                            .foregroundColor(.nsTextSecondary)
                    }
                    .padding(.horizontal, NSSpacing.base)

                    HStack(spacing: NSSpacing.sm) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundColor(.nsPrimary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("현재 동네")
                                .font(.system(size: NSFont.xs, weight: .semibold))
                                .foregroundColor(.nsTextDisabled)
                            Text(neighborhoodText)
                                .font(.system(size: NSFont.sm, weight: .bold))
                                .foregroundColor(.nsTextPrimary)
                        }
                        Spacer()
                    }
                    .padding(NSSpacing.base)
                    .background(Color.nsSurface)
                    .cornerRadius(NSRadius.lg)
                    .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
                    .padding(.horizontal, NSSpacing.base)

                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, NSSpacing.xxxl)
                    } else if groups.isEmpty {
                        EmptyStateView(
                            title: "\(neighborhoodText)에 진행 중인 공동구매가 없습니다.",
                            description: "새 공동구매를 열어서 같은 동네 첫 참여자를 모아보세요."
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
            let profileResponse: ApiResponse<UserProfile> = try await APIService.shared.get("/users/me")
            neighborhoodText = profileResponse.data?.address?.districtDisplay ?? "내 동네 설정 필요"

            let response: ApiResponse<PagedData<GroupPurchase>> = try await APIService.shared.get(
                "/groups",
                queryItems: [URLQueryItem(name: "size", value: "50")]
            )
            groups = response.data?.content ?? []
        } catch {
            print("Failed to load groups: \(error)")
            neighborhoodText = "내 동네 설정 필요"
            groups = []
        }
    }
}
