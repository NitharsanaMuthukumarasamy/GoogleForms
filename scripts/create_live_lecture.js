const fs = require('fs');
const path = require('path');

async function main() {
  const config = JSON.parse(fs.readFileSync('C:/Users/Admin/.config/configstore/firebase-tools.json', 'utf8'));
  const accessToken = config.tokens.access_token;
  const projectId = 'alumni-feedback-5b0e1';
  const lectureId = 'guest-lecture-2026';

  const firestoreUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/lectures?documentId=${lectureId}`;

  const payload = {
    fields: {
      id: { stringValue: lectureId },
      title: { stringValue: 'Cloud Architecture & Modern DevOps' },
      speakerName: { stringValue: 'Priya Sundaram (Class of 2018)' },
      designation: { stringValue: 'Senior Software Architect' },
      company: { stringValue: 'Google Cloud' },
      venue: { stringValue: 'Auditorium Hall B' },
      department: { stringValue: 'MCA' },
      academicYear: { stringValue: '2026-2027' },
      dateTime: { timestampValue: '2026-11-20T10:00:00Z' },
      status: { stringValue: 'active' },
      createdAt: { timestampValue: new Date().toISOString() },
      responseCount: { integerValue: '0' }
    }
  };

  console.log('Sending request to Firestore REST API...');
  const res = await fetch(firestoreUrl, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(payload)
  });

  const resData = await res.json();
  if (!res.ok) {
    // If it already exists (409 conflict), try PATCH
    if (res.status === 409) {
      console.log('Lecture document already exists. Patching...');
      const patchUrl = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents/lectures/${lectureId}`;
      const patchRes = await fetch(patchUrl, {
        method: 'PATCH',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
      });
      const patchData = await patchRes.json();
      console.log('Patch result:', patchData.name || patchData);
    } else {
      console.error('Firestore API error:', res.status, resData);
      process.exit(1);
    }
  } else {
    console.log('✓ Successfully created lecture document in Firestore:', resData.name);
  }

  // Print the live URL
  const liveUrl = `https://${projectId}.web.app/?lecture=${lectureId}`;
  console.log('✓ Live Form URL:', liveUrl);
}

main().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
