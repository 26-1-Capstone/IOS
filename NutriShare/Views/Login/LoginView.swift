import SwiftUI
#Preview {
    LoginView();
}
struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isLoading = false
    @State private var errorToastMessage = ""
    
    // WebView Auth States
    @State private var showingWebView = false
    @State private var authRequestUrl: URL?

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
                    benefitRow(symbol: "shippingbox.fill", text: "대용량 마트 상품을 소분해서 알뜰하게")
                    benefitRow(symbol: "truck.box.fill", text: "이웃과 함께사면 배송비 0원")
                }
                .padding(.horizontal, NSSpacing.xxl)
                .padding(.bottom, NSSpacing.xxxl)

                // OAuth Buttons
                VStack(spacing: NSSpacing.md) {
                    socialLoginButton(
                        icon: "applelogo",
                        text: "테스트 계정 로그인 (Dev)",
                        backgroundColor: .black,
                        textColor: .white,
                        action: { handleLogin() }
                    )

                    socialLoginButton(
                        icon: "message.fill",
                        text: "카카오 로그인",
                        backgroundColor: Color(hex: "FEE500"),
                        textColor: .black.opacity(0.85),
                        action: {
                            let baseUrlString = APIService.shared.baseURL
                                .replacingOccurrences(of: "/api/v1", with: "")
                                .replacingOccurrences(of: "localhost", with: "127.0.0.1")
                            if let url = URL(string: "\(baseUrlString)/oauth2/authorization/kakao") {
                                authRequestUrl = url
                                showingWebView = true
                            }
                        }
                    )
                    
                    socialLoginButton(
                        icon: "g.circle.fill",
                        text: "구글 로그인",
                        backgroundColor: .white,
                        textColor: .black.opacity(0.85),
                        showBorder: true,
                        action: {
                            let baseUrlString = APIService.shared.baseURL
                                .replacingOccurrences(of: "/api/v1", with: "")
                                .replacingOccurrences(of: "localhost", with: "127.0.0.1")
                            if let url = URL(string: "\(baseUrlString)/oauth2/authorization/google") {
                                authRequestUrl = url
                                showingWebView = true
                            }
                        }
                    )
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

                Text("현재 서버: \(APIService.shared.baseURL)")
                    .font(.system(size: NSFont.xs))
                    .foregroundColor(.nsTextDisabled)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, NSSpacing.xxl)
            }

            if isLoading {
                Color.black.opacity(0.3).ignoresSafeArea()
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
        .toast($errorToastMessage, type: .error)
        .fullScreenCover(isPresented: $showingWebView) {
            if let targetUrl = authRequestUrl {
                ZStack(alignment: .topTrailing) {
                    LoginWebView(
                        url: targetUrl,
                        onTokenReceived: { token in
                            showingWebView = false
                            authManager.setToken(token)
                        },
                        onCancel: {
                            showingWebView = false
                        },
                        onError: { message in
                            showingWebView = false
                            errorToastMessage = message
                        }
                    )
                    .edgesIgnoringSafeArea(.bottom)
                    
                    Button(action: { showingWebView = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.black.opacity(0.5))
                            .padding()
                    }
                }
            }
        }
    }

    private func benefitRow(symbol: String, text: String) -> some View {
        HStack(spacing: NSSpacing.md) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.nsPrimary)
                .frame(width: 24)
            Text(text)
                .font(.system(size: NSFont.sm))
                .foregroundColor(.nsTextSecondary)
            Spacer()
        }
        .padding(NSSpacing.md)
        .background(Color.nsSurfaceAlt)
        .cornerRadius(NSRadius.md)
    }

    private func socialLoginButton(
        icon: String,
        text: String,
        backgroundColor: Color,
        textColor: Color,
        showBorder: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: NSSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: NSFont.lg, weight: .bold))
                    .foregroundColor(textColor)
                    .frame(width: 28, height: 28)
                    .background(backgroundColor == .white && showBorder ? Color.clear : backgroundColor)
                    .cornerRadius(6)
                Text(text)
                    .font(.system(size: NSFont.md, weight: .semibold))
            }
            .foregroundColor(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, NSSpacing.md)
            .background(backgroundColor)
            .cornerRadius(NSRadius.md)
            .overlay(
                Group {
                    if showBorder {
                        RoundedRectangle(cornerRadius: NSRadius.md)
                            .stroke(Color.nsGray300, lineWidth: 1)
                    }
                }
            )
        }
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
                await MainActor.run {
                    errorToastMessage = error.localizedDescription
                }
            }

            await MainActor.run { isLoading = false }
        }
    }
}
