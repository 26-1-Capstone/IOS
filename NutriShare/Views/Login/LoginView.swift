import SwiftUI
#Preview {
    LoginView();
}
struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isLoading = false
    @State private var showSignupSheet = false
    @State private var showSignupError = false
    @State private var signupErrorMessage = ""

    @State private var signupEmail = ""
    @State private var signupPassword = ""
    @State private var signupName = ""
    @State private var signupZipCode = ""
    @State private var signupAddressLine1 = ""
    @State private var signupAddressLine2 = ""

    var body: some View {
        ZStack {
            Color.nsBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo
                VStack(spacing: 8) {
                    Text("NutriShare")
                        .font(.system(size: NSFont.xxxl, weight: .bold))
                        .foregroundColor(.nsPrimary)

                    Text("우리 동네 알뜰 식료품 공동구매")
                        .font(.system(size: NSFont.base))
                        .font(.system(size: NSFont.base))
                        .foregroundColor(.nsTextSecondary)
                }
                .padding(.bottom, NSSpacing.xxl)

                // Benefits
                VStack(spacing: NSSpacing.md) {
                    benefitRow(icon: "📦", text: "대용량 마트 상품을 소분해서 알뜰하게")
                    benefitRow(icon: "🚚", text: "이웃과 함께사면 배송비 0원")
                }
                .padding(.horizontal, NSSpacing.xxl)
                .padding(.bottom, NSSpacing.xxxl)

                // OAuth Buttons
                VStack(spacing: NSSpacing.md) {
                    Button(action: { handleLogin() }) {
                        HStack(spacing: NSSpacing.sm) {
                            Text("K")
                                .font(.system(size: NSFont.lg, weight: .bold))
                                .frame(width: 28, height: 28)
                                .background(Color.black.opacity(0.1))
                                .cornerRadius(6)
                            Text("카카오로 3초 만에 시작하기")
                                .font(.system(size: NSFont.md, weight: .semibold))
                        }
                        .foregroundColor(.black.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, NSSpacing.md)
                        .background(Color(hex: "FEE500"))
                        .cornerRadius(NSRadius.md)
                    }

                    Button(action: { handleLogin() }) {
                        HStack(spacing: NSSpacing.sm) {
                            Text("G")
                                .font(.system(size: NSFont.lg, weight: .bold))
                                .foregroundColor(.red)
                                .frame(width: 28, height: 28)
                                .background(Color.white)
                                .cornerRadius(6)
                            Text("Google 계정으로 로그인")
                                .font(.system(size: NSFont.md, weight: .semibold))
                        }
                        .foregroundColor(.nsTextPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, NSSpacing.md)
                        .background(Color.white)
                        .cornerRadius(NSRadius.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: NSRadius.md)
                                .stroke(Color.nsGray300, lineWidth: 1)
                        )
                    }

                    /*Button(action: { showSignupSheet = true }) {
                        Text("이메일로 회원가입")
                            .font(.system(size: NSFont.sm, weight: .semibold))
                            .foregroundColor(.nsPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, NSSpacing.md)
                            .overlay(
                                RoundedRectangle(cornerRadius: NSRadius.md)
                                    .stroke(Color.nsPrimary, lineWidth: 1)
                            )
                    }*/
                }
                .padding(.horizontal, NSSpacing.xxl)

                Spacer()

                // Footer
                Text("로그인 시 NutriShare의 이용약관 및 개인정보처리방침에 동의하게 됩니다.")
                    .font(.system(size: NSFont.xs))
                    .foregroundColor(.nsTextDisabled)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, NSSpacing.xxl)
                    .padding(.bottom, NSSpacing.xxl)
            }

            if isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
        .sheet(isPresented: $showSignupSheet) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: NSSpacing.lg) {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: NSRadius.lg)
                                .fill(
                                    LinearGradient(
                                        colors: [.nsPrimary, .nsPrimaryDark],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            VStack(alignment: .leading, spacing: NSSpacing.xs) {
                                Text("회원가입")
                                    .font(.system(size: NSFont.xl, weight: .bold))
                                    .foregroundColor(.white)
                                Text("이메일과 배송지 정보를 입력하면\n바로 공동구매를 시작할 수 있어요.")
                                    .font(.system(size: NSFont.sm))
                                    .foregroundColor(.white.opacity(0.9))
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(NSSpacing.lg)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 128)
                        .padding(.horizontal, NSSpacing.base)

                        VStack(alignment: .leading, spacing: NSSpacing.sm) {
                            Text("계정 정보")
                                .font(.system(size: NSFont.sm, weight: .semibold))
                                .foregroundColor(.nsTextPrimary)
                            signupInputField("이메일", text: $signupEmail, isEmail: true)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            signupSecureField("비밀번호 (8자 이상)", text: $signupPassword)
                            signupInputField("이름", text: $signupName)
                        }
                        .padding(NSSpacing.base)
                        .background(Color.nsSurfaceAlt)
                        .cornerRadius(NSRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: NSRadius.lg)
                                .stroke(Color.nsGray200, lineWidth: 1)
                        )
                        .padding(.horizontal, NSSpacing.base)

                        VStack(alignment: .leading, spacing: NSSpacing.sm) {
                            Text("주소")
                                .font(.system(size: NSFont.sm, weight: .semibold))
                                .foregroundColor(.nsTextPrimary)
                            signupInputField("우편번호", text: $signupZipCode)
                            signupInputField("기본 주소", text: $signupAddressLine1)
                            signupInputField("상세 주소", text: $signupAddressLine2)
                        }
                        .padding(NSSpacing.base)
                        .background(Color.nsSurfaceAlt)
                        .cornerRadius(NSRadius.lg)
                        .overlay(
                            RoundedRectangle(cornerRadius: NSRadius.lg)
                                .stroke(Color.nsGray200, lineWidth: 1)
                        )
                        .padding(.horizontal, NSSpacing.base)

                        Button(action: {
                            Task { await handleSignup() }
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("가입하고 시작하기")
                                        .font(.system(size: NSFont.md, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, NSSpacing.md)
                            .background(isSignupFormValid ? Color.nsPrimary : Color.nsGray300)
                            .cornerRadius(NSRadius.md)
                        }
                        .disabled(!isSignupFormValid || isLoading)
                        .padding(.horizontal, NSSpacing.base)
                        .padding(.top, NSSpacing.sm)
                    }
                }
                .background(Color.nsBg)
                .scrollContentBackground(.hidden)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("닫기") { showSignupSheet = false }
                    }
                }
            }
        }
        .alert("회원가입 오류", isPresented: $showSignupError) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(signupErrorMessage)
        }
    }

    private func benefitRow(icon: String, text: String) -> some View {
        HStack(spacing: NSSpacing.md) {
            Text(icon)
                .font(.system(size: 24))
            Text(text)
                .font(.system(size: NSFont.sm))
                .foregroundColor(.nsTextSecondary)
            Spacer()
        }
        .padding(NSSpacing.md)
        .background(Color.nsSurfaceAlt)
        .cornerRadius(NSRadius.md)
    }

    private func signupInputField(_ placeholder: String, text: Binding<String>, isEmail: Bool = false) -> some View {
        TextField(placeholder, text: text)
            .keyboardType(isEmail ? .emailAddress : .default)
            .font(.system(size: NSFont.sm))
            .padding(.horizontal, NSSpacing.md)
            .padding(.vertical, NSSpacing.md)
            .background(Color.nsSurface)
            .cornerRadius(NSRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: NSRadius.md)
                    .stroke(Color.nsGray200, lineWidth: 1)
            )
    }

    private func signupSecureField(_ placeholder: String, text: Binding<String>) -> some View {
        SecureField(placeholder, text: text)
            .font(.system(size: NSFont.sm))
            .padding(.horizontal, NSSpacing.md)
            .padding(.vertical, NSSpacing.md)
            .background(Color.nsSurface)
            .cornerRadius(NSRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: NSRadius.md)
                    .stroke(Color.nsGray200, lineWidth: 1)
            )
    }

    private func handleLogin() {
        Task {
            await MainActor.run { isLoading = true }

            do {
                let response: ApiResponse<String> = try await APIService.shared.get(
                    "/auth/dev-login",
                    authenticated: false
                )

                guard let token = response.data else {
                    throw APIError.invalidResponse
                }

                await MainActor.run {
                    authManager.setToken(token)
                }
            } catch {
                print("Login failed: \(error.localizedDescription)")
            }

            await MainActor.run { isLoading = false }
        }
    }

    private var isSignupFormValid: Bool {
        signupEmail.contains("@") &&
        signupPassword.count >= 8 &&
        !signupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func handleSignup() async {
        struct SignupRequest: Encodable {
            let email: String
            let password: String
            let name: String
            let zipCode: String?
            let addressLine1: String?
            let addressLine2: String?
        }

        await MainActor.run { isLoading = true }

        do {
            let payload = SignupRequest(
                email: signupEmail.trimmingCharacters(in: .whitespacesAndNewlines),
                password: signupPassword,
                name: signupName.trimmingCharacters(in: .whitespacesAndNewlines),
                zipCode: signupZipCode.isEmpty ? nil : signupZipCode,
                addressLine1: signupAddressLine1.isEmpty ? nil : signupAddressLine1,
                addressLine2: signupAddressLine2.isEmpty ? nil : signupAddressLine2
            )

            let response: ApiResponse<String> = try await APIService.shared.post(
                "/auth/signup",
                body: payload,
                authenticated: false
            )

            if let token = response.data {
                await MainActor.run {
                    authManager.setToken(token)
                    showSignupSheet = false
                }
            } else {
                throw APIError.invalidResponse
            }
        } catch {
            await MainActor.run {
                signupErrorMessage = error.localizedDescription
                showSignupError = true
            }
        }

        await MainActor.run { isLoading = false }
    }
}
