"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendPushToAdmins = sendPushToAdmins;
exports.processSubmissionNotifications = processSubmissionNotifications;
const admin = require("firebase-admin");
/**
 * Sends a push notification to all registered admin FCM tokens.
 */
async function sendPushToAdmins(db, payload) {
    try {
        const adminsSnapshot = await db.collection("admins").get();
        const allTokens = [];
        adminsSnapshot.forEach((doc) => {
            const data = doc.data();
            if (Array.isArray(data.fcmTokens)) {
                for (const token of data.fcmTokens) {
                    if (typeof token === "string" && token.length > 0 && !allTokens.includes(token)) {
                        allTokens.push(token);
                    }
                }
            }
        });
        if (allTokens.length === 0) {
            console.log("[FCM] No admin tokens registered to receive notification.");
            return;
        }
        const response = await admin.messaging().sendEachForMulticast({
            tokens: allTokens,
            notification: {
                title: payload.title,
                body: payload.body,
            },
            data: payload.data || {},
            android: {
                priority: "high",
                notification: {
                    sound: "default",
                    channelId: "lecture_feedback_alerts",
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: "default",
                        badge: 1,
                    },
                },
            },
        });
        console.log(`[FCM] Notification sent: ${response.successCount} succeeded, ${response.failureCount} failed.`);
        // Clean up stale or invalid tokens
        if (response.failureCount > 0) {
            const tokensToRemove = [];
            response.responses.forEach((resp, idx) => {
                if (!resp.success) {
                    const errCode = resp.error?.code;
                    if (errCode === "messaging/invalid-registration-token" ||
                        errCode === "messaging/registration-token-not-registered") {
                        tokensToRemove.push(allTokens[idx]);
                    }
                }
            });
            if (tokensToRemove.length > 0) {
                console.log(`[FCM] Removing ${tokensToRemove.length} stale tokens from admins.`);
                for (const doc of adminsSnapshot.docs) {
                    const data = doc.data();
                    if (Array.isArray(data.fcmTokens)) {
                        const hasStale = data.fcmTokens.some((t) => tokensToRemove.includes(t));
                        if (hasStale) {
                            await doc.ref.update({
                                fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensToRemove),
                            });
                        }
                    }
                }
            }
        }
    }
    catch (error) {
        console.error("[FCM] Error broadcasting notification to admins:", error);
    }
}
/**
 * Handles notifications when a student submits feedback.
 */
async function processSubmissionNotifications(db, lectureId, newCount, responseData) {
    try {
        // 1. Fetch settings to respect admin notification preferences
        const settingsDoc = await db.collection("settings").doc("college_profile").get();
        const settings = settingsDoc.data() || {};
        const notifyNewResponse = settings.notifyOnNewResponse !== false; // default true
        const notifyTargetReached = settings.notifyOnTargetReached !== false; // default true
        // 2. Fetch lecture to inspect responseTarget and title
        const lectureDoc = await db.collection("lectures").doc(lectureId).get();
        if (!lectureDoc.exists)
            return;
        const lecture = lectureDoc.data();
        const lectureTitle = lecture.title || responseData.lectureTitle || "Alumni Lecture";
        const responseTarget = typeof lecture.responseTarget === "number" ? lecture.responseTarget : null;
        // 3. Check Milestone: Has it reached the target?
        if (notifyTargetReached && responseTarget && newCount === responseTarget) {
            await sendPushToAdmins(db, {
                title: "Target Reached! 🎯",
                body: `Your lecture '${lectureTitle}' has reached its target of ${responseTarget} responses!`,
                data: { lectureId: lectureId, type: "target_reached" },
            });
        }
        // 4. Send new response notification if enabled
        if (notifyNewResponse) {
            const studentName = responseData.name || "A student";
            const programme = responseData.programme ? ` (${responseData.programme})` : "";
            await sendPushToAdmins(db, {
                title: `New Response: ${lectureTitle}`,
                body: `${studentName}${programme} just submitted feedback.`,
                data: { lectureId: lectureId, type: "new_response" },
            });
        }
    }
    catch (error) {
        console.error("[Notifications] Error processing feedback notifications:", error);
    }
}
//# sourceMappingURL=notifications.js.map