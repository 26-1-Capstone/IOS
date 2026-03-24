import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) var dismiss

    @State private var nickname = ""
    @State private var email = ""
    @State private var cityOrDistrict = ""
    @State private var dong = ""
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var toastMessage = ""

    var body: some View {
        if isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .task { await loadProfile() }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: NSSpacing.xl) {
                    // Basic Info
                    sectionView(title: "기본 정보") {
                        VStack(spacing: NSSpacing.md) {
                            formField(label: "닉네임", text: $nickname, placeholder: "닉네임을 입력하세요")
                            formField(label: "이메일 (변경 불가)", text: .constant(email), placeholder: "", disabled: true)
                        }
                    }

                    Divider()

                    // Address
                    sectionView(title: "내 동네 설정") {
                        VStack(alignment: .leading, spacing: NSSpacing.md) {
                            Text("온보딩과 공동구매 추천에 사용할 내 동네를 입력해 주세요. 주소는 `~시 ~동` 기준으로 간단히 관리합니다.")
                                .font(.system(size: NSFont.xs))
                                .foregroundColor(.nsTextSecondary)

                            VStack(alignment: .leading, spacing: NSSpacing.xs) {
                                Text("시/구")
                                    .font(.system(size: NSFont.sm, weight: .semibold))
                                    .foregroundColor(.nsTextSecondary)
                                TextField("예) 서울시 강남구", text: $cityOrDistrict)
                                    .textFieldStyle(.roundedBorder)
                            }

                            VStack(alignment: .leading, spacing: NSSpacing.xs) {
                                Text("동")
                                    .font(.system(size: NSFont.sm, weight: .semibold))
                                    .foregroundColor(.nsTextSecondary)
                                TextField("예) 역삼동", text: $dong)
                                    .textFieldStyle(.roundedBorder)
                            }

                            Text("입력한 동네를 기준으로 같은 지역 공동구매를 함께 보게 됩니다.")
                                .font(.system(size: NSFont.xs))
                                .foregroundColor(.nsPrimaryDark)
                        }
                    }

                    // Save Button
                    Button(action: saveProfile) {
                        Text(isSaving ? "저장 중..." : "프로필 저장")
                            .font(.system(size: NSFont.md, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, NSSpacing.md)
                            .background(isSaving ? Color.nsGray400 : Color.nsPrimary)
                            .cornerRadius(NSRadius.md)
                    }
                    .disabled(isSaving)

                }
                .padding(NSSpacing.base)
            }
            .background(Color.nsBg)
            .navigationTitle("프로필 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toast($toastMessage, type: .success)
        }
    }

    private func sectionView<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: NSSpacing.md) {
            Text(title)
                .font(.system(size: NSFont.md, weight: .bold))
                .foregroundColor(.nsTextPrimary)
            content()
        }
    }

    private func formField(label: String, text: Binding<String>, placeholder: String, disabled: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: NSSpacing.xs) {
            Text(label)
                .font(.system(size: NSFont.sm, weight: .semibold))
                .foregroundColor(.nsTextSecondary)
            TextField(placeholder, text: text)
                .textFieldStyle(.roundedBorder)
                .disabled(disabled)
                .opacity(disabled ? 0.6 : 1)
        }
    }

    private func loadProfile() async {
        isLoading = true
        do {
            let response: ApiResponse<UserProfile> = try await APIService.shared.get("/users/me")
            if let data = response.data {
                await MainActor.run {
                    nickname = data.nickname ?? ""
                    email = data.email ?? ""
                    cityOrDistrict = data.address?.cityOrDistrict ?? ""
                    dong = data.address?.dong ?? ""
                }
            }
        } catch {
            print("Failed to load profile: \(error)")
        }
        await MainActor.run { isLoading = false }
    }

    private func saveProfile() {
        isSaving = true
        let payload = ProfileUpdateRequest(
            nickname: nickname,
            zipCode: nil,
            addressLine1: cityOrDistrict.isEmpty ? nil : cityOrDistrict,
            addressLine2: nil,
            dong: dong.isEmpty ? nil : dong
        )

        Task {
            do {
                let _: ApiResponse<ResourceResponse> = try await APIService.shared.put("/users/me", body: payload)
                await MainActor.run {
                    toastMessage = "프로필이 성공적으로 수정되었습니다."
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run { dismiss() }
            } catch {
                print("Failed to save profile: \(error)")
                await MainActor.run { toastMessage = "프로필 수정에 실패했습니다." }
            }
            await MainActor.run { isSaving = false }
        }
    }
}
