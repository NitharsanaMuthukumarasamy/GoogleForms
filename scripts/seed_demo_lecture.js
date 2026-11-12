const admin = require('../functions/node_modules/firebase-admin');
const fs = require('fs');
const path = require('path');
const QRCode = require('qrcode');

admin.initializeApp({
  projectId: 'alumni-feedback-5b0e1'
});

const db = admin.firestore();

async function createDemoLectureAndQR() {
  const lectureId = 'guest-lecture-2026';
  const lectureUrl = `https://alumni-feedback-5b0e1.web.app/?lecture=${lectureId}`;

  const lectureData = {
    id: lectureId,
    title: 'Cloud Architecture & Modern DevOps',
    speakerName: 'Priya Sundaram (Class of 2018)',
    designation: 'Senior Software Architect',
    company: 'Google Cloud',
    venue: 'Auditorium Hall B',
    department: 'MCA',
    academicYear: '2026-2027',
    dateTime: admin.firestore.Timestamp.fromDate(new Date('2026-11-20T10:00:00Z')),
    status: 'active',
    responseCount: 0,
    responseTarget: 50,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  console.log('Writing active lecture to Firestore...');
  await db.collection('lectures').doc(lectureId).set(lectureData);
  console.log('✓ Successfully created lecture:', lectureId);

  // Generate QR Code PNG
  const outPath = path.resolve(__dirname, '../guest_lecture_qr.png');
  await QRCode.toFile(outPath, lectureUrl, {
    width: 600,
    margin: 2,
    color: {
      dark: '#0B2545',
      light: '#FFFFFF'
    }
  });
  console.log('✓ Generated QR Code image at:', outPath);
  console.log('✓ Live Form URL:', lectureUrl);
}

createDemoLectureAndQR().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
