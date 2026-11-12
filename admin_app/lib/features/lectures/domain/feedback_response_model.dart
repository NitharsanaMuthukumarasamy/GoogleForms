import 'package:cloud_firestore/cloud_firestore.dart';

/// Allowed options for student feedback questions.
class FeedbackConstants {
  static const List<String> programmes = [
    'MCA',
    'B.Sc. Computer Systems and Design',
    'BCA',
    'B.Sc. Computer Science',
    'Other',
  ];

  static const List<String> yearsOfStudy = [
    'I Year',
    'II Year',
    'III Year',
    'IV Year',
    'V Year',
  ];

  static const List<String> understandingOptions = [
    'Yes, significantly',
    'Yes, to some extent',
    'Not much',
    'No',
  ];

  static const List<String> attendMoreOptions = [
    'Definitely',
    'Probably',
    'Maybe',
    'No',
  ];

  static const List<String> allowedFutureTopics = [
    'Career Guidance',
    'Industry Experience',
    'Artificial Intelligence & Machine Learning',
    'Software Development',
    'Emerging Technologies',
    'Higher Studies',
    'Entrepreneurship',
    'Placement Preparation',
    'Other',
  ];
}

/// Data model representing a student's Feedback Response.
/// The document ID in Firestore is the student's register number (uppercased and trimmed).
class FeedbackResponse {
  final String registerNumber;
  final String name;
  final String email;
  final String programme;
  final String yearOfStudy;
  final String lectureTitle;
  final int relevanceRating;
  final int usefulnessRating;
  final String understandingImproved;
  final String mainTakeaway;
  final String attendMore;
  final List<String> futureTopics;
  final String suggestions;
  final int satisfactionRating;
  final DateTime submittedAt;

  const FeedbackResponse({
    required this.registerNumber,
    required this.name,
    required this.email,
    required this.programme,
    required this.yearOfStudy,
    required this.lectureTitle,
    required this.relevanceRating,
    required this.usefulnessRating,
    required this.understandingImproved,
    required this.mainTakeaway,
    required this.attendMore,
    required this.futureTopics,
    required this.suggestions,
    required this.satisfactionRating,
    required this.submittedAt,
  });

  /// Normalize and trim register number to guarantee uniqueness.
  static String formatRegisterNumber(String raw) => raw.trim().toUpperCase();

  /// Factory constructor to deserialize from a Firestore DocumentSnapshot / Map.
  factory FeedbackResponse.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FeedbackResponse.fromMap(data, registerNumber: doc.id);
  }

  /// Factory constructor to deserialize from Map.
  factory FeedbackResponse.fromMap(Map<String, dynamic> map, {String? registerNumber}) {
    final regNo = registerNumber ?? (map['registerNumber'] as String? ?? '');
    return FeedbackResponse(
      registerNumber: formatRegisterNumber(regNo),
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      programme: map['programme'] as String? ?? '',
      yearOfStudy: map['yearOfStudy'] as String? ?? '',
      lectureTitle: map['lectureTitle'] as String? ?? '',
      relevanceRating: (map['relevanceRating'] as num?)?.toInt() ?? 1,
      usefulnessRating: (map['usefulnessRating'] as num?)?.toInt() ?? 1,
      understandingImproved: map['understandingImproved'] as String? ?? '',
      mainTakeaway: map['mainTakeaway'] as String? ?? '',
      attendMore: map['attendMore'] as String? ?? '',
      futureTopics: List<String>.from(map['futureTopics'] as List? ?? []),
      suggestions: map['suggestions'] as String? ?? '',
      satisfactionRating: (map['satisfactionRating'] as num?)?.toInt() ?? 1,
      submittedAt: _parseDateTime(map['submittedAt']),
    );
  }

  /// Converts the model to a Firestore-compatible Map.
  /// Matches the exact 15 fields expected by Firestore security rules.
  Map<String, dynamic> toMap({bool useServerTimestamp = false}) {
    return {
      'registerNumber': formatRegisterNumber(registerNumber),
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'programme': programme,
      'yearOfStudy': yearOfStudy,
      'lectureTitle': lectureTitle,
      'relevanceRating': relevanceRating,
      'usefulnessRating': usefulnessRating,
      'understandingImproved': understandingImproved,
      'mainTakeaway': mainTakeaway.trim(),
      'attendMore': attendMore,
      'futureTopics': futureTopics,
      'suggestions': suggestions.trim(),
      'satisfactionRating': satisfactionRating,
      'submittedAt': useServerTimestamp ? FieldValue.serverTimestamp() : Timestamp.fromDate(submittedAt),
    };
  }

  /// Helper to parse DateTime from Timestamp or String.
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }
}
