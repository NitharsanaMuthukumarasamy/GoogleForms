# Alumni Lecture Feedback System

A complete feedback collection and administration platform designed for college alumni guest lectures, replacing manual Google Forms with an automated, secure, and mobile-first experience.

---

## 🏛️ System Architecture

The project consists of three core components:

```
d:/Googleforms/
├── admin_app/          # Flutter cross-platform mobile app (Android & iOS) for Admins
├── student_web/        # Ultra-lightweight mobile-first web feedback form (HTML5/CSS3/ES6)
├── functions/          # Firebase Cloud Functions (TypeScript / Node.js)
├── firestore.rules     # Enterprise Firestore security rules & schema constraints
└── firebase.json       # Firebase Hosting, Functions, and Firestore configuration
```

### 1. `/admin_app` (Flutter Admin Suite)
- **Target Platforms**: Android & iOS from a single codebase.
- **State Management & Routing**: `flutter_riverpod` + `go_router` with reactive auth state guards.
- **Design System**: Collegiate Blue & White theme (`#0B2545` Navy, `#134074` Royal Blue, `#F8FAFC` Slate).
- **Core Features**:
  - Secure Email & Password login with Role-Based Access Control (RBAC) checking the `admins` collection.
  - Persistent login session across app launches.
  - Password reset via email.
  - Lecture management: create, edit, delete (with confirmation), and status toggle (**Draft** / **Active** / **Closed**).
  - Folder-style lecture cards formatted as `YYYY_LectureTitle_SpeakerName`.
  - Multi-parameter search & filtering (by Status, Academic Year, Department).
  - High-contrast scannable QR Code generation (`qr_flutter`) linking directly to the student web form.
  - Real-time metric synchronization using Firestore streams.

### 2. `/student_web` (Student Web Form)
- **Concept**: A frictionless, mobile-first web page opened by scanning a lecture's QR code.
- **Zero Friction**: **No student app download and no login required**.
- **URL Format**: `https://<hosting-domain>/?lecture=<lectureId>`
- **Core Features**:
  - Automatically loads and displays lecture session details (Topic, Speaker, Date, Venue, Department).
  - Inactive/Closed protection: If the lecture status is not `active`, displays a friendly "This feedback form is closed" screen.
  - Single configuration source: All questions and validation rules are centralized in [`questions.js`](student_web/js/questions.js).
  - Exact 14-question set (replaces the original Google Form):
    - Email validation, Student Name, Register Number (auto-uppercased).
    - Single-choice radio buttons for Programme and Year of Study.
    - Read-only auto-filled Lecture Title.
    - 1–5 Labeled rating scales for Relevance, Usefulness, and Overall Satisfaction.
    - Long textareas for Takeaways and Suggestions.
    - Checkbox multi-select for Future Alumni Topics.
  - Live progress tracker (% answered).
  - Inline error validation with smooth auto-scroll to the first invalid field.
  - "Clear form" with confirmation modal.
  - **Multi-Layer Duplicate & Spam Protection**:
    - **Register Number Normalization**: Strips internal, leading, and trailing whitespace and forces uppercase (`"abc 123"` and `"ABC123"` map to `"ABC123"`).
    - **Firestore Document-ID Locking**: Uses the normalized register number as the document ID in `lectures/{lectureId}/responses/{registerNumber}`. Firestore's `create` rules inherently reject subsequent attempts with the same ID.
    - **Browser LocalStorage Guard**: Flags the submission locally per `lectureId` to prevent repeat submissions from the same browser, displaying *"You have already submitted feedback for this lecture."*
    - **Anti-Bot Honeypot**: Hidden offscreen field that traps automated bots while remaining invisible to humans.
    - **Minimum Time-to-Fill Check**: Enforces a minimum 10-second completion time to block automated scripts and rapid clicking.
    - **Optional Institutional Email Restriction**: `COLLEGE_EMAIL_DOMAIN` in `questions.js` allows optionally restricting submissions to college domain addresses (e.g., `@college.edu`).
    - **Firebase App Check (reCAPTCHA v3)**: Integrated client-side with fallback token support.

### 3. `/functions` (Firebase Cloud Functions)
- **`onFeedbackSubmitted`**: Listens for new documents in `lectures/{lectureId}/responses/{responseId}` and atomically increments the parent lecture's `responseCount` using `FieldValue.increment(1)`.
- **`submitFeedback`**: Rate-limited callable Cloud Function enforcing IP-based rate limiting (maximum 5 submissions per minute per IP), minimum time-to-fill validation, and App Check token verification.

---

## 🔒 Firestore Database & Security Rules

### Collections Schema:
1. **`admins/{adminId}`**:
   - `id`: string (matches Firebase Auth UID)
   - `name`: string
   - `email`: string
   - `role`: string (`superadmin` | `admin` | `coordinator`)
2. **`lectures/{lectureId}`**:
   - `id`: string
   - `title`: string
   - `speakerName`: string
   - `designation`: string
   - `company`: string
   - `dateTime`: timestamp
   - `venue`: string
   - `department`: string
   - `academicYear`: string
   - `status`: string (`draft` | `active` | `closed`)
   - `createdAt`: timestamp
   - `responseCount`: int
3. **`lectures/{lectureId}/responses/{registerNumber}`**:
   - Document ID is the student's register number (e.g. `23MCA101`).
   - Exact 15 fields enforced by `firestore.rules` (extra unknown fields are blocked).
   - Only authenticated admins can read feedback responses; public/students can never view responses.

---

## 🚀 Setup & Deployment Guide

### Prerequisites
1. **Flutter SDK** (v3.19.0 or later): [Install Flutter](https://docs.flutter.dev/get-started/install)
2. **Node.js** (v20 or later) & **npm**: [Install Node.js](https://nodejs.org/)
3. **Firebase CLI**: Install globally via:
   ```bash
   npm install -g firebase-tools
   ```

---

### Step 1: Initialize Firebase Project
1. Log in to Firebase:
   ```bash
   firebase login
   ```
2. Create a new Firebase project in the [Firebase Console](https://console.firebase.google.com/):
   - Project Name: e.g. `alumni-lecture-feedback`
   - Enable **Firebase Authentication** -> Sign-in method -> Enable **Email/Password**.
   - Enable **Cloud Firestore** in Production mode.
   - Enable **Firebase Hosting**.

---

### Step 2: Deploy Security Rules & Cloud Functions
From the root workspace directory (`d:/Googleforms`):
```bash
# Associate your project
firebase use --add

# Deploy Firestore Security Rules
firebase deploy --only firestore:rules

# Install and deploy Cloud Functions
cd functions
npm install
npm run build
cd ..
firebase deploy --only functions

# Deploy Student Web Form to Firebase Hosting
firebase deploy --only hosting
```

---

### Step 3: Configure Student Web Form
1. In the Firebase Console, go to **Project Settings** -> **General** -> **Your apps** -> Add a **Web app** (`</>`).
2. Copy the `firebaseConfig` object and update [`student_web/js/firebase-config.js`](student_web/js/firebase-config.js):
   ```javascript
   const DEFAULT_FIREBASE_CONFIG = {
     apiKey: "YOUR_API_KEY",
     authDomain: "YOUR_PROJECT.firebaseapp.com",
     projectId: "YOUR_PROJECT_ID",
     storageBucket: "YOUR_PROJECT.appspot.com",
     messagingSenderId: "YOUR_SENDER_ID",
     appId: "YOUR_APP_ID"
   };
   ```
3. Test locally:
   ```bash
   npx serve student_web
   ```
   Open `http://localhost:3000/?lecture=<LECTURE_ID>` in your browser.

---

### Step 4: Configure & Run Flutter Admin App

#### 1. Connect Firebase to Flutter:
The easiest way is using the official FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
cd admin_app
flutterfire configure
```
Alternatively, download configuration files manually from the Firebase Console:
- **Android**: Place `google-services.json` in `admin_app/android/app/`.
- **iOS**: Place `GoogleService-Info.plist` in `admin_app/ios/Runner/`.

#### 2. Create Your First Administrator User:
1. In **Firebase Console -> Authentication**, click **Add user** (e.g., `admin@college.edu` with a strong password). Copy their **User UID**.
2. In **Firebase Console -> Cloud Firestore**, open the `admins` collection and add a document with **Document ID equal to the copied UID**:
   ```json
   {
     "id": "<PASTE_COPIED_UID_HERE>",
     "name": "Dr. Sarah Jenkins",
     "email": "admin@college.edu",
     "role": "superadmin"
   }
   ```
*(Note: If a user signs in whose UID is not in `/admins`, the app will automatically reject them with an "Access Denied" message).*

#### 3. Run the Admin App:
```bash
cd admin_app
flutter pub get
flutter run
```

---

## 📱 Testing the Student Form Flow

1. Open the Admin App and log in.
2. Go to **Lectures** -> tap **New Lecture** -> fill in session details -> set status to **Active** -> tap **Create Lecture Record**.
3. Tap on the newly created lecture folder card -> switch to the **QR Form** tab.
4. Scan the QR code with any smartphone camera (or copy the URL).
5. Fill in the student feedback form:
   - Notice the lecture topic is locked and pre-populated.
   - Enter your register number (e.g. `23MCA101`).
   - Rate the session and submit.
6. Attempt to submit a second time with the same register number: the system will cleanly reject the duplicate with:
   > *"You have already submitted feedback for this lecture."*
7. Return to the Admin App: the lecture's response count will be updated in real-time.
