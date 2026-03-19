# NutriShare iOS

NutriShare의 iOS 프론트엔드 프로젝트입니다.  
SwiftUI 기반으로 구성되어 있고, 로컬 백엔드와 연동해 홈, 공동구매, 장바구니, 마이페이지 화면을 테스트할 수 있습니다.

## Requirements

- Xcode 15+
- iOS 16.0+
- 실행 중인 로컬 백엔드

## Run

1. 백엔드를 먼저 실행합니다.
   현재 기본 API Base URL은 `http://localhost:8080/api/v1` 입니다.

2. Xcode에서 아래 프로젝트를 엽니다.
   `NutriShare.xcodeproj`

3. iOS Simulator를 선택한 뒤 실행합니다.

## Project Structure

- `NutriShare/Views`
  화면 단위 SwiftUI 뷰
- `NutriShare/Models`
  API 응답 및 앱 모델
- `NutriShare/Services`
  네트워크 및 인증 처리
- `NutriShare/Utils`
  디자인 시스템 및 공용 유틸

## Notes

- 로그인은 현재 개발용 `dev-login` 흐름으로 테스트합니다.
- 일부 기능은 백엔드 스펙 상태에 따라 동작이 제한될 수 있습니다.
- 상품/공동구매 이미지는 현재 백엔드에서 `imageUrl`을 내려주지 않으면 기본 플레이스홀더로 표시됩니다.
