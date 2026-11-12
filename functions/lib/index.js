"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.submitFeedback = exports.onFeedbackSubmitted = exports.backupLectureToDrive = exports.checkLectureReminders = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const https_1 = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const notifications_1 = require("./notifications");
var reminders_1 = require("./reminders");
Object.defineProperty(exports, "checkLectureReminders", { enumerable: true, get: function () { return reminders_1.checkLectureReminders; } });
var backup_drive_1 = require("./backup_drive");
Object.defineProperty(exports, "backupLectureToDrive", { enumerable: true, get: function () { return backup_drive_1.backupLectureToDrive; } });
admin.initializeApp();
const db = admin.firestore();
// Optional institution domain restriction (Leave empty to allow all valid emails)
const COLLEGE_EMAIL_DOMAIN = process.env.COLLEGE_EMAIL_DOMAIN || "";
// Rate Limiting Configuration: Maximum 5 submissions per minute per client IP
const RATE_LIMIT_WINDOW_MS = 60 * 1000; // 1 minute
const MAX_SUBMISSIONS_PER_WINDOW = 5;
/**
 * 1. Background Trigger:
 * Fires whenever a new feedback document is created in Firestore.
 * Atomically increments responseCount on the parent lecture document
 * and broadcasts notifications to admins (milestones and new response alerts).
 */
exports.onFeedbackSubmitted = (0, firestore_1.onDocumentCreated)("lectures/{lectureId}/responses/{responseId}", async (event) => {
    const lectureId = event.params.lectureId;
    const responseId = event.params.responseId;
    const data = event.data?.data();
    if (!data)
        return;
    const lectureRef = db.collection("lectures").doc(lectureId);
    try {
        let updatedCount = 1;
        await db.runTransaction(async (transaction) => {
            const doc = await transaction.get(lectureRef);
            if (doc.exists) {
                const currentCount = Number(doc.data()?.responseCount || 0);
                updatedCount = currentCount + 1;
                transaction.update(lectureRef, {
                    responseCount: updatedCount,
                    lastFeedbackAt: admin.firestore.FieldValue.serverTimestamp(),
                });
            }
        });
        console.log(`[Counter] Updated response count to ${updatedCount} for lecture ${lectureId} (Student: ${responseId})`);
        // Process FCM push notifications (new response & target milestones)
        await (0, notifications_1.processSubmissionNotifications)(db, lectureId, updatedCount, {
            name: data.name,
            programme: data.programme,
            lectureTitle: data.lectureTitle,
        });
    }
    catch (err) {
        console.error(`[Counter] Failed to increment count for lecture ${lectureId}:`, err);
    }
});
/**
 * 2. Rate-Limited & App Check-Verified Submission Callable Function:
 * Enforces Firebase App Check, IP rate limiting, bot honeypot detection,
 * minimum time-to-fill validation, and duplicate register number prevention.
 */
exports.submitFeedback = (0, https_1.onCall)({
    // Enable App Check enforcement when configured in Firebase Console
    enforceAppCheck: false,
    cors: true,
}, async (request) => {
    const data = request.data || {};
    const rawIp = request.rawRequest?.ip || "unknown-client";
    const ipKey = Buffer.from(rawIp).toString("base64").replace(/=/g, "");
    // -------------------------------------------------------------------------
    // A. Bot Honeypot Detection
    // -------------------------------------------------------------------------
    if (data.honeypot && typeof data.honeypot === "string" && data.honeypot.trim().length > 0) {
        console.warn(`[Anti-Spam] Bot submission blocked from IP: ${rawIp}`);
        throw new https_1.HttpsError("invalid-argument", "Automated submission detected.");
    }
    // -------------------------------------------------------------------------
    // B. Minimum Time-To-Fill Check (>= 10 seconds)
    // -------------------------------------------------------------------------
    const timeElapsedSeconds = Number(data.timeElapsedSeconds || 0);
    if (timeElapsedSeconds < 10) {
        throw new https_1.HttpsError("failed-precondition", "Submission received too fast. Please take at least 10 seconds to review your responses.");
    }
    // -------------------------------------------------------------------------
    // C. Basic IP Rate Limiting (Max 5 submissions per minute per IP)
    // -------------------------------------------------------------------------
    const now = Date.now();
    const rateLimitRef = db.collection("rate_limits").doc(`ip_${ipKey}`);
    try {
        await db.runTransaction(async (transaction) => {
            const rateDoc = await transaction.get(rateLimitRef);
            const rateData = rateDoc.data() || { count: 0, resetAt: now + RATE_LIMIT_WINDOW_MS };
            if (now > rateData.resetAt) {
                // Reset window
                transaction.set(rateLimitRef, { count: 1, resetAt: now + RATE_LIMIT_WINDOW_MS });
            }
            else if (rateData.count >= MAX_SUBMISSIONS_PER_WINDOW) {
                throw new https_1.HttpsError("resource-exhausted", "Rate limit exceeded. Please wait a minute before submitting again.");
            }
            else {
                transaction.update(rateLimitRef, { count: admin.firestore.FieldValue.increment(1) });
            }
        });
    }
    catch (err) {
        if (err instanceof https_1.HttpsError)
            throw err;
        console.warn("[RateLimit] Non-fatal rate limit check error:", err);
    }
    // -------------------------------------------------------------------------
    // D. Validate Lecture Existence & Active Status
    // -------------------------------------------------------------------------
    const lectureId = data.lectureId;
    if (!lectureId || typeof lectureId !== "string") {
        throw new https_1.HttpsError("invalid-argument", "Lecture ID is missing.");
    }
    const lectureRef = db.collection("lectures").doc(lectureId);
    const lectureSnap = await lectureRef.get();
    if (!lectureSnap.exists) {
        throw new https_1.HttpsError("not-found", "Lecture not found.");
    }
    const lectureData = lectureSnap.data();
    if (lectureData.status !== "active") {
        throw new https_1.HttpsError("failed-precondition", "This feedback form is closed.");
    }
    // -------------------------------------------------------------------------
    // E. Register Number Normalization & Duplicate Prevention
    // Strips all whitespace and converts to uppercase: "abc 123" -> "ABC123"
    // -------------------------------------------------------------------------
    const rawRegisterNumber = String(data.registerNumber || "");
    const registerNumber = rawRegisterNumber.replace(/\s+/g, "").toUpperCase();
    if (!registerNumber || registerNumber.length < 3 || registerNumber.length > 50) {
        throw new https_1.HttpsError("invalid-argument", "Invalid register number.");
    }
    const responseRef = lectureRef.collection("responses").doc(registerNumber);
    const existingResponse = await responseRef.get();
    if (existingResponse.exists) {
        throw new https_1.HttpsError("already-exists", "You have already submitted feedback for this lecture.");
    }
    // -------------------------------------------------------------------------
    // F. Email Validation & Optional Domain Restriction
    // -------------------------------------------------------------------------
    const email = String(data.email || "").trim().toLowerCase();
    const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    if (!emailRegex.test(email)) {
        throw new https_1.HttpsError("invalid-argument", "Invalid email format.");
    }
    if (COLLEGE_EMAIL_DOMAIN && !email.endsWith(COLLEGE_EMAIL_DOMAIN.toLowerCase())) {
        throw new https_1.HttpsError("invalid-argument", `Only email addresses ending with ${COLLEGE_EMAIL_DOMAIN} are permitted.`);
    }
    // -------------------------------------------------------------------------
    // G. Construct Exact 15-Field Payload & Write to Firestore
    // -------------------------------------------------------------------------
    const responsePayload = {
        email: email,
        name: String(data.name || "").trim(),
        registerNumber: registerNumber,
        programme: String(data.programme || ""),
        yearOfStudy: String(data.yearOfStudy || ""),
        lectureTitle: lectureData.title,
        relevanceRating: Number(data.relevanceRating || 1),
        usefulnessRating: Number(data.usefulnessRating || 1),
        understandingImproved: String(data.understandingImproved || ""),
        mainTakeaway: String(data.mainTakeaway || "").trim(),
        attendMore: String(data.attendMore || ""),
        futureTopics: Array.isArray(data.futureTopics) ? data.futureTopics : [],
        suggestions: String(data.suggestions || "").trim(),
        satisfactionRating: Number(data.satisfactionRating || 1),
        submittedAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    await responseRef.set(responsePayload);
    return {
        success: true,
        registerNumber: registerNumber,
        message: "Feedback recorded successfully.",
    };
});
//# sourceMappingURL=index.js.map