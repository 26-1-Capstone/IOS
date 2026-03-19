import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) var dismiss

    @State private var nickname = ""
    @State private var email = ""
    @State private var zipCode = ""
    @State private var addressLine1 = ""
    @State private var addressLine2 = ""
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
                    sectionView(title: "기본 배송지 관리") {
                        VStack(alignment: .leading, spacing: NSSpacing.md) {
                            Text("공동구매 결제 시 식료품을 편하게 받아보실 배송지를 등록해 주세요.")
                                .font(.system(size: NSFont.xs))
                                .foregroundColor(.nsTextSecondary)

                            HStack(spacing: NSSpacing.sm) {
                                TextField("우편번호", text: $zipCode)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 120)
                                Button("주소 찾기") {
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

                    Divider()

                    // Danger Zone
                    sectionView(title: "회원 탈퇴") {
                        VStack(alignment: .leading, spacing: NSSpacing.sm) {
                            Text("탈퇴 시 참여 중인 공동구매 내역이 모두 취소됩니다.")
                                .font(.system(size: NSFont.xs))
                                .foregroundColor(.nsTextSecondary)
                            Button("탈퇴하기") {}
                                .font(.system(size: NSFont.sm, weight: .medium))
                                .foregroundColor(.nsError)
                                .padding(.horizontal, NSSpacing.base)
                                .padding(.vertical, NSSpacing.sm)
                                .overlay(
                                    RoundedRectangle(cornerRadius: NSRadius.md)
                                        .stroke(Color.nsError, lineWidth: 1)
                                )
                        }
                    }
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
                    zipCode = data.address?.zipCode ?? ""
                    addressLine1 = data.address?.addressLine1 ?? ""
                    addressLine2 = data.address?.addressLine2 ?? ""
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
            zipCode: zipCode.isEmpty ? nil : zipCode,
            addressLine1: addressLine1.isEmpty ? nil : addressLine1,
            addressLine2: addressLine2.isEmpty ? nil : addressLine2
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
