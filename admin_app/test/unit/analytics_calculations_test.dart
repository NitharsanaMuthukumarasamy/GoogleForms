import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/features/lectures/domain/feedback_response_model.dart';
import 'package:admin_app/features/lectures/domain/lecture_analytics_model.dart';

void main() {
  group('Analytics Calculations & Metrics Tests', () {
    // 10 mock student feedback responses for precise percentage and average testing
    List<FeedbackResponse> createMockResponses() {
      final baseDate = DateTime(2026, 4, 15, 10, 0);

      return [
        FeedbackResponse(
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
          submittedAt: baseDate.add(const Duration(minutes: 10)),
        ),
        FeedbackResponse(
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
          submittedAt: baseDate.add(const Duration(minutes: 15)),
        ),
        FeedbackResponse(
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
          submittedAt: baseDate.add(const Duration(minutes: 20)),
        ),
        FeedbackResponse(
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
          submittedAt: baseDate.add(const Duration(minutes: 25)),
        ),
        FeedbackResponse(
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
          submittedAt: baseDate.add(const Duration(minutes: 30)),
        ),
        FeedbackResponse(
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
          submittedAt: baseDate.add(const Duration(minutes: 35)),
        ),
        FeedbackResponse(
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
          submittedAt: baseDate.add(const Duration(minutes: 40)),
        ),
        FeedbackResponse(
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
          submittedAt: baseDate.add(const Duration(minutes: 45)),
        ),
        FeedbackResponse(
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
          submittedAt: baseDate.add(const Duration(minutes: 50)),
        ),
        FeedbackResponse(
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
          submittedAt: baseDate.add(const Duration(minutes: 55)),
        ),
      ];
    }

    test('should calculate exact rating averages out of 5.0', () {
      final responses = createMockResponses();
      final analytics = LectureAnalyticsSummary.fromResponses(responses);

      expect(analytics.totalResponses, equals(10));

      // Relevance ratings: 5, 4, 5, 3, 5, 4, 5, 4, 5, 4 = 44 / 10 = 4.40
      expect(analytics.averageRelevance, closeTo(4.4, 0.001));

      // Usefulness ratings: 5, 4, 4, 3, 5, 4, 5, 3, 5, 4 = 42 / 10 = 4.20
      expect(analytics.averageUsefulness, closeTo(4.2, 0.001));

      // Satisfaction ratings: 5, 4, 5, 3, 5, 4, 5, 4, 5, 3 = 43 / 10 = 4.30
      expect(analytics.averageSatisfaction, closeTo(4.3, 0.001));
    });

    test('should calculate single-select category counts and exact percentages', () {
      final responses = createMockResponses();
      final analytics = LectureAnalyticsSummary.fromResponses(responses);

      // Programme counts: MCA = 5 (50%), BCA = 2 (20%), B.Sc CS = 1 (10%), B.Sc CSD = 1 (10%), Other = 1 (10%)
      expect(analytics.programmeDistribution['MCA'], equals(5));
      expect(analytics.programmeDistribution['BCA'], equals(2));
      final mcaPct = (analytics.programmeDistribution['MCA']! / analytics.totalResponses) * 100;
      expect(mcaPct, equals(50.0));

      // Attend More counts: Definitely = 6 (60%), Probably = 2 (20%), Maybe = 1 (10%), No = 1 (10%)
      expect(analytics.attendMoreDistribution['Definitely'], equals(6));
      expect(analytics.attendMoreDistribution['Probably'], equals(2));
      expect(analytics.attendMoreDistribution['Maybe'], equals(1));
      expect(analytics.attendMoreDistribution['No'], equals(1));
      final definitelyPct = (analytics.attendMoreDistribution['Definitely']! / analytics.totalResponses) * 100;
      expect(definitelyPct, equals(60.0));

      // Understanding Improved: Yes significantly = 6 (60%), Yes to some extent = 3 (30%), Not much = 1 (10%)
      expect(analytics.understandingDistribution['Yes, significantly'], equals(6));
      expect(analytics.understandingDistribution['Yes, to some extent'], equals(3));
      expect(analytics.understandingDistribution['Not much'], equals(1));
      expect(analytics.understandingDistribution['No'], equals(0));
    });

    test('should calculate multi-select checkbox topics percentages per respondent', () {
      final responses = createMockResponses();
      final analytics = LectureAnalyticsSummary.fromResponses(responses);

      // Multi-select counts across 10 respondents:
      // AI & ML: chosen by REG001, REG002, REG004, REG005, REG007, REG009 = 6 out of 10 respondents = 60.0%
      // Software Development: REG001, REG005, REG009 = 3 respondents = 30.0%
      // Placement Preparation: REG003, REG005, REG007 = 3 respondents = 30.0%
      // Industry Experience: REG002, REG006 = 2 respondents = 20.0%
      // Career Guidance: REG003, REG008 = 2 respondents = 20.0%
      // Higher Studies: REG010 = 1 respondent = 10.0%
      final topicsMap = Map.fromEntries(analytics.sortedTopics);

      expect(topicsMap['Artificial Intelligence & Machine Learning'], equals(6));
      expect(topicsMap['Software Development'], equals(3));
      expect(topicsMap['Placement Preparation'], equals(3));
      expect(topicsMap['Industry Experience'], equals(2));
      expect(topicsMap['Career Guidance'], equals(2));
      expect(topicsMap['Higher Studies'], equals(1));

      // Sorted descending check: AI & ML should be rank #1
      expect(analytics.sortedTopics.first.key, equals('Artificial Intelligence & Machine Learning'));
      expect(analytics.sortedTopics.first.value, equals(6));

      // Multi-select percentage calculation formula check: count / totalResponses * 100
      final aiPct = (topicsMap['Artificial Intelligence & Machine Learning']! / analytics.totalResponses) * 100;
      expect(aiPct, equals(60.0));

      final placementPct = (topicsMap['Placement Preparation']! / analytics.totalResponses) * 100;
      expect(placementPct, equals(30.0));
    });

    test('should handle empty responses gracefully without division by zero', () {
      final analytics = LectureAnalyticsSummary.fromResponses([]);

      expect(analytics.totalResponses, equals(0));
      expect(analytics.averageRelevance, equals(0.0));
      expect(analytics.averageUsefulness, equals(0.0));
      expect(analytics.averageSatisfaction, equals(0.0));
      expect(analytics.sortedTopics, isEmpty);
      expect(analytics.mainTakeaways, isEmpty);
      expect(analytics.suggestions, isEmpty);
    });

    test('extractKeywords filters stop words and returns frequent terms', () {
      final texts = [
        'Great session on cloud architecture and Docker containers',
        'Loved the Docker containers and deployment automation',
        'Docker is essential for modern cloud environments',
      ];

      final keywords = LectureAnalyticsSummary.extractKeywords(texts, topN: 5);
      final wordKeys = keywords.map((e) => e.key).toList();

      expect(wordKeys, contains('docker'));
      expect(wordKeys, contains('cloud'));
      expect(wordKeys, isNot(contains('and'))); // Stop word eliminated
      expect(wordKeys, isNot(contains('the'))); // Stop word eliminated
    });
  });
}
