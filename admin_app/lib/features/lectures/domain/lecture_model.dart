import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum representing the lifecycle status of a lecture.
enum LectureStatus {
  draft('draft'),
  active('active'),
  closed('closed');

  final String value;
  const LectureStatus(this.value);

  static LectureStatus fromString(String status) {
    return LectureStatus.values.firstWhere(
      (e) => e.value.toLowerCase() == status.toLowerCase(),
      orElse: () => LectureStatus.draft,
    );
  }
}

/// Data model representing an Alumni Lecture.
class Lecture {
  final String id;
  final String title;
  final String speakerName;
  final String designation;
  final String company;
  final DateTime dateTime;
  final String venue;
  final String department;
  final String academicYear;
  final LectureStatus status;
  final DateTime createdAt;
  final int responseCount;
  final int? responseTarget;

  const Lecture({
    required this.id,
    required this.title,
    required this.speakerName,
    required this.designation,
    required this.company,
    required this.dateTime,
    required this.venue,
    required this.department,
    required this.academicYear,
    required this.status,
    required this.createdAt,
    this.responseCount = 0,
    this.responseTarget,
  });

  /// Folder-style name: "YYYY_LectureTitle_SpeakerName"
  String get folderName {
    final year = dateTime.year.toString();
    final cleanTitle = title.trim();
    final cleanSpeaker = speakerName.trim();
    return '${year}_${cleanTitle}_$cleanSpeaker';
  }

  /// Factory constructor to deserialize from a Firestore DocumentSnapshot / Map.
  factory Lecture.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Lecture.fromMap(data, id: doc.id);
  }

  /// Factory constructor to deserialize from Map.
  factory Lecture.fromMap(Map<String, dynamic> map, {required String id}) {
    return Lecture(
      id: id,
      title: map['title'] as String? ?? '',
      speakerName: map['speakerName'] as String? ?? '',
      designation: map['designation'] as String? ?? '',
      company: map['company'] as String? ?? '',
      dateTime: _parseDateTime(map['dateTime']),
      venue: map['venue'] as String? ?? '',
      department: map['department'] as String? ?? '',
      academicYear: map['academicYear'] as String? ?? '',
      status: LectureStatus.fromString(map['status'] as String? ?? 'draft'),
      createdAt: _parseDateTime(map['createdAt']),
      responseCount: (map['responseCount'] as num?)?.toInt() ?? 0,
      responseTarget: (map['responseTarget'] as num?)?.toInt(),
    );
  }

  /// Converts the model to a Firestore-compatible Map matching security rules schema.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'speakerName': speakerName,
      'designation': designation,
      'company': company,
      'dateTime': Timestamp.fromDate(dateTime),
      'venue': venue,
      'department': department,
      'academicYear': academicYear,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'responseCount': responseCount,
      if (responseTarget != null) 'responseTarget': responseTarget,
    };
  }

  /// Immutability copyWith method.
  Lecture copyWith({
    String? id,
    String? title,
    String? speakerName,
    String? designation,
    String? company,
    DateTime? dateTime,
    String? venue,
    String? department,
    String? academicYear,
    LectureStatus? status,
    DateTime? createdAt,
    int? responseCount,
    int? responseTarget,
  }) {
    return Lecture(
      id: id ?? this.id,
      title: title ?? this.title,
      speakerName: speakerName ?? this.speakerName,
      designation: designation ?? this.designation,
      company: company ?? this.company,
      dateTime: dateTime ?? this.dateTime,
      venue: venue ?? this.venue,
      department: department ?? this.department,
      academicYear: academicYear ?? this.academicYear,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      responseCount: responseCount ?? this.responseCount,
      responseTarget: responseTarget ?? this.responseTarget,
    );
  }

  /// Helper to robustly parse DateTime from Timestamp, String, or int.
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
