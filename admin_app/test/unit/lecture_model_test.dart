import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/features/lectures/domain/lecture_model.dart';

void main() {
  group('Lecture Model Tests', () {
    final testDate = DateTime(2026, 3, 15, 10, 30);
    final testCreatedAt = DateTime(2026, 3, 1, 9, 0);

    test('should construct a valid Lecture instance with all fields', () {
      final lecture = Lecture(
        id: 'lec_101',
        title: 'Cloud DevOps Architecture',
        speakerName: 'Priya Sundaram',
        designation: 'Staff DevOps Engineer',
        company: 'Google',
        dateTime: testDate,
        venue: 'Auditorium Hall B',
        department: 'MCA',
        academicYear: '2026-2027',
        status: LectureStatus.active,
        createdAt: testCreatedAt,
        responseCount: 42,
        responseTarget: 100,
      );

      expect(lecture.id, equals('lec_101'));
      expect(lecture.title, equals('Cloud DevOps Architecture'));
      expect(lecture.speakerName, equals('Priya Sundaram'));
      expect(lecture.designation, equals('Staff DevOps Engineer'));
      expect(lecture.company, equals('Google'));
      expect(lecture.dateTime, equals(testDate));
      expect(lecture.venue, equals('Auditorium Hall B'));
      expect(lecture.department, equals('MCA'));
      expect(lecture.academicYear, equals('2026-2027'));
      expect(lecture.status, equals(LectureStatus.active));
      expect(lecture.createdAt, equals(testCreatedAt));
      expect(lecture.responseCount, equals(42));
      expect(lecture.responseTarget, equals(100));
    });

    test('should format folderName strictly as "YYYY_LectureTitle_SpeakerName"', () {
      final lecture = Lecture(
        id: 'lec_001',
        title: 'AI In Healthcare',
        speakerName: 'Dr. Anand Raman',
        designation: 'AI Director',
        company: 'HealthTech',
        dateTime: DateTime(2026, 11, 20),
        venue: 'Seminar Hall',
        department: 'BCA',
        academicYear: '2026-2027',
        status: LectureStatus.active,
        createdAt: testCreatedAt,
      );

      expect(lecture.folderName, equals('2026_AI In Healthcare_Dr. Anand Raman'));
    });

    test('should serialize toMap matching Firestore security rules schema', () {
      final lecture = Lecture(
        id: 'lec_002',
        title: 'Modern Web Performance',
        speakerName: 'Suresh Kumar',
        designation: 'Lead Architect',
        company: 'Amazon',
        dateTime: testDate,
        venue: 'Lab 3',
        department: 'Information Technology',
        academicYear: '2025-2026',
        status: LectureStatus.draft,
        createdAt: testCreatedAt,
        responseCount: 15,
        responseTarget: 50,
      );

      final map = lecture.toMap();

      expect(map['id'], equals('lec_002'));
      expect(map['title'], equals('Modern Web Performance'));
      expect(map['speakerName'], equals('Suresh Kumar'));
      expect(map['status'], equals('draft'));
      expect(map['responseCount'], equals(15));
      expect(map['responseTarget'], equals(50));
      expect(map.containsKey('dateTime'), isTrue);
      expect(map.containsKey('createdAt'), isTrue);
    });

    test('should deserialize correctly fromMap and handle missing responseTarget', () {
      final map = {
        'title': 'Cybersecurity Fundamentals',
        'speakerName': 'Kavita Nair',
        'designation': 'Security Consultant',
        'company': 'PwC',
        'dateTime': '2026-04-10T14:00:00.000',
        'venue': 'Hall A',
        'department': 'MCA',
        'academicYear': '2026-2027',
        'status': 'closed',
        'createdAt': '2026-04-01T09:00:00.000',
        'responseCount': 88,
      };

      final lecture = Lecture.fromMap(map, id: 'lec_003');

      expect(lecture.id, equals('lec_003'));
      expect(lecture.title, equals('Cybersecurity Fundamentals'));
      expect(lecture.status, equals(LectureStatus.closed));
      expect(lecture.responseCount, equals(88));
      expect(lecture.responseTarget, isNull);
    });

    test('should copyWith modified values correctly preserving immutability', () {
      final original = Lecture(
        id: 'lec_004',
        title: 'Original Title',
        speakerName: 'Speaker One',
        designation: 'Engineer',
        company: 'Corp',
        dateTime: testDate,
        venue: 'Room 1',
        department: 'MCA',
        academicYear: '2026-2027',
        status: LectureStatus.draft,
        createdAt: testCreatedAt,
        responseTarget: 50,
      );

      final updated = original.copyWith(
        title: 'Updated Title',
        status: LectureStatus.active,
        responseCount: 10,
        responseTarget: 75,
      );

      expect(updated.id, equals(original.id));
      expect(updated.title, equals('Updated Title'));
      expect(updated.status, equals(LectureStatus.active));
      expect(updated.responseCount, equals(10));
      expect(updated.responseTarget, equals(75));
      expect(updated.speakerName, equals(original.speakerName));
    });
  });
}
