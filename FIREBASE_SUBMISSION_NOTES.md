# ReceiptSnap Firebase Submission Notes

## Implemented runtime
- `ReceiptSnap/ReceiptSnapApp.swift`
  - Firebase is configured at launch.
  - Google Sign-In callback URLs are handled.
- `ReceiptSnap/Services/Auth/ServiceLocator.swift`
  - Auth uses `FirebaseAuthService`.
  - Receipts now use `FirebaseReceiptService`.
  - Budgets now use `FirebaseBudgetService`.

## Firebase data structure
- Firestore collections
  - `users/{uid}`
  - `receipts/{receiptId}`
  - `budgets/{budgetId}`
- Receipt document fields
  - `id`, `userId`, `title`, `category`, `date`, `amount`, `notes`, `isFavorite`, `tags`, `imageURL`, `createdAt`, `updatedAt`
  - optional `split`
- Budget document fields
  - `id`, `userId`, `monthlyLimit`, `currentSpending`, `period`, `month`, `year`, `alertEnabled`, `alertThreshold`, `createdAt`
- Firebase Storage
  - receipt photos are stored at `receipts/{uid}/{receiptId}.jpg`

## Security rules to apply in Firebase
```txt
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    match /receipts/{receiptId} {
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      allow update: if request.auth != null
        && resource.data.userId == request.auth.uid
        && request.resource.data.userId == request.auth.uid;
      allow delete: if request.auth != null && resource.data.userId == request.auth.uid;
    }

    match /budgets/{budgetId} {
      allow read: if request.auth != null && resource.data.userId == request.auth.uid;
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      allow update: if request.auth != null
        && resource.data.userId == request.auth.uid
        && request.resource.data.userId == request.auth.uid;
      allow delete: if request.auth != null && resource.data.userId == request.auth.uid;
    }
  }
}
```

```txt
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /receipts/{userId}/{fileName} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Authentication status for the assessment
- Implemented
  - email/password via Firebase Auth
  - Google sign-in via Firebase Auth + Google Sign-In
  - biometric unlock via `LocalAuthentication`
- Partially present
  - Apple Sign-In capability exists in entitlements
  - Apple button exists in login and sign-up screens
  - full Apple authorization flow is not implemented in this assessment build

## Demo steps for biometrics in Simulator
- Face ID
  - run on `iPhone 15` Simulator
  - enable `Features > Face ID > Enrolled`
  - trigger biometric login in the app
  - approve with `Features > Face ID > Matching Face`
  - show a failure once with `Features > Face ID > Non-matching Face`
- Touch ID
  - run on `iPhone SE` Simulator
  - enable `Features > Touch ID > Enrolled`
  - trigger biometric login in the app
  - approve with `Features > Touch ID > Matching Touch`
  - show a failure once with `Features > Touch ID > Non-matching Touch`

## What to say in the demo
- “Biometric login uses Apple LocalAuthentication, and the Simulator is configured to emulate Face ID and Touch ID.”
- “Receipt documents are stored in Firestore, while receipt photos are stored in Firebase Storage and loaded back by URL.”
- “Google sign-in is implemented. Apple Sign-In capability is present, but the full production authorization flow is not included in this assessment build.”