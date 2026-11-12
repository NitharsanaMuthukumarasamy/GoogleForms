import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import { sendPushToAdmins } from "./notifications";

/**
 * Scheduled check: Checks for active lectures whose date & time was >24 hours ago.
 * Sends a reminder notification to the admin: "Remember to close the feedback form for '<title>'."
 */
export const checkLectureReminders = onSchedule(
  {
    schedule: "every 2 hours",
    timeZone: "UTC",
  },
  async () => {
    const db = admin.firestore();

    // Check if 24h reminders are enabled in settings
    const settingsDoc = await db.collection("settings").doc("college_profile").get();
    if (settingsDoc.exists && settingsDoc.data()?.notifyReminder24h === false) {
      console.log("[Reminders] 24h reminders are disabled in settings.");
      return;
    }

    const now = Date.now();
    const cutoff = new Date(now - 24 * 60 * 60 * 1000);

    try {
      const snapshot = await db
        .collection("lectures")
        .where("status", "==", "active")
        .where("dateTime", "<=", admin.firestore.Timestamp.fromDate(cutoff))
        .get();

      console.log(`[Reminders] Found ${snapshot.size} candidate lectures passed 24h mark.`);

      for (const doc of snapshot.docs) {
        const lecture = doc.data();
        if (!lecture.reminder24hSent) {
          await sendPushToAdmins(db, {
            title: "Reminder: Close Feedback Form",
            body: `Remember to close the feedback form for '${lecture.title}'.`,
            data: { lectureId: doc.id, type: "reminder_close_form" },
          });

          await doc.ref.update({
            reminder24hSent: true,
            reminderSentAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          console.log(`[Reminders] Reminder sent for lecture: ${lecture.title}`);
        }
      }
    } catch (err) {
      console.error("[Reminders] Error checking lecture reminders:", err);
    }
  }
);
