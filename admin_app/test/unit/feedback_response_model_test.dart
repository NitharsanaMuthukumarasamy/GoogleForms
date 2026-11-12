import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/features/lectures/domain/feedback_response_model.dart';

void main() {
  group('FeedbackResponse Model Tests', () {
    test('formatRegisterNumber strips all whitespace and converts to uppercase', () {
      expect(FeedbackResponse.formatRegisterNumber('abc 123'), equals('ABC 123'.replaceAll(' ', '')));
      expect(FeedbackResponse.formatRegisterNumber('  23mca045  '), equals('23MCA045'));
      expect(FeedbackResponse.formatRegisterNumber('cs-101 '), equals('CS-101'));
      expect(FeedbackResponse.formatRegisterNumber('a b c d'), equals('ABCD'));
    });

    test('should construct a valid FeedbackResponse with all 15 questions', () {
      final now = DateTime(2026, 3, 15, 12, 45);
      final response = FeedbackResponse(
        registerNumber: '23MCA101',
        name: 'Arun Kumar',
        email: 'arun@college.edu',
        programme: 'MCA',
        yearOfStudy: 'II Year',
        lectureTitle: 'Cloud Architecture',
        relevanceRating: 5,
        usefulnessRating: 4,
        understandingImproved: 'Yes, significantly',
        mainTakeaway: 'Understanding microservices and serverless scalability.',
        attendMore: 'Definitely',
        futureTopics: ['Artificial Intelligence & Machine Learning', 'Software Development'],
        suggestions: 'More hands-on lab sessions would be helpful.',
        satisfactionRating: 5,
        submittedAt: now,
      );

      expect(response.registerNumber, equals('23MCA101'));
      expect(response.name, equals('Arun Kumar'));
      expect(response.email, equals('arun@college.edu'));
      expect(response.programme, equals('MCA'));
      expect(response.yearOfStudy, equals('II Year'));
      expect(response.lectureTitle, equals('Cloud Architecture'));
      expect(response.relevanceRating, equals(5));
      expect(response.usefulnessRating, equals(4));
      expect(response.understandingImproved, equals('Yes, significantly'));
      expect(response.mainTakeaway, contains('microservices'));
      expect(response.attendMore, equals('Definitely'));
      expect(response.futureTopics.length, equals(2));
      expect(response.suggestions, contains('hands-on'));
      expect(response.satisfactionRating, equals(5));
      expect(response.submittedAt, equals(now));
    });

    test('should deserialize from Map and normalize registerNumber', () {
      final map = {
        'registerNumber': ' 24bca099 ',
        'name': 'Deepa S',
        'email': 'deepa@college.edu',
        'programme': 'BCA',
        'yearOfStudy': 'I Year',
        'lectureTitle': 'Web Architecture',
        'relevanceRating': 4,
        'usefulnessRating': 5,
        'understandingImproved': 'Yes, to some extent',
        'mainTakeaway': 'Full stack tips',
        'attendMore': 'Probably',
        'futureTopics': ['Career Guidance'],
        'suggestions': '',
        'satisfactionRating': 4,
        'submittedAt': '2026-03-15T13:00:00.000',
      };

      final response = FeedbackResponse.fromMap(map, registerNumber: '24bca099');

      expect(response.registerNumber, equals('24BCA099'));
      expect(response.name, equals('Deepa S'));
      expect(response.relevanceRating, equals(4));
      expect(response.satisfactionRating, equals(4));
      expect(response.futureTopics, contains('Career Guidance'));
    });

    test('FeedbackConstants should contain verified allowed options', () {
      expect(FeedbackConstants.programmes, contains('MCA'));
      expect(FeedbackConstants.programmes, contains('BCA'));
      expect(FeedbackConstants.yearsOfStudy.length, equals(5));
      expect(FeedbackConstants.understandingOptions, contains('Yes, significantly'));
      expect(FeedbackConstants.attendMoreOptions, contains('Definitely'));
      expect(FeedbackConstants.allowedFutureTopics.length, equals(9));
    });
  });
}
