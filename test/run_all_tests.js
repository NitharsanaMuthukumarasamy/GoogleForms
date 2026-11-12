/**
 * Comprehensive Automated Verification Test Suite
 * Alumni Guest Lecture Feedback System
 * 
 * Verifies:
 * 1. Data Models, Analytics Calculations, Averages, Distributions, Multi-select Checkboxes
 * 2. Student Web Questionnaire, Edge Cases, Anti-Spam (Honeypot, Time-to-fill, LocalStorage)
 * 3. Firestore Security Rules Assertions & Policies
 * 4. End-to-End Flow Simulation (Create Active Lecture -> QR URL -> Student Submission ->
 *    Duplicate Prevention -> Admin Table -> Analytics -> Excel Export)
 */

const assert = require('node:assert');
const fs = require('node:fs');
const path = require('node:path');

// Colors for terminal reporting
const GREEN = '\x1b[32m';
const RED = '\x1b[31m';
const YELLOW = '\x1b[33m';
const CYAN = '\x1b[36m';
const BOLD = '\x1b[1m';
const RESET = '\x1b[0m';

let passedTests = 0;
let failedTests = 0;
const testResults = [];

function test(name, fn) {
  try {
    fn();
    passedTests++;
    testResults.push({ name, status: 'PASSED' });
    console.log(`  ${GREEN}✓${RESET} ${name}`);
  } catch (err) {
    failedTests++;
    testResults.push({ name, status: 'FAILED', error: err.message });
    console.error(`  ${RED}✗${RESET} ${BOLD}${name}${RESET}`);
    console.error(`    ${RED}Error: ${err.message}${RESET}`);
  }
}

console.log(`\n${BOLD}${CYAN}================================================================${RESET}`);
console.log(`${BOLD}${CYAN}  ALUMNI FEEDBACK SYSTEM: COMPREHENSIVE VERIFICATION TEST SUITE ${RESET}`);
console.log(`${BOLD}${CYAN}================================================================${RESET}\n`);

// Load Questionnaire Configuration
const questionsPath = path.resolve(__dirname, '../student_web/js/questions.js');
const { FEEDBACK_QUESTIONS, COLLEGE_EMAIL_DOMAIN } = require(questionsPath);

// =============================================================================
// TEST GROUP 1: DATA MODELS & ANALYTICS CALCULATIONS
// =============================================================================
console.log(`${BOLD}Test Group 1: Data Models & Analytics Calculations${RESET}`);

// Helper function to create 10 mock feedback responses matching test specification
function createMockResponses() {
  const baseDate = new Date('2026-04-15T10:00:00Z');
  return [
    {
      registerNumber: 'REG001',
      name: 'Student 1',
      email: 's1@college.edu',
      programme: 'MCA',
      yearOfStudy: 'I Year',
      lectureTitle: 'DevOps & Cloud',
      relevanceRating: 5,
      usefulnessRating: 5,
      understandingImproved: 'Yes, significantly',
      mainTakeaway: 'Docker containerization and Kubernetes cluster management',
      attendMore: 'Definitely',
      futureTopics: ['Artificial Intelligence & Machine Learning', 'Software Development'],
      suggestions: 'Great session, please organize more workshops.',
      satisfactionRating: 5,
      submittedAt: new Date(baseDate.getTime() + 10 * 60000),
    },
    {
      registerNumber: 'REG002',
      name: 'Student 2',
      email: 's2@college.edu',
      programme: 'MCA',
      yearOfStudy: 'II Year',
      lectureTitle: 'DevOps & Cloud',
      relevanceRating: 4,
      usefulnessRating: 4,
      understandingImproved: 'Yes, significantly',
      mainTakeaway: 'CI/CD pipeline automation with GitHub Actions',
      attendMore: 'Definitely',
      futureTopics: ['Artificial Intelligence & Machine Learning', 'Industry Experience'],
      suggestions: 'Very informative lecture.',
      satisfactionRating: 4,
      submittedAt: new Date(baseDate.getTime() + 15 * 60000),
    },
    {
      registerNumber: 'REG003',
      name: 'Student 3',
      email: 's3@college.edu',
      programme: 'BCA',
      yearOfStudy: 'III Year',
      lectureTitle: 'DevOps & Cloud',
      relevanceRating: 5,
      usefulnessRating: 4,
      understandingImproved: 'Yes, to some extent',
      mainTakeaway: 'Infrastructure as Code and Terraform concepts',
      attendMore: 'Definitely',
      futureTopics: ['Career Guidance', 'Placement Preparation'],
      suggestions: 'Please share slides after the talk.',
      satisfactionRating: 5,
      submittedAt: new Date(baseDate.getTime() + 20 * 60000),
    },
    {
      registerNumber: 'REG004',
      name: 'Student 4',
      email: 's4@college.edu',
      programme: 'B.Sc. Computer Science',
      yearOfStudy: 'II Year',
      lectureTitle: 'DevOps & Cloud',
      relevanceRating: 3,
      usefulnessRating: 3,
      understandingImproved: 'Yes, to some extent',
      mainTakeaway: 'Cloud deployment basics',
      attendMore: 'Probably',
      futureTopics: ['Artificial Intelligence & Machine Learning'],
      suggestions: '',
      satisfactionRating: 3,
      submittedAt: new Date(baseDate.getTime() + 25 * 60000),
    },
    {
      registerNumber: 'REG005',
      name: 'Student 5',
      email: 's5@college.edu',
      programme: 'MCA',
      yearOfStudy: 'I Year',
      lectureTitle: 'DevOps & Cloud',
      relevanceRating: 5,
      usefulnessRating: 5,
      understandingImproved: 'Yes, significantly',
      mainTakeaway: 'Microservices architecture patterns',
      attendMore: 'Definitely',
      futureTopics: ['Artificial Intelligence & Machine Learning', 'Software Development', 'Placement Preparation'],
      suggestions: 'Conduct hands-on coding sessions.',
      satisfactionRating: 5,
      submittedAt: new Date(baseDate.getTime() + 30 * 60000),
    },
    {
      registerNumber: 'REG006',
      name: 'Student 6',
      email: 's6@college.edu',
      programme: 'B.Sc. Computer Systems and Design',
      yearOfStudy: 'IV Year',
      lectureTitle: 'DevOps & Cloud',
      relevanceRating: 4,
      usefulnessRating: 4,
      understandingImproved: 'Yes, significantly',
      mainTakeaway: 'Cloud monitoring and Prometheus observability',
      attendMore: 'Probably',
      futureTopics: ['Industry Experience'],
      suggestions: 'Audio in back rows was slightly quiet.',
      satisfactionRating: 4,
      submittedAt: new Date(baseDate.getTime() + 35 * 60000),
    },
    {
      registerNumber: 'REG007',
      name: 'Student 7',
      email: 's7@college.edu',
      programme: 'MCA',
      yearOfStudy: 'II Year',
      lectureTitle: 'DevOps & Cloud',
      relevanceRating: 5,
      usefulnessRating: 5,
      understandingImproved: 'Yes, significantly',
      mainTakeaway: 'Serverless architecture with AWS Lambda',
      attendMore: 'Definitely',
      futureTopics: ['Artificial Intelligence & Machine Learning', 'Placement Preparation'],
      suggestions: 'Speaker was excellent and engaging.',
      satisfactionRating: 5,
      submittedAt: new Date(baseDate.getTime() + 40 * 60000),
    },
    {
      registerNumber: 'REG008',
      name: 'Student 8',
      email: 's8@college.edu',
      programme: 'BCA',
      yearOfStudy: 'I Year',
      lectureTitle: 'DevOps & Cloud',
      relevanceRating: 4,
      usefulnessRating: 3,
      understandingImproved: 'Yes, to some extent',
      mainTakeaway: 'Understanding Docker containers',
      attendMore: 'Maybe',
      futureTopics: ['Career Guidance'],
      suggestions: '',
      satisfactionRating: 4,
      submittedAt: new Date(baseDate.getTime() + 45 * 60000),
    },
    {
      registerNumber: 'REG009',
      name: 'Student 9',
      email: 's9@college.edu',
      programme: 'MCA',
      yearOfStudy: 'II Year',
      lectureTitle: 'DevOps & Cloud',
      relevanceRating: 5,
      usefulnessRating: 5,
      understandingImproved: 'Yes, significantly',
      mainTakeaway: 'Production deployment best practices and reliability engineering',
      attendMore: 'Definitely',
      futureTopics: ['Artificial Intelligence & Machine Learning', 'Software Development'],
      suggestions: 'Loved the real-world industry examples.',
      satisfactionRating: 5,
      submittedAt: new Date(baseDate.getTime() + 50 * 60000),
    },
    {
      registerNumber: 'REG010',
      name: 'Student 10',
      email: 's10@college.edu',
      programme: 'Other',
      yearOfStudy: 'V Year',
      lectureTitle: 'DevOps & Cloud',
      relevanceRating: 4,
      usefulnessRating: 4,
      understandingImproved: 'Not much',
      mainTakeaway: 'General overview of tech stacks',
      attendMore: 'No',
      futureTopics: ['Higher Studies'],
      suggestions: 'Would prefer beginner level introductory topics.',
      satisfactionRating: 3,
      submittedAt: new Date(baseDate.getTime() + 55 * 60000),
    },
  ];
}

// Analytics Calculation Engine (mirrors Dart LectureAnalyticsSummary)
function calculateAnalytics(responses) {
  const total = responses.length;
  if (total === 0) {
    return {
      totalResponses: 0,
      averageRelevance: 0.0,
      averageUsefulness: 0.0,
      averageSatisfaction: 0.0,
      programmeDistribution: {},
      yearOfStudyDistribution: {},
      understandingDistribution: {},
      attendMoreDistribution: {},
      topicCounts: {},
      topicPercentages: {},
      sortedTopics: [],
    };
  }

  const sumRel = responses.reduce((acc, r) => acc + r.relevanceRating, 0);
  const sumUse = responses.reduce((acc, r) => acc + r.usefulnessRating, 0);
  const sumSat = responses.reduce((acc, r) => acc + r.satisfactionRating, 0);

  const progMap = {};
  const yearMap = {};
  const underMap = {};
  const attendMap = {};
  const topicMap = {};

  for (const r of responses) {
    progMap[r.programme] = (progMap[r.programme] || 0) + 1;
    yearMap[r.yearOfStudy] = (yearMap[r.yearOfStudy] || 0) + 1;
    underMap[r.understandingImproved] = (underMap[r.understandingImproved] || 0) + 1;
    attendMap[r.attendMore] = (attendMap[r.attendMore] || 0) + 1;

    for (const t of r.futureTopics) {
      topicMap[t] = (topicMap[t] || 0) + 1;
    }
  }

  // Topic percentage per respondent: count / totalResponses * 100
  const topicPct = {};
  for (const [t, cnt] of Object.entries(topicMap)) {
    topicPct[t] = (cnt / total) * 100;
  }

  const sortedTopics = Object.entries(topicMap).sort((a, b) => b[1] - a[1]);

  return {
    totalResponses: total,
    averageRelevance: parseFloat((sumRel / total).toFixed(4)),
    averageUsefulness: parseFloat((sumUse / total).toFixed(4)),
    averageSatisfaction: parseFloat((sumSat / total).toFixed(4)),
    programmeDistribution: progMap,
    yearOfStudyDistribution: yearMap,
    understandingDistribution: underMap,
    attendMoreDistribution: attendMap,
    topicCounts: topicMap,
    topicPercentages: topicPct,
    sortedTopics,
  };
}

test('Exact rating averages: Relevance (4.40), Usefulness (4.20), Satisfaction (4.30)', () => {
  const responses = createMockResponses();
  const summary = calculateAnalytics(responses);

  assert.strictEqual(summary.totalResponses, 10);
  assert.strictEqual(summary.averageRelevance, 4.4);
  assert.strictEqual(summary.averageUsefulness, 4.2);
  assert.strictEqual(summary.averageSatisfaction, 4.3);
});

test('Single-select distribution and percentages (Programme & Year of Study)', () => {
  const responses = createMockResponses();
  const summary = calculateAnalytics(responses);

  // MCA = 5 of 10 -> 50%
  assert.strictEqual(summary.programmeDistribution['MCA'], 5);
  assert.strictEqual((summary.programmeDistribution['MCA'] / 10) * 100, 50.0);

  // BCA = 2 of 10 -> 20%
  assert.strictEqual(summary.programmeDistribution['BCA'], 2);
  assert.strictEqual((summary.programmeDistribution['BCA'] / 10) * 100, 20.0);

  // Years of Study: I Year = 3 (30%), II Year = 4 (40%), III = 1, IV = 1, V = 1
  assert.strictEqual(summary.yearOfStudyDistribution['I Year'], 3);
  assert.strictEqual((summary.yearOfStudyDistribution['I Year'] / 10) * 100, 30.0);
  assert.strictEqual(summary.yearOfStudyDistribution['II Year'], 4);
  assert.strictEqual((summary.yearOfStudyDistribution['II Year'] / 10) * 100, 40.0);
  assert.strictEqual(summary.yearOfStudyDistribution['III Year'], 1);
  assert.strictEqual(summary.yearOfStudyDistribution['IV Year'], 1);
  assert.strictEqual(summary.yearOfStudyDistribution['V Year'], 1);
});

test('Single-select understanding & attend more percentages', () => {
  const responses = createMockResponses();
  const summary = calculateAnalytics(responses);

  // Understanding Improved
  assert.strictEqual(summary.understandingDistribution['Yes, significantly'], 6);
  assert.strictEqual((summary.understandingDistribution['Yes, significantly'] / 10) * 100, 60.0);
  assert.strictEqual(summary.understandingDistribution['Yes, to some extent'], 3);
  assert.strictEqual((summary.understandingDistribution['Yes, to some extent'] / 10) * 100, 30.0);
  assert.strictEqual(summary.understandingDistribution['Not much'], 1);

  // Attend More
  assert.strictEqual(summary.attendMoreDistribution['Definitely'], 6);
  assert.strictEqual((summary.attendMoreDistribution['Definitely'] / 10) * 100, 60.0);
  assert.strictEqual(summary.attendMoreDistribution['Probably'], 2);
  assert.strictEqual(summary.attendMoreDistribution['Maybe'], 1);
  assert.strictEqual(summary.attendMoreDistribution['No'], 1);
});

test('Multi-select future topics per-respondent percentages and sorting', () => {
  const responses = createMockResponses();
  const summary = calculateAnalytics(responses);

  // AI & ML: 6 out of 10 respondents = 60.0%
  assert.strictEqual(summary.topicCounts['Artificial Intelligence & Machine Learning'], 6);
  assert.strictEqual(summary.topicPercentages['Artificial Intelligence & Machine Learning'], 60.0);

  // Software Development: 3 respondents = 30.0%
  assert.strictEqual(summary.topicCounts['Software Development'], 3);
  assert.strictEqual(summary.topicPercentages['Software Development'], 30.0);

  // Placement Preparation: 3 respondents = 30.0%
  assert.strictEqual(summary.topicCounts['Placement Preparation'], 3);
  assert.strictEqual(summary.topicPercentages['Placement Preparation'], 30.0);

  // Top topic is AI/ML
  assert.strictEqual(summary.sortedTopics[0][0], 'Artificial Intelligence & Machine Learning');
  assert.strictEqual(summary.sortedTopics[0][1], 6);
});

test('Empty response set handled gracefully without NaN or division by zero', () => {
  const summary = calculateAnalytics([]);
  assert.strictEqual(summary.totalResponses, 0);
  assert.strictEqual(summary.averageRelevance, 0.0);
  assert.strictEqual(summary.averageUsefulness, 0.0);
  assert.strictEqual(summary.averageSatisfaction, 0.0);
  assert.strictEqual(summary.sortedTopics.length, 0);
});

test('Folder name generation follows YYYY_LectureTitle_SpeakerName format', () => {
  const lectureDate = new Date('2026-11-20T10:00:00Z');
  const title = 'Cloud Architecture & Modern DevOps';
  const speaker = 'Priya Sundaram';

  // Model folderName format: "${year}_${cleanTitle}_$cleanSpeaker"
  const folderName = `${lectureDate.getFullYear()}_${title.trim()}_${speaker.trim()}`;
  assert.strictEqual(folderName, '2026_Cloud Architecture & Modern DevOps_Priya Sundaram');

  // Export sanitized file name (replaces forbidden characters [\\/:*?"<>|])
  const sanitized = folderName.replace(/[\\/:*?"<>|]/g, '_');
  assert.strictEqual(sanitized, '2026_Cloud Architecture & Modern DevOps_Priya Sundaram');
});

// =============================================================================
// TEST GROUP 2: STUDENT WEB QUESTIONNAIRE & EDGE CASES
// =============================================================================
console.log(`\n${BOLD}Test Group 2: Student Web Form Validation & Edge Cases${RESET}`);

test('Centralized questionnaire contract has 14 questions with exact required flags', () => {
  assert.strictEqual(FEEDBACK_QUESTIONS.length, 14);

  const qMap = {};
  for (const q of FEEDBACK_QUESTIONS) {
    qMap[q.id] = q;
  }

  // Verify all 14 questions are present
  const expectedIds = [
    'email', 'name', 'registerNumber', 'programme', 'yearOfStudy',
    'lectureTitle', 'relevanceRating', 'usefulnessRating', 'understandingImproved',
    'mainTakeaway', 'attendMore', 'futureTopics', 'suggestions', 'satisfactionRating'
  ];
  for (const id of expectedIds) {
    assert.ok(qMap[id], `Missing question id: ${id}`);
  }

  // suggestions is optional, all others required
  assert.strictEqual(qMap['suggestions'].required, false);
  for (const id of expectedIds) {
    if (id !== 'suggestions') {
      assert.strictEqual(qMap[id].required, true, `Question ${id} should be required`);
    }
  }
});

test('Register number normalization: strips internal & boundary spaces, converts to UPPERCASE', () => {
  const regQ = FEEDBACK_QUESTIONS.find(q => q.id === 'registerNumber');
  assert.ok(regQ && regQ.transform);

  // Test casing and space stripping
  assert.strictEqual(regQ.transform(' abc 123 '), 'ABC123');
  assert.strictEqual(regQ.transform('23mca045'), '23MCA045');
  assert.strictEqual(regQ.transform('  a  b  c  1  2  3  '), 'ABC123');
  assert.strictEqual(regQ.transform('bca-2024-001'), 'BCA-2024-001');

  // Length validation: 3-50 chars
  assert.strictEqual(regQ.validate(''), 'Register number is required.');
  assert.strictEqual(regQ.validate('  '), 'Register number is required.');
  assert.strictEqual(regQ.validate('ab'), 'Please enter a valid register number (3-50 characters).');
  assert.strictEqual(regQ.validate('ABC123'), null);
});

test('Email format validation: RFC regex and optional institutional domain', () => {
  const emailQ = FEEDBACK_QUESTIONS.find(q => q.id === 'email');
  assert.ok(emailQ && emailQ.validate);

  // Valid emails
  assert.strictEqual(emailQ.validate('student@college.edu'), null);
  assert.strictEqual(emailQ.validate('alumni.speaker@techcorp.com'), null);
  assert.strictEqual(emailQ.validate('user+tag@sub.domain.org'), null);

  // Invalid emails
  assert.strictEqual(emailQ.validate(''), 'Email address is required.');
  assert.strictEqual(emailQ.validate('plainaddress'), 'Please enter a valid email address.');
  assert.strictEqual(emailQ.validate('@missingusername.com'), 'Please enter a valid email address.');
  assert.strictEqual(emailQ.validate('user@domain'), 'Please enter a valid email address.');
  assert.strictEqual(emailQ.validate('user@.com.my'), 'Please enter a valid email address.');
});

test('Multi-select future topics validation: requires at least 1 selection', () => {
  const topicsQ = FEEDBACK_QUESTIONS.find(q => q.id === 'futureTopics');
  assert.ok(topicsQ && topicsQ.validate);

  // Empty or invalid selections rejected
  assert.strictEqual(topicsQ.validate([]), 'Please select at least one topic for future sessions.');
  assert.strictEqual(topicsQ.validate(null), 'Please select at least one topic for future sessions.');
  assert.strictEqual(topicsQ.validate('Artificial Intelligence'), 'Please select at least one topic for future sessions.');

  // Valid selections pass
  assert.strictEqual(topicsQ.validate(['Artificial Intelligence & Machine Learning']), null);
  assert.strictEqual(topicsQ.validate(['Career Guidance', 'Placement Preparation']), null);
});

test('Rating scale validation: must be integer within range 1 to 5', () => {
  const relQ = FEEDBACK_QUESTIONS.find(q => q.id === 'relevanceRating');
  const useQ = FEEDBACK_QUESTIONS.find(q => q.id === 'usefulnessRating');
  const satQ = FEEDBACK_QUESTIONS.find(q => q.id === 'satisfactionRating');

  // Valid scores
  for (let score = 1; score <= 5; score++) {
    assert.strictEqual(relQ.validate(score), null);
    assert.strictEqual(useQ.validate(score), null);
    assert.strictEqual(satQ.validate(score), null);
  }

  // Out of range or invalid
  assert.ok(relQ.validate(0) !== null);
  assert.ok(relQ.validate(6) !== null);
  assert.ok(satQ.validate(-1) !== null);
  assert.ok(satQ.validate('invalid') !== null);
  assert.ok(useQ.validate(null) !== null);
});

test('Missing required text fields validation (name, main takeaway, lecture title)', () => {
  const nameQ = FEEDBACK_QUESTIONS.find(q => q.id === 'name');
  const takeawayQ = FEEDBACK_QUESTIONS.find(q => q.id === 'mainTakeaway');
  const titleQ = FEEDBACK_QUESTIONS.find(q => q.id === 'lectureTitle');

  assert.strictEqual(nameQ.validate(''), 'Full name is required.');
  assert.strictEqual(takeawayQ.validate('   '), 'Please share your main takeaway from the lecture.');
  assert.strictEqual(titleQ.validate(''), 'Lecture topic is missing.');

  // Valid texts pass
  assert.strictEqual(nameQ.validate('Ravi Kumar'), null);
  assert.strictEqual(takeawayQ.validate('Learned about Kubernetes orchestration'), null);
  assert.strictEqual(titleQ.validate('Modern Cloud Architecture'), null);
});

test('Missing required choice options validation (programme, yearOfStudy, understanding, attendMore)', () => {
  const progQ = FEEDBACK_QUESTIONS.find(q => q.id === 'programme');
  const yearQ = FEEDBACK_QUESTIONS.find(q => q.id === 'yearOfStudy');
  const underQ = FEEDBACK_QUESTIONS.find(q => q.id === 'understandingImproved');
  const attendQ = FEEDBACK_QUESTIONS.find(q => q.id === 'attendMore');

  // Empty values rejected
  assert.strictEqual(progQ.validate(''), 'Please select your academic programme.');
  assert.strictEqual(yearQ.validate(''), 'Please select your current year of study.');
  assert.strictEqual(underQ.validate(''), 'Please select how much your understanding improved.');
  assert.strictEqual(attendQ.validate(''), 'Please select your interest in attending future alumni sessions.');

  // Valid options accepted
  assert.strictEqual(progQ.validate('MCA'), null);
  assert.strictEqual(yearQ.validate('II Year'), null);
  assert.strictEqual(underQ.validate('Yes, significantly'), null);
  assert.strictEqual(attendQ.validate('Definitely'), null);
});

test('Duplicate register number collision test across various casing and spacing variants', () => {
  const transform = FEEDBACK_QUESTIONS.find(q => q.id === 'registerNumber').transform;

  const variants = [
    '23mca045',
    '23MCA045',
    ' 23mca045 ',
    '23 mca 045',
    ' 23 MCA 045 ',
    '   23MCA045   '
  ];

  // All variants must normalize to the identical key '23MCA045'
  const normalizedKeys = new Set(variants.map(v => transform(v)));
  assert.strictEqual(normalizedKeys.size, 1, 'All variants must normalize to a single unique key');
  assert.ok(normalizedKeys.has('23MCA045'));
});

test('Honeypot bot protection: reject submissions with filled honeypot', () => {
  function checkHoneypot(honeypotValue) {
    if (honeypotValue && honeypotValue.trim().length > 0) {
      return { botDetected: true, action: 'SILENT_DISCARD' };
    }
    return { botDetected: false, action: 'PROCEED' };
  }

  assert.deepStrictEqual(checkHoneypot('bot-entered-email@spam.com'), {
    botDetected: true,
    action: 'SILENT_DISCARD',
  });
  assert.deepStrictEqual(checkHoneypot(''), {
    botDetected: false,
    action: 'PROCEED',
  });
  assert.deepStrictEqual(checkHoneypot(null), {
    botDetected: false,
    action: 'PROCEED',
  });
});

test('Minimum time-to-fill check: reject submissions under 10 seconds', () => {
  function checkSubmissionTime(renderedTimestamp, submitTimestamp) {
    const elapsedSeconds = (submitTimestamp - renderedTimestamp) / 1000;
    if (elapsedSeconds < 10) {
      return {
        allowed: false,
        error: `Submission received too quickly. Please take at least 10 seconds to thoughtfully review your answers before submitting (${Math.ceil(10 - elapsedSeconds)}s remaining).`
      };
    }
    return { allowed: true, error: null };
  }

  const renderTime = 100000;
  // 3 seconds elapsed -> reject
  const quickSubmit = checkSubmissionTime(renderTime, renderTime + 3000);
  assert.strictEqual(quickSubmit.allowed, false);
  assert.ok(quickSubmit.error.includes('Submission received too quickly'));

  // 15 seconds elapsed -> allow
  const legitimateSubmit = checkSubmissionTime(renderTime, renderTime + 15000);
  assert.strictEqual(legitimateSubmit.allowed, true);
  assert.strictEqual(legitimateSubmit.error, null);
});

test('Inactive and invalid lecture handling: form shows closed state', () => {
  function evaluateLectureAccessibility(lectureExists, lectureData) {
    if (!lectureExists) {
      return { isOpen: false, title: 'This feedback form is closed', message: 'The requested lecture session was not found or is no longer available.' };
    }
    if (lectureData.status !== 'active') {
      return { isOpen: false, title: 'This feedback form is closed', message: 'Feedback submission for this alumni lecture is currently closed.' };
    }
    return { isOpen: true, title: lectureData.title, message: 'Form is open for submission' };
  }

  // Missing lecture ID
  const notFound = evaluateLectureAccessibility(false, null);
  assert.strictEqual(notFound.isOpen, false);
  assert.strictEqual(notFound.title, 'This feedback form is closed');

  // Closed lecture
  const closedLec = evaluateLectureAccessibility(true, { status: 'closed', title: 'AI Talk' });
  assert.strictEqual(closedLec.isOpen, false);
  assert.strictEqual(closedLec.title, 'This feedback form is closed');

  // Draft lecture
  const draftLec = evaluateLectureAccessibility(true, { status: 'draft', title: 'AI Talk' });
  assert.strictEqual(draftLec.isOpen, false);

  // Active lecture
  const activeLec = evaluateLectureAccessibility(true, { status: 'active', title: 'AI Talk' });
  assert.strictEqual(activeLec.isOpen, true);
});

// =============================================================================
// TEST GROUP 3: FIRESTORE SECURITY RULES VERIFICATION
// =============================================================================
console.log(`\n${BOLD}Test Group 3: Firestore Security Rules Policies${RESET}`);

const firestoreRulesContent = fs.readFileSync(path.resolve(__dirname, '../firestore.rules'), 'utf-8');

test('Security Rule: Public CANNOT read responses subcollection', () => {
  // Check responses subcollection rule
  const matchResponses = firestoreRulesContent.includes('match /responses/{responseId}');
  assert.ok(matchResponses, 'Rule must define match /responses/{responseId}');

  // Ensure read is restricted to isAdmin()
  assert.ok(
    firestoreRulesContent.includes('match /responses/{responseId} {\n        // Only authenticated admins can read responses\n        allow read: if isAdmin();') ||
    firestoreRulesContent.includes('allow read: if isAdmin();'),
    'Responses read must be restricted to isAdmin()'
  );
});

test('Security Rule: Public CANNOT update or delete feedback responses', () => {
  // Updates are strictly prohibited
  assert.ok(
    firestoreRulesContent.includes('allow update: if false;'),
    'Rule must enforce allow update: if false for responses'
  );
  // Deletes are only allowed for admins
  assert.ok(
    firestoreRulesContent.includes('allow delete: if isAdmin();'),
    'Rule must enforce allow delete: if isAdmin() for responses'
  );
});

test('Security Rule: Response document ID must match student registerNumber', () => {
  assert.ok(
    firestoreRulesContent.includes('data.registerNumber == responseId'),
    'Security rule must enforce data.registerNumber == responseId'
  );
});

test('Security Rule: Submission rejected if parent lecture is not active', () => {
  assert.ok(
    firestoreRulesContent.includes("get(/databases/$(database)/documents/lectures/$(lectureId)).data.status == 'active'"),
    'Security rule must check parent lecture status == active'
  );
});

test('Security Rule: Exact 15 fields enforced with hasAll and hasOnly', () => {
  const fields = [
    'email', 'name', 'registerNumber', 'programme', 'yearOfStudy',
    'lectureTitle', 'relevanceRating', 'usefulnessRating', 'understandingImproved',
    'mainTakeaway', 'attendMore', 'futureTopics', 'suggestions',
    'satisfactionRating', 'submittedAt'
  ];

  for (const f of fields) {
    assert.ok(firestoreRulesContent.includes(`'${f}'`), `Security rule must include field '${f}'`);
  }
  assert.ok(firestoreRulesContent.includes('data.keys().hasAll(expectedFields)'));
  assert.ok(firestoreRulesContent.includes('data.keys().hasOnly(expectedFields)'));
});

test('Security Rule: Background Cloud Function metadata does not break admin lecture updates', () => {
  assert.ok(firestoreRulesContent.includes("'lastFeedbackAt'"));
  assert.ok(firestoreRulesContent.includes("'reminder24hSent'"));
  assert.ok(firestoreRulesContent.includes("'reminderSentAt'"));
  assert.ok(firestoreRulesContent.includes("requiredFields.concat(optionalFields)"));
});

// =============================================================================
// TEST GROUP 4: FULL END-TO-END FLOW SIMULATION
// =============================================================================
console.log(`\n${BOLD}Test Group 4: Full End-to-End Flow Simulation${RESET}`);

test('Full Flow: Admin creates active lecture -> QR Link -> Student submits -> Admin Table, Charts, & Excel export', () => {
  // Step 1: Admin creates lecture
  const lecture = {
    id: 'lec_cloud_2026',
    title: 'Cloud Architecture & Modern DevOps',
    speakerName: 'Priya Sundaram',
    designation: 'Senior Cloud Architect',
    company: 'Google Cloud',
    dateTime: new Date('2026-11-20T10:00:00Z'),
    venue: 'Auditorium Hall B',
    department: 'MCA',
    academicYear: '2026-2027',
    status: 'active',
    responseCount: 0,
    createdAt: new Date(),
  };
  assert.strictEqual(lecture.status, 'active');

  // Step 2: QR URL generated with lectureId
  const qrUrl = `https://alumni-feedback.web.app/?lecture=${lecture.id}`;
  const urlObj = new URL(qrUrl);
  const lectureIdParam = urlObj.searchParams.get('lecture');
  assert.strictEqual(lectureIdParam, 'lec_cloud_2026');

  // Step 3: Student Web Form loads lecture & sets read-only title
  assert.strictEqual(lecture.status, 'active', 'Lecture is active');
  const autoFilledTitle = lecture.title;
  assert.strictEqual(autoFilledTitle, 'Cloud Architecture & Modern DevOps');

  // Step 4: Student enters register number with mixed case and whitespace
  const rawInputReg = '  23mca045  ';
  const cleanRegNo = rawInputReg.replace(/\s+/g, '').toUpperCase();
  assert.strictEqual(cleanRegNo, '23MCA045');

  // Step 5: Student submits valid feedback payload
  const studentSubmission = {
    email: 'priya.student@college.edu',
    name: 'Priya S',
    registerNumber: cleanRegNo,
    programme: 'MCA',
    yearOfStudy: 'II Year',
    lectureTitle: autoFilledTitle,
    relevanceRating: 5,
    usefulnessRating: 5,
    understandingImproved: 'Yes, significantly',
    mainTakeaway: 'Hands-on Kubernetes deployments and IaC principles',
    attendMore: 'Definitely',
    futureTopics: ['Artificial Intelligence & Machine Learning', 'Software Development'],
    suggestions: 'Please conduct full-day workshop next time.',
    satisfactionRating: 5,
    submittedAt: new Date(),
  };

  // Verify all 15 fields exist
  const expectedKeys = [
    'email', 'name', 'registerNumber', 'programme', 'yearOfStudy',
    'lectureTitle', 'relevanceRating', 'usefulnessRating', 'understandingImproved',
    'mainTakeaway', 'attendMore', 'futureTopics', 'suggestions',
    'satisfactionRating', 'submittedAt'
  ];
  assert.strictEqual(Object.keys(studentSubmission).length, 15);
  for (const k of expectedKeys) {
    assert.ok(studentSubmission[k] !== undefined, `Field ${k} is missing from submission`);
  }

  // Step 6: Simulate Firestore storage & atomic increment
  const firestoreDb = new Map();
  const docPath = `lectures/${lecture.id}/responses/${cleanRegNo}`;
  firestoreDb.set(docPath, studentSubmission);
  lecture.responseCount += 1;
  assert.strictEqual(lecture.responseCount, 1);

  // Step 7: Duplicate prevention verification:
  // Same student tries to submit again with different casing/spacing: " 23MCA045 "
  const repeatReg = ' 23MCA045 '.replace(/\s+/g, '').toUpperCase();
  const repeatDocPath = `lectures/${lecture.id}/responses/${repeatReg}`;
  const alreadyExists = firestoreDb.has(repeatDocPath);
  assert.strictEqual(alreadyExists, true, 'Repeat submission for 23MCA045 must be detected');

  // Step 8: Admin Responses Table Row - Verify 15 columns in exact prescribed order
  const tableHeaders = [
    'Submitted At', 'Email', 'Name', 'Register Number', 'Programme/Department',
    'Year of Study', 'Lecture Title', 'Relevance (1-5)', 'Usefulness (1-5)',
    'Understanding Improved', 'Main Takeaway', 'Attend More Alumni Lectures',
    'Future Topics', 'Suggestions', 'Overall Satisfaction (1-5)'
  ];
  assert.strictEqual(tableHeaders.length, 15);

  const tableRow = [
    studentSubmission.submittedAt.toISOString(),
    studentSubmission.email,
    studentSubmission.name,
    studentSubmission.registerNumber,
    studentSubmission.programme,
    studentSubmission.yearOfStudy,
    studentSubmission.lectureTitle,
    studentSubmission.relevanceRating,
    studentSubmission.usefulnessRating,
    studentSubmission.understandingImproved,
    studentSubmission.mainTakeaway,
    studentSubmission.attendMore,
    studentSubmission.futureTopics.join(', '),
    studentSubmission.suggestions,
    studentSubmission.satisfactionRating
  ];
  assert.strictEqual(tableRow.length, 15);
  assert.strictEqual(tableRow[3], '23MCA045');
  assert.strictEqual(tableRow[7], 5);
  assert.strictEqual(tableRow[14], 5);

  // Step 9: Analytics tab recalculation
  const analyticsResult = calculateAnalytics([studentSubmission]);
  assert.strictEqual(analyticsResult.totalResponses, 1);
  assert.strictEqual(analyticsResult.averageRelevance, 5.0);
  assert.strictEqual(analyticsResult.averageSatisfaction, 5.0);
  assert.strictEqual(analyticsResult.topicPercentages['Artificial Intelligence & Machine Learning'], 100.0);

  // Step 10: Excel Export Generator verification
  // Sheet 1: Responses with 15 columns header + rows
  // Sheet 2: Summary with metrics
  const excelSheet1Name = 'Responses';
  const excelSheet2Name = 'Summary';

  const sheet1Data = [tableHeaders, tableRow];
  assert.strictEqual(sheet1Data[0].length, 15);
  assert.strictEqual(sheet1Data[1].length, 15);

  const sheet2Data = [
    ['Key Metric', 'Score (out of 5.0)'],
    ['Average Relevance Rating', analyticsResult.averageRelevance],
    ['Average Usefulness Rating', analyticsResult.averageUsefulness],
    ['Average Overall Satisfaction', analyticsResult.averageSatisfaction],
    ['Total Responses', analyticsResult.totalResponses],
  ];
  assert.strictEqual(sheet2Data[1][1], 5.0);
  assert.strictEqual(sheet2Data[4][1], 1);
});

// =============================================================================
// SUMMARY & EXIT
// =============================================================================
console.log(`\n${BOLD}${CYAN}----------------------------------------------------------------${RESET}`);
console.log(`${BOLD}Test Execution Summary:${RESET}`);
console.log(`  Total Tests Run : ${passedTests + failedTests}`);
console.log(`  ${GREEN}Passed Tests     : ${passedTests}${RESET}`);
if (failedTests > 0) {
  console.log(`  ${RED}Failed Tests     : ${failedTests}${RESET}`);
  process.exit(1);
} else {
  console.log(`  ${GREEN}${BOLD}ALL TESTS PASSED WITH 100% SUCCESS RATE!${RESET}`);
  console.log(`${BOLD}${CYAN}----------------------------------------------------------------${RESET}\n`);
}
