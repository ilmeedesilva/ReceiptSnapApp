# ReceiptSnap — Development Guide

## Overview

ReceiptSnap is a SwiftUI iOS application for receipt scanning and expense tracking. This guide covers Phase 1: the complete authentication flow.

---

## Project Structure

```
ReceiptSnap/
├── App/
│   ├── ReceiptSnapApp.swift          App entry point; Firebase configure hook
│   ├── AppState.swift                Global auth + session state (@EnvironmentObject)
│   ├── AuthRoute.swift               Typed NavigationStack destinations
│   └── AuthCoordinatorView.swift     Owns ViewModels; drives auth NavigationStack
│
├── Core/
│   ├── Theme/
│   │   ├── AppColors.swift           Brand palette + Color(hex:) initialiser
│   │   └── AppTheme.swift            Spacing, radii, font sizes, heights
│   ├── Extensions/
│   │   ├── String+Validation.swift   isValidEmail, isValidPassword, etc.
│   │   └── View+Extensions.swift     .dismissKeyboardOnTap(), .rsCardStyle(), etc.
│   └── Components/
│       ├── PrimaryButton.swift       Filled CTA button
│       ├── SecondaryButton.swift     Outlined button
│       ├── CustomTextField.swift     Styled text input + label + error
│       ├── PasswordTextField.swift   Secure field with show/hide toggle
│       ├── OTPInputField.swift       6-cell OTP with auto-advance + paste
│       ├── SocialLoginButton.swift   Google / Apple outlined button
│       ├── LoadingOverlay.swift      Semi-transparent loading modal
│       └── BackButton.swift          Consistent back chevron
│
├── Features/
│   ├── Onboarding/
│   │   └── OnboardingView.swift      Welcome screen
│   ├── Auth/
│   │   ├── Views/
│   │   │   ├── LoginView.swift
│   │   │   ├── SignUpView.swift
│   │   │   ├── AccountCreatedView.swift
│   │   │   └── ForgotPassword/
│   │   │       ├── ForgotPasswordEmailView.swift
│   │   │       ├── VerifyCodeView.swift
│   │   │       ├── CreateNewPasswordView.swift
│   │   │       └── PasswordUpdatedView.swift
│   │   └── ViewModels/
│   │       ├── LoginViewModel.swift
│   │       ├── SignUpViewModel.swift
│   │       └── ForgotPasswordViewModel.swift
│   ├── Biometric/
│   │   ├── Views/
│   │   │   ├── BiometricSetupView.swift
│   │   │   ├── FaceIDScanningView.swift
│   │   │   ├── BiometricSuccessView.swift
│   │   │   ├── PasscodeSetupView.swift
│   │   │   └── PasscodeSuccessView.swift
│   │   └── ViewModels/
│   │       └── BiometricViewModel.swift
│   └── Home/
│       └── HomeView.swift            Phase 1 placeholder
│
├── Services/
│   ├── Auth/
│   │   ├── AuthServiceProtocol.swift  Protocol + AuthError enum
│   │   ├── MockAuthService.swift      In-memory implementation (default)
│   │   ├── FirebaseAuthService.swift  Firebase implementation (requires SDK)
│   │   └── ServiceLocator.swift       Central service registry
│   ├── Biometric/
│   │   └── BiometricService.swift     LAContext wrapper + MockBiometricService
│   └── Storage/
│       └── KeychainService.swift      Keychain CRUD + passcode helpers
│
└── Models/
    └── AppUser.swift                  Lightweight user value type

ReceiptSnapTests/
├── Auth/
│   ├── LoginViewModelTests.swift      (15 tests)
│   ├── SignUpViewModelTests.swift     (18 tests)
│   └── ForgotPasswordViewModelTests.swift (16 tests)
├── Services/
│   ├── BiometricViewModelTests.swift  (14 tests)
│   └── KeychainServiceTests.swift     (10 tests)
└── Validation/
    └── ValidationTests.swift          (18 tests)
```

Total unit tests: **91+**

---

## Quick Start (No Firebase)

The project compiles and runs **immediately** using `MockAuthService`.

1. Open `ReceiptSnap.xcodeproj` in Xcode
2. Select an iPhone 15 simulator (iOS 17+)
3. Press **Run** (⌘R)

**Demo credentials:**
- Email: `demo@receiptsnap.com`
- Password: `Demo@1234`

You can also create a new account from the Sign Up screen; new users are stored in memory for the session.

---

## Firebase Setup (Production)

### 1. Create Firebase Project
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Create a project (e.g. "ReceiptSnap")
3. Add an iOS app with bundle ID `com.yourname.ReceiptSnap`
4. Download `GoogleService-Info.plist`

### 2. Add Firebase SDK
In Xcode: **File ▸ Add Package Dependencies…**
```
https://github.com/firebase/firebase-ios-sdk
```
Select products: **FirebaseAuth** + **FirebaseFirestore**

### 3. Add GoogleService-Info.plist
Drag the downloaded file into the Xcode project navigator, ensuring "Add to target: ReceiptSnap" is checked.

### 4. Activate Firebase in Code
**ReceiptSnapApp.swift** — uncomment:
```swift
FirebaseApp.configure()
```

**ServiceLocator.swift** — change:
```swift
lazy var authService: AuthServiceProtocol = FirebaseAuthService()
```

---

## Architecture

### Pattern: MVVM + Coordinator

| Layer      | Responsibility                                          |
|------------|--------------------------------------------------------|
| View       | SwiftUI declarative UI, observes ViewModel state        |
| ViewModel  | Business logic, input validation, async service calls   |
| Service    | Network/hardware I/O (Firebase, LocalAuthentication)    |
| Model      | Plain value types (`AppUser`)                           |
| AppState   | Session state shared via `@EnvironmentObject`           |
| Coordinator | Navigation: `AuthCoordinatorView` owns `NavigationStack`|

### Dependency Injection
ViewModels accept `AuthServiceProtocol` via constructor:
```swift
LoginViewModel(authService: MockAuthService())    // tests
LoginViewModel(authService: FirebaseAuthService()) // production
```
Default uses `ServiceLocator.shared.authService`, so swapping is a one-liner.

---

## Authentication Flow

```
App Launch
  │
  ├── hasCompletedOnboarding == false
  │     └── OnboardingView → completeOnboarding() → auth flow
  │
  └── hasCompletedOnboarding == true
        │
        ├── isAuthenticated == false
        │     └── AuthCoordinatorView (NavigationStack)
        │           ├── LoginView
        │           │     ├── → ForgotPasswordEmailView
        │           │     │     → VerifyCodeView
        │           │     │       → CreateNewPasswordView
        │           │     │           → PasswordUpdatedView → LoginView
        │           │     │
        │           │     └── → SignUpView → AccountCreatedView
        │           │                           ├── → BiometricSetupView
        │           │                           │     ├── FaceIDScanningView → BiometricSuccessView
        │           │                           │     └── → PasscodeSetupView → PasscodeSuccessView
        │           │                           └── Skip → Home
        │           └── (after any successful path) → appState.signIn()
        │
        └── isAuthenticated == true
              └── HomeView
```

---

## Colour Palette

| Token               | Hex       | Usage                     |
|---------------------|-----------|---------------------------|
| `rsDeepGreen`       | `#0E3B2E` | Headings, dark text        |
| `rsForestGreen`     | `#1F6F54` | Primary buttons, links     |
| `rsMediumGreen`     | `#5FB88A` | Success icons, accents     |
| `rsLightGreen`      | `#D7E7DD` | Illustration backgrounds   |
| `rsBackgroundGreen` | `#F6FBF7` | Screen backgrounds         |

---

## Running Tests

```bash
# All tests
xcodebuild test \
  -scheme ReceiptSnap \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# In Xcode
# ⌘U — runs all tests
# ⌘6 — opens Test Navigator
```

---

## Accessibility

- All interactive elements have `.accessibilityLabel`
- `PrimaryButton` and `SecondaryButton` add `.isButton` trait
- OTP cells announce digit state: "Digit 4"
- Error messages prepend "Error:" for VoiceOver
- Password show/hide announces "Show password" / "Hide password"

---

## Phase 2 Integration Notes

The Phase 1 auth layer is intentionally decoupled so Phase 2 can be added without refactoring.

### What Phase 2 should add
1. **Receipt model** — `Item.swift` is a placeholder; add `@Model class Receipt` there
2. **Camera / OCR** — new `ScanFeature/` directory
3. **Receipt list** — replace `HomeView.swift` placeholder cards
4. **Firestore schema** — receipts collection: `users/{uid}/receipts/{receiptId}`
5. **Cloud Storage** — receipt images at `receipts/{uid}/{receiptId}.jpg`

### AppState extension
Add `var receipts: [Receipt]` and a listener in `AppState` when Phase 2 starts.

### SwiftData (optional)
Re-enable SwiftData in `ReceiptSnapApp.swift` for offline caching of receipts.
`Item.swift` is the designated placeholder for the `Receipt` model.
