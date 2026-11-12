/**
 * Firebase Client Configuration & SDK Initializer.
 * Uses Firebase Modular CDN (v10) for maximum browser performance without bundlers.
 */

// Replace the placeholder values below with your Firebase project credentials
// (Found in Firebase Console -> Project Settings -> General -> Your apps -> Web app)
const DEFAULT_FIREBASE_CONFIG = {
  apiKey: "AIzaSyB3t5wbyVme6V4eVVPA4ykdp3jWe6f6Dk4",
  authDomain: "alumni-feedback-5b0e1.firebaseapp.com",
  projectId: "alumni-feedback-5b0e1",
  storageBucket: "alumni-feedback-5b0e1.firebasestorage.app",
  messagingSenderId: "545670362177",
  appId: "1:545670362177:web:7541edff20741f498382c0",
  // Firebase App Check reCAPTCHA v3 Site Key
  // (Found in Firebase Console -> App Check -> Apps -> Register Web App with reCAPTCHA v3)
  appCheckSiteKey: ""
};

// Allow runtime override via window.FIREBASE_CONFIG if set
export const firebaseConfig = window.__FIREBASE_CONFIG__ || DEFAULT_FIREBASE_CONFIG;
