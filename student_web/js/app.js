import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.12.2/firebase-app.js';
import {
  getFirestore,
  doc,
  getDoc,
  setDoc,
  serverTimestamp,
  updateDoc,
  increment,
  collection,
  query,
  where,
  limit,
  getDocs
} from 'https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js';
import {
  initializeAppCheck,
  ReCaptchaV3Provider
} from 'https://www.gstatic.com/firebasejs/10.12.2/firebase-app-check.js';
import { firebaseConfig } from './firebase-config.js';

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// Initialize Firebase App Check (reCAPTCHA v3) if site key is configured
if (firebaseConfig.appCheckSiteKey && firebaseConfig.appCheckSiteKey.trim().length > 0) {
  try {
    initializeAppCheck(app, {
      provider: new ReCaptchaV3Provider(firebaseConfig.appCheckSiteKey),
      isTokenAutoRefreshEnabled: true
    });
    console.log('Firebase App Check (reCAPTCHA v3) enabled.');
  } catch (err) {
    console.warn('App Check setup note:', err);
  }
}

// State
let currentLecture = null;
let currentLectureId = null;
let formRenderedTimestamp = null; // Track minimum time-to-fill (>= 10 seconds)

// DOM Elements
const loadingState = document.getElementById('loadingState');
const closedState = document.getElementById('closedState');
const alreadySubmittedState = document.getElementById('alreadySubmittedState');
const thankYouState = document.getElementById('thankYouState');
const formContainer = document.getElementById('formContainer');
const questionsContainer = document.getElementById('questionsContainer');
const lectureDetailsCard = document.getElementById('lectureDetailsCard');
const progressBarFill = document.getElementById('progressBarFill');
const progressText = document.getElementById('progressText');
const feedbackForm = document.getElementById('feedbackForm');
const submitBtn = document.getElementById('submitBtn');
const clearBtn = document.getElementById('clearBtn');
const clearModal = document.getElementById('clearModal');
const cancelClearBtn = document.getElementById('cancelClearBtn');
const confirmClearBtn = document.getElementById('confirmClearBtn');
const spamAlertBanner = document.getElementById('spamAlertBanner');
const spamAlertText = document.getElementById('spamAlertText');
const honeypotInput = document.getElementById('form_hp_secondary_email');

/**
 * Initialize Web Form Application
 */
async function initApp() {
  const urlParams = new URLSearchParams(window.location.search);
  // Support ?lecture=<id> as primary, fallback to ?id=<id>
  currentLectureId = urlParams.get('lecture') || urlParams.get('id');

  try {
    if (!currentLectureId) {
      // 1. Constant QR Code Mode: Automatically load the currently Active lecture
      const q = query(collection(db, 'lectures'), where('status', '==', 'active'), limit(1));
      const activeSnaps = await getDocs(q);

      if (!activeSnaps.empty) {
        const activeDoc = activeSnaps.docs[0];
        currentLectureId = activeDoc.id;
        currentLecture = activeDoc.data();
      } else {
        showClosedState('No Active Lecture', 'There is currently no active alumni lecture accepting feedback. Please check back when your session begins.');
        return;
      }
    } else {
      // 2. Specific Lecture ID Mode: Load the exact lecture
      const lectureRef = doc(db, 'lectures', currentLectureId);
      const lectureSnap = await getDoc(lectureRef);

      if (!lectureSnap.exists()) {
        showClosedState('This feedback form is closed', 'The requested lecture session was not found or is no longer available.');
        return;
      }

      currentLecture = lectureSnap.data();

      // Verify Active status
      if (currentLecture.status !== 'active') {
        showClosedState(
          'This feedback form is closed',
          'Feedback submission for this alumni lecture is currently closed. If you believe this is an error, please reach out to your session coordinator.'
        );
        return;
      }
    }

    // Browser LocalStorage Protection: Block immediate repeat attempts on same browser
    const storageKey = `alumni_feedback_submitted_${currentLectureId}`;
    if (localStorage.getItem(storageKey)) {
      showAlreadySubmitted();
      return;
    }

    // Render Form
    renderLectureCard(currentLecture);
    renderQuestions(currentLecture);
    updateProgress();

    // Start timer for minimum time-to-fill check (minimum 10 seconds)
    formRenderedTimestamp = Date.now();

    loadingState.classList.add('hidden');
    formContainer.classList.remove('hidden');

  } catch (error) {
    console.error('Error fetching lecture:', error);
    if (error?.code === 'permission-denied' || error?.message?.includes('permission-denied')) {
      showClosedState(
        'This feedback form is closed',
        'Feedback submission for this alumni lecture is currently closed or unavailable.'
      );
    } else {
      showClosedState('Error Connecting', 'Unable to reach the feedback servers. Please check your network connection and scan again.');
    }
  }
}

/**
 * Renders Lecture Overview Header Card
 */
function renderLectureCard(lecture) {
  document.getElementById('lectureTitleDisplay').textContent = lecture.title || 'Alumni Lecture';
  document.getElementById('lectureSpeakerDisplay').textContent =
    `${lecture.speakerName || 'Distinguished Alumni'} • ${lecture.designation || ''}, ${lecture.company || ''}`;

  let formattedDate = 'Scheduled Session';
  if (lecture.dateTime) {
    const d = lecture.dateTime.toDate ? lecture.dateTime.toDate() : new Date(lecture.dateTime);
    formattedDate = d.toLocaleDateString('en-US', {
      weekday: 'long',
      month: 'short',
      day: 'numeric',
      year: 'numeric'
    });
  }

  document.getElementById('lectureMetaDisplay').textContent =
    `Date: ${formattedDate} | Venue: ${lecture.venue || 'College Auditorium'} | Dept: ${lecture.department || 'All Departments'}`;
}

/**
 * Renders Questionnaire Cards from FEEDBACK_QUESTIONS
 */
function renderQuestions(lecture) {
  questionsContainer.innerHTML = '';

  FEEDBACK_QUESTIONS.forEach((q) => {
    const card = document.createElement('div');
    card.className = 'card question-card';
    card.id = `card_${q.id}`;
    card.dataset.questionId = q.id;

    // Header with Title & Asterisk
    const titleRow = document.createElement('div');
    titleRow.className = 'question-title';
    titleRow.innerHTML = `${q.title} ${q.required ? '<span class="required-star">*</span>' : ''}`;
    card.appendChild(titleRow);

    // Optional Description
    if (q.description) {
      const desc = document.createElement('div');
      desc.className = 'question-desc';
      desc.textContent = q.description;
      card.appendChild(desc);
    }

    // Question Input Type Renderers
    const inputWrapper = document.createElement('div');
    inputWrapper.className = 'question-input-wrap';

    switch (q.type) {
      case 'readonly':
        inputWrapper.innerHTML = `
          <input type="text" class="input-field readonly-input" 
                 id="field_${q.id}" name="${q.id}" 
                 value="${escapeHtml(lecture.title || '')}" readonly />
        `;
        break;

      case 'text':
      case 'email':
        inputWrapper.innerHTML = `
          <input type="${q.type === 'email' ? 'email' : 'text'}" 
                 class="input-field" 
                 id="field_${q.id}" 
                 name="${q.id}" 
                 placeholder="${q.placeholder || ''}" 
                 autocomplete="off" />
        `;
        break;

      case 'textarea':
        inputWrapper.innerHTML = `
          <textarea class="input-field" 
                    id="field_${q.id}" 
                    name="${q.id}" 
                    rows="3" 
                    placeholder="${q.placeholder || ''}"></textarea>
        `;
        break;

      case 'radio': {
        const group = document.createElement('div');
        group.className = 'options-group';
        q.options.forEach((opt, optIndex) => {
          const optLabel = document.createElement('label');
          optLabel.className = 'option-label';
          optLabel.innerHTML = `
            <input type="radio" class="option-input" 
                   name="${q.id}" value="${escapeHtml(opt)}" 
                   id="opt_${q.id}_${optIndex}" />
            <span>${escapeHtml(opt)}</span>
          `;
          group.appendChild(optLabel);
        });
        inputWrapper.appendChild(group);
        break;
      }

      case 'checkbox': {
        const group = document.createElement('div');
        group.className = 'options-group';
        q.options.forEach((opt, optIndex) => {
          const optLabel = document.createElement('label');
          optLabel.className = 'option-label';
          optLabel.innerHTML = `
            <input type="checkbox" class="option-input" 
                   name="${q.id}" value="${escapeHtml(opt)}" 
                   id="opt_${q.id}_${optIndex}" />
            <span>${escapeHtml(opt)}</span>
          `;
          group.appendChild(optLabel);
        });
        inputWrapper.appendChild(group);
        break;
      }

      case 'scale': {
        const scaleWrap = document.createElement('div');
        scaleWrap.className = 'scale-wrapper';

        const scaleBtns = document.createElement('div');
        scaleBtns.className = 'scale-options';

        for (let i = q.minScale; i <= q.maxScale; i++) {
          const btnLabel = document.createElement('label');
          btnLabel.className = 'scale-btn-label';
          btnLabel.innerHTML = `
            <input type="radio" name="${q.id}" value="${i}" class="hidden" />
            <span class="scale-number">${i}</span>
          `;
          scaleBtns.appendChild(btnLabel);
        }

        const endpoints = document.createElement('div');
        endpoints.className = 'scale-endpoints';
        endpoints.innerHTML = `
          <span>${escapeHtml(q.minLabel || '1')}</span>
          <span>${escapeHtml(q.maxLabel || '5')}</span>
        `;

        scaleWrap.appendChild(scaleBtns);
        scaleWrap.appendChild(endpoints);
        inputWrapper.appendChild(scaleWrap);
        break;
      }
    }

    // Error Message Placeholder
    const errorDiv = document.createElement('div');
    errorDiv.className = 'error-message';
    errorDiv.id = `error_${q.id}`;
    errorDiv.innerHTML = `
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
        <circle cx="12" cy="12" r="10"></circle>
        <line x1="12" y1="8" x2="12" y2="12"></line>
        <line x1="12" y1="16" x2="12.01" y2="16"></line>
      </svg>
      <span class="error-text">This is a required question</span>
    `;

    card.appendChild(inputWrapper);
    card.appendChild(errorDiv);
    questionsContainer.appendChild(card);
  });

  setupInputListeners();
}

/**
 * Setup Event Listeners for UI state and Real-Time Validation
 */
function setupInputListeners() {
  // Register Number Auto-Format: Remove internal/leading/trailing spaces & Uppercase
  const regInput = document.getElementById('field_registerNumber');
  if (regInput) {
    regInput.addEventListener('input', (e) => {
      e.target.value = e.target.value.replace(/\s+/g, '').toUpperCase();
    });
  }

  // Radio button visual selection
  document.querySelectorAll('.option-input[type="radio"]').forEach((radio) => {
    radio.addEventListener('change', (e) => {
      const name = e.target.name;
      document.querySelectorAll(`input[name="${name}"]`).forEach((r) => {
        r.closest('.option-label')?.classList.toggle('selected', r.checked);
      });
      clearCardError(name);
      hideSpamAlert();
      updateProgress();
    });
  });

  // Checkbox visual selection
  document.querySelectorAll('.option-input[type="checkbox"]').forEach((box) => {
    box.addEventListener('change', (e) => {
      e.target.closest('.option-label')?.classList.toggle('selected', e.target.checked);
      clearCardError(e.target.name);
      hideSpamAlert();
      updateProgress();
    });
  });

  // Scale buttons visual selection
  document.querySelectorAll('.scale-btn-label input[type="radio"]').forEach((scaleRadio) => {
    scaleRadio.addEventListener('change', (e) => {
      const name = e.target.name;
      document.querySelectorAll(`input[name="${name}"]`).forEach((r) => {
        r.closest('.scale-btn-label')?.classList.toggle('selected', r.checked);
      });
      clearCardError(name);
      hideSpamAlert();
      updateProgress();
    });
  });

  // Text inputs real-time update
  document.querySelectorAll('input.input-field, textarea.input-field').forEach((input) => {
    input.addEventListener('input', (e) => {
      clearCardError(e.target.name);
      hideSpamAlert();
      updateProgress();
    });
  });
}

function clearCardError(questionId) {
  const card = document.getElementById(`card_${questionId}`);
  if (card) {
    card.classList.remove('has-error');
  }
}

function showSpamAlert(message) {
  if (spamAlertBanner && spamAlertText) {
    spamAlertText.textContent = message;
    spamAlertBanner.classList.remove('hidden');
    spamAlertBanner.scrollIntoView({ behavior: 'smooth', block: 'center' });
  }
}

function hideSpamAlert() {
  if (spamAlertBanner) {
    spamAlertBanner.classList.add('hidden');
  }
}

/**
 * Updates Live Progress Bar
 */
function updateProgress() {
  const answers = getFormValues();
  let answeredRequired = 0;
  const totalRequired = FEEDBACK_QUESTIONS.filter((q) => q.required).length;

  FEEDBACK_QUESTIONS.forEach((q) => {
    if (!q.required) return;
    const val = answers[q.id];
    if (val !== undefined && val !== null && val !== '') {
      if (Array.isArray(val) && val.length === 0) return;
      answeredRequired++;
    }
  });

  const percentage = Math.round((answeredRequired / totalRequired) * 100);
  progressBarFill.style.width = `${percentage}%`;
  progressText.textContent = `${answeredRequired} of ${totalRequired} answered (${percentage}%)`;
}

/**
 * Extracts Current Form Answers Object
 */
function getFormValues() {
  const values = {};

  FEEDBACK_QUESTIONS.forEach((q) => {
    if (q.type === 'readonly') {
      values[q.id] = currentLecture ? currentLecture.title : '';
    } else if (q.type === 'radio' || q.type === 'scale') {
      const checked = document.querySelector(`input[name="${q.id}"]:checked`);
      values[q.id] = checked ? checked.value : '';
    } else if (q.type === 'checkbox') {
      const checkedBoxes = document.querySelectorAll(`input[name="${q.id}"]:checked`);
      values[q.id] = Array.from(checkedBoxes).map((c) => c.value);
    } else {
      const input = document.getElementById(`field_${q.id}`);
      values[q.id] = input ? input.value : '';
    }

    if (q.transform && typeof q.transform === 'function') {
      values[q.id] = q.transform(values[q.id]);
    }
  });

  return values;
}

/**
 * Validates All Questions and Highlights Errors
 */
function validateForm() {
  const values = getFormValues();
  let firstErrorCard = null;
  let hasErrors = false;

  FEEDBACK_QUESTIONS.forEach((q) => {
    const card = document.getElementById(`card_${q.id}`);
    const errorEl = card.querySelector('.error-text');
    const val = values[q.id];

    let errorMsg = null;
    if (q.validate && typeof q.validate === 'function') {
      errorMsg = q.validate(val, values);
    }

    if (errorMsg) {
      hasErrors = true;
      card.classList.add('has-error');
      if (errorEl) errorEl.textContent = errorMsg;
      if (!firstErrorCard) firstErrorCard = card;
    } else {
      card.classList.remove('has-error');
    }
  });

  if (firstErrorCard) {
    firstErrorCard.scrollIntoView({ behavior: 'smooth', block: 'center' });
  }

  return !hasErrors;
}

/**
 * Handles Form Submission with Anti-Spam & Duplicate Defense
 */
feedbackForm.addEventListener('submit', async (e) => {
  e.preventDefault();
  hideSpamAlert();

  // 1. Anti-Bot Honeypot Defense:
  // If the invisible honeypot field was filled in, it was submitted by an automated bot.
  if (honeypotInput && honeypotInput.value && honeypotInput.value.trim().length > 0) {
    console.warn('Bot detected via honeypot trap.');
    setSubmitting(true);
    // Simulate short network delay, then silently discard
    setTimeout(() => {
      setSubmitting(false);
      showThankYou();
    }, 1500);
    return;
  }

  // 2. Minimum Time-To-Fill Defense (>= 10 seconds):
  // Humans take at least 10-30s to read and fill 14 questions. Scripts submit instantaneously.
  if (formRenderedTimestamp) {
    const secondsElapsed = (Date.now() - formRenderedTimestamp) / 1000;
    if (secondsElapsed < 10) {
      const waitRemaining = Math.ceil(10 - secondsElapsed);
      showSpamAlert(
        `Submission received too quickly. Please take at least 10 seconds to thoughtfully review your answers before submitting (${waitRemaining}s remaining).`
      );
      return;
    }
  }

  // 3. Question-level Field Validation
  if (!validateForm()) {
    return;
  }

  const formData = getFormValues();

  // 4. Strict Normalization: All whitespace stripped + Uppercased
  // "abc 123", " abc123 ", and "ABC123" all become "ABC123"
  const registerNumber = (formData.registerNumber || '').replace(/\s+/g, '').toUpperCase();

  // 5. Browser LocalStorage Guard: Repeat check
  const storageKey = `alumni_feedback_submitted_${currentLectureId}`;
  if (localStorage.getItem(storageKey)) {
    showAlreadySubmitted();
    return;
  }

  // Set Loading UI
  setSubmitting(true);

  try {
    const responseRef = doc(db, 'lectures', currentLectureId, 'responses', registerNumber);

    // 6. Prepare exact 15-field payload matching Firestore security rules contract
    const payload = {
      email: formData.email.trim().toLowerCase(),
      name: formData.name.trim(),
      registerNumber: registerNumber,
      programme: formData.programme,
      yearOfStudy: formData.yearOfStudy,
      lectureTitle: currentLecture.title,
      relevanceRating: parseInt(formData.relevanceRating, 10),
      usefulnessRating: parseInt(formData.usefulnessRating, 10),
      understandingImproved: formData.understandingImproved,
      mainTakeaway: formData.mainTakeaway.trim(),
      attendMore: formData.attendMore,
      futureTopics: formData.futureTopics,
      suggestions: (formData.suggestions || '').trim(),
      satisfactionRating: parseInt(formData.satisfactionRating, 10),
      submittedAt: serverTimestamp()
    };

    // 8. Commit response to Firestore
    await setDoc(responseRef, payload);

    // 9. Persist browser lock flag in LocalStorage
    localStorage.setItem(storageKey, JSON.stringify({
      submittedAt: Date.now(),
      registerNumber: registerNumber
    }));

    // 10. Update lecture responseCount
    try {
      await updateDoc(doc(db, 'lectures', currentLectureId), {
        responseCount: increment(1)
      });
    } catch (_) {
      // Ignored if client security rule delegates lecture update to Cloud Functions
    }

    setSubmitting(false);
    showThankYou();

  } catch (error) {
    setSubmitting(false);
    console.error('Submission error:', error);

    // Handle permission-denied (fires when document already exists under security rules or lecture inactive)
    if (error.code === 'permission-denied') {
      localStorage.setItem(storageKey, 'true');
      showAlreadySubmitted();
    } else {
      showSpamAlert('Failed to submit response. Please check your network connection and try again.');
    }
  }
});

function setSubmitting(isSubmitting) {
  submitBtn.disabled = isSubmitting;
  clearBtn.disabled = isSubmitting;
  if (isSubmitting) {
    submitBtn.innerHTML = '<span class="spinner"></span> <span>Submitting...</span>';
  } else {
    submitBtn.innerHTML = '<span>Submit Response</span>';
  }
}

/**
 * State Screen Displays
 */
function showClosedState(title, desc) {
  loadingState.classList.add('hidden');
  formContainer.classList.add('hidden');
  alreadySubmittedState.classList.add('hidden');
  thankYouState.classList.add('hidden');

  document.getElementById('closedStateTitle').textContent = title;
  document.getElementById('closedStateDesc').textContent = desc;
  closedState.classList.remove('hidden');
}

function showAlreadySubmitted() {
  loadingState.classList.add('hidden');
  formContainer.classList.add('hidden');
  alreadySubmittedState.classList.remove('hidden');
  thankYouState.classList.add('hidden');
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function showThankYou() {
  formContainer.classList.add('hidden');
  thankYouState.classList.remove('hidden');
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

/**
 * Clear Form Confirmation Modal
 */
clearBtn.addEventListener('click', () => {
  clearModal.style.display = 'flex';
});

cancelClearBtn.addEventListener('click', () => {
  clearModal.style.display = 'none';
});

confirmClearBtn.addEventListener('click', () => {
  clearModal.style.display = 'none';
  feedbackForm.reset();

  document.querySelectorAll('.option-label, .scale-btn-label').forEach((el) => {
    el.classList.remove('selected');
  });

  document.querySelectorAll('.question-card').forEach((card) => {
    card.classList.remove('has-error');
  });

  // Re-fill readonly lecture title
  if (currentLecture) {
    const lectureTitleInput = document.getElementById('field_lectureTitle');
    if (lectureTitleInput) lectureTitleInput.value = currentLecture.title || '';
  }

  hideSpamAlert();
  updateProgress();
  window.scrollTo({ top: 0, behavior: 'smooth' });
});

function escapeHtml(str) {
  return (str || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

// Start
initApp();
