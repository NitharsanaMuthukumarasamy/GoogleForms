/**
 * Centralized Feedback Questionnaire Configuration.
 * All questions, validation rules, types, and options are defined here in one place.
 * Field IDs match the Cloud Firestore schema exact 15-field contract.
 */

// Optional: Restrict submissions to an institutional domain (e.g., "@college.edu").
// Leave empty ("") by default to allow any valid email format.
const COLLEGE_EMAIL_DOMAIN = "";

const FEEDBACK_QUESTIONS = [
  {
    id: 'email',
    title: 'Email',
    description: COLLEGE_EMAIL_DOMAIN 
      ? `Please provide your official college email (${COLLEGE_EMAIL_DOMAIN}).`
      : 'We will send a copy of your response confirmation.',
    type: 'email',
    required: true,
    placeholder: COLLEGE_EMAIL_DOMAIN ? `student${COLLEGE_EMAIL_DOMAIN}` : 'student@college.edu',
    validate: (val) => {
      if (!val || !val.trim()) return 'Email address is required.';
      const regex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9]+([.-][a-zA-Z0-9]+)*\.[a-zA-Z]{2,}$/;
      const email = val.trim().toLowerCase();
      if (!regex.test(email)) return 'Please enter a valid email address.';
      if (COLLEGE_EMAIL_DOMAIN && !email.endsWith(COLLEGE_EMAIL_DOMAIN.toLowerCase())) {
        return `Only email addresses ending with ${COLLEGE_EMAIL_DOMAIN} are permitted.`;
      }
      return null;
    }
  },
  {
    id: 'name',
    title: 'Student Full Name',
    type: 'text',
    required: true,
    placeholder: 'Enter your full name',
    validate: (val) => {
      if (!val || !val.trim()) return 'Full name is required.';
      if (val.trim().length > 100) return 'Name must be under 100 characters.';
      return null;
    }
  },
  {
    id: 'registerNumber',
    title: 'Register Number / Roll Number',
    description: 'Unique student identifier (spaces are stripped and uppercased, e.g. "abc 123" becomes "ABC123"). Duplicate submissions are rejected.',
    type: 'text',
    required: true,
    placeholder: 'e.g., 23MCA101',
    // Strips all whitespace and converts to uppercase
    transform: (val) => (val || '').replace(/\s+/g, '').toUpperCase(),
    validate: (val) => {
      const clean = (val || '').replace(/\s+/g, '').toUpperCase();
      if (!clean) return 'Register number is required.';
      if (clean.length < 3 || clean.length > 50) return 'Please enter a valid register number (3-50 characters).';
      return null;
    }
  },
  {
    id: 'programme',
    title: 'Programme / Department',
    type: 'radio',
    required: true,
    options: [
      'MCA',
      'B.Sc. Computer Systems and Design',
      'BCA',
      'B.Sc. Computer Science',
      'Other'
    ],
    validate: (val) => {
      if (!val) return 'Please select your academic programme.';
      return null;
    }
  },
  {
    id: 'yearOfStudy',
    title: 'Year of Study',
    type: 'radio',
    required: true,
    options: [
      'I Year',
      'II Year',
      'III Year',
      'IV Year',
      'V Year'
    ],
    validate: (val) => {
      if (!val) return 'Please select your current year of study.';
      return null;
    }
  },
  {
    id: 'lectureTitle',
    title: 'Title / Topic of the Lecture',
    description: 'Auto-populated from the verified alumni lecture schedule. Read-only.',
    type: 'readonly',
    required: true,
    validate: (val) => {
      if (!val || !val.trim()) return 'Lecture topic is missing.';
      return null;
    }
  },
  {
    id: 'relevanceRating',
    title: 'How relevant was the lecture to your course and studies?',
    type: 'scale',
    required: true,
    minScale: 1,
    maxScale: 5,
    minLabel: 'Not Relevant',
    maxLabel: 'Highly Relevant',
    validate: (val) => {
      const num = parseInt(val, 10);
      if (isNaN(num) || num < 1 || num > 5) return 'Please select a relevance rating between 1 and 5.';
      return null;
    }
  },
  {
    id: 'usefulnessRating',
    title: 'How useful was the information shared?',
    type: 'scale',
    required: true,
    minScale: 1,
    maxScale: 5,
    minLabel: 'Not Useful',
    maxLabel: 'Very Useful',
    validate: (val) => {
      const num = parseInt(val, 10);
      if (isNaN(num) || num < 1 || num > 5) return 'Please select a usefulness rating between 1 and 5.';
      return null;
    }
  },
  {
    id: 'understandingImproved',
    title: 'Did the lecture improve your understanding of the topic?',
    type: 'radio',
    required: true,
    options: [
      'Yes, significantly',
      'Yes, to some extent',
      'Not much',
      'No'
    ],
    validate: (val) => {
      if (!val) return 'Please select how much your understanding improved.';
      return null;
    }
  },
  {
    id: 'mainTakeaway',
    title: 'What was your main takeaway from the lecture?',
    description: 'Key insights, concepts, technologies, or advice shared by the alumni speaker.',
    type: 'textarea',
    required: true,
    placeholder: 'Share what you found most valuable or interesting...',
    validate: (val) => {
      if (!val || !val.trim()) return 'Please share your main takeaway from the lecture.';
      if (val.trim().length > 2000) return 'Response must be within 2000 characters.';
      return null;
    }
  },
  {
    id: 'attendMore',
    title: 'Would you like to attend more lectures by alumni?',
    type: 'radio',
    required: true,
    options: [
      'Definitely',
      'Probably',
      'Maybe',
      'No'
    ],
    validate: (val) => {
      if (!val) return 'Please select your interest in attending future alumni sessions.';
      return null;
    }
  },
  {
    id: 'futureTopics',
    title: 'Which topics would you like alumni to discuss in future sessions?',
    description: 'Select all topics of interest (at least 1 required).',
    type: 'checkbox',
    required: true,
    options: [
      'Career Guidance',
      'Industry Experience',
      'Artificial Intelligence & Machine Learning',
      'Software Development',
      'Emerging Technologies',
      'Higher Studies',
      'Entrepreneurship',
      'Placement Preparation',
      'Other'
    ],
    validate: (val) => {
      if (!Array.isArray(val) || val.length === 0) {
        return 'Please select at least one topic for future sessions.';
      }
      return null;
    }
  },
  {
    id: 'suggestions',
    title: 'What suggestions do you have for improving future alumni lectures?',
    description: 'Any feedback regarding audio, venue, session duration, interactive Q&A, etc.',
    type: 'textarea',
    required: false,
    placeholder: 'Optional suggestions or feedback...',
    validate: (val) => {
      if (val && val.trim().length > 2000) {
        return 'Suggestions must be within 2000 characters.';
      }
      return null;
    }
  },
  {
    id: 'satisfactionRating',
    title: 'Overall, how satisfied are you with this alumni guest lecture?',
    type: 'scale',
    required: true,
    minScale: 1,
    maxScale: 5,
    minLabel: 'Very Dissatisfied',
    maxLabel: 'Very Satisfied',
    validate: (val) => {
      const num = parseInt(val, 10);
      if (isNaN(num) || num < 1 || num > 5) return 'Please select your overall satisfaction rating.';
      return null;
    }
  }
];

if (typeof module !== 'undefined' && module.exports) {
  module.exports = { FEEDBACK_QUESTIONS, COLLEGE_EMAIL_DOMAIN };
}
