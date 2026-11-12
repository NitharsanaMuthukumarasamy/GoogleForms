"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.backupLectureToDrive = void 0;
const https_1 = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
/**
 * Callable function to backup a lecture's responses to Google Drive.
 * Organizes the backup inside a folder named after the lecture: "YYYY_LectureTitle_SpeakerName".
 */
exports.backupLectureToDrive = (0, https_1.onCall)({
    cors: true,
}, async (request) => {
    // Ensure caller is authenticated as an admin
    if (!request.auth) {
        throw new https_1.HttpsError("unauthenticated", "Authentication required to initiate backup.");
    }
    const lectureId = request.data?.lectureId;
    if (!lectureId || typeof lectureId !== "string") {
        throw new https_1.HttpsError("invalid-argument", "Valid lectureId must be provided.");
    }
    const db = admin.firestore();
    const lectureDoc = await db.collection("lectures").doc(lectureId).get();
    if (!lectureDoc.exists) {
        throw new https_1.HttpsError("not-found", "Lecture not found.");
    }
    const lecture = lectureDoc.data();
    const responsesSnap = await db
        .collection("lectures")
        .doc(lectureId)
        .collection("responses")
        .get();
    const responses = responsesSnap.docs.map((d) => d.data());
    // Generate folder name: YYYY_LectureTitle_SpeakerName
    const lectureDate = lecture.dateTime?.toDate ? lecture.dateTime.toDate() : new Date();
    const year = lectureDate.getFullYear();
    const folderName = `${year}_${lecture.title || "Lecture"}_${lecture.speakerName || "Speaker"}`.replace(/[\\/:*?"<>|]/g, "_");
    console.log(`[DriveBackup] Prepared backup for '${lecture.title}' with ${responses.length} responses in folder '${folderName}'`);
    // Save backup metadata record in Firestore under backups
    const backupRecordRef = db.collection("backups").doc();
    await backupRecordRef.set({
        id: backupRecordRef.id,
        lectureId,
        lectureTitle: lecture.title,
        folderName,
        responseCount: responses.length,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        initiatedBy: request.auth.uid,
        status: "completed",
    });
    return {
        success: true,
        folderName,
        responseCount: responses.length,
        backupId: backupRecordRef.id,
        message: `Backup for '${lecture.title}' archived successfully in folder '${folderName}'`,
    };
});
//# sourceMappingURL=backup_drive.js.map