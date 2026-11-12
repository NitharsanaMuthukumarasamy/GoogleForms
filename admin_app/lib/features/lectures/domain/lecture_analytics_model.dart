import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'feedback_response_model.dart';
import 'lecture_model.dart';

/// Single data point for time-series charts.
class TimeSeriesPoint {
  final DateTime timestamp;
  final String label;
  final int count;

  const TimeSeriesPoint({
    required this.timestamp,
    required this.label,
    required this.count,
  });
}

/// Trend data point for a lecture in academic year order.
class LectureRatingTrendPoint {
  final String lectureId;
  final String title;
  final String speakerName;
  final DateTime dateTime;
  final int responseCount;
  final double averageSatisfaction;
  final double averageRelevance;
  final double averageUsefulness;

  const LectureRatingTrendPoint({
    required this.lectureId,
    required this.title,
    required this.speakerName,
    required this.dateTime,
    required this.responseCount,
    required this.averageSatisfaction,
    required this.averageRelevance,
    required this.averageUsefulness,
  });
}

/// Statistics and metrics for a single lecture's feedback responses.
class LectureAnalyticsSummary {
  final int totalResponses;
  final double averageRelevance;
  final Map<int, int> relevanceDistribution; // 1 to 5
  final double averageUsefulness;
  final Map<int, int> usefulnessDistribution; // 1 to 5
  final double averageSatisfaction;
  final Map<int, int> satisfactionDistribution; // 1 to 5

  final Map<String, int> programmeDistribution;
  final Map<String, int> yearDistribution;
  final Map<String, int> understandingDistribution;
  final Map<String, int> attendMoreDistribution;
  final List<MapEntry<String, int>> sortedTopics; // Sorted descending

  final List<TimeSeriesPoint> hourlyTimeSeries;
  final List<TimeSeriesPoint> dailyTimeSeries;

  final List<String> mainTakeaways;
  final List<String> suggestions;
  final List<MapEntry<String, int>> commonTakeawayWords;
  final List<MapEntry<String, int>> commonSuggestionWords;

  const LectureAnalyticsSummary({
    required this.totalResponses,
    required this.averageRelevance,
    required this.relevanceDistribution,
    required this.averageUsefulness,
    required this.usefulnessDistribution,
    required this.averageSatisfaction,
    required this.satisfactionDistribution,
    required this.programmeDistribution,
    required this.yearDistribution,
    required this.understandingDistribution,
    required this.attendMoreDistribution,
    required this.sortedTopics,
    required this.hourlyTimeSeries,
    required this.dailyTimeSeries,
    required this.mainTakeaways,
    required this.suggestions,
    required this.commonTakeawayWords,
    required this.commonSuggestionWords,
  });

  /// Factory to compute all analytics from a list of feedback responses.
  factory LectureAnalyticsSummary.fromResponses(List<FeedbackResponse> responses) {
    if (responses.isEmpty) {
      return LectureAnalyticsSummary(
        totalResponses: 0,
        averageRelevance: 0.0,
        relevanceDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        averageUsefulness: 0.0,
        usefulnessDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        averageSatisfaction: 0.0,
        satisfactionDistribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        programmeDistribution: {},
        yearDistribution: {for (var y in FeedbackConstants.yearsOfStudy) y: 0},
        understandingDistribution: {for (var u in FeedbackConstants.understandingOptions) u: 0},
        attendMoreDistribution: {for (var a in FeedbackConstants.attendMoreOptions) a: 0},
        sortedTopics: [],
        hourlyTimeSeries: [],
        dailyTimeSeries: [],
        mainTakeaways: [],
        suggestions: [],
        commonTakeawayWords: [],
        commonSuggestionWords: [],
      );
    }

    final total = responses.length;

    // 1. Distributions for 1-5 ratings
    final relDist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    final useDist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    final satDist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    int sumRel = 0;
    int sumUse = 0;
    int sumSat = 0;

    // 2. Distributions for categories
    final progDist = <String, int>{};
    final yrDist = {for (var y in FeedbackConstants.yearsOfStudy) y: 0};
    final underDist = {for (var u in FeedbackConstants.understandingOptions) u: 0};
    final attDist = {for (var a in FeedbackConstants.attendMoreOptions) a: 0};
    final topicCounts = <String, int>{};

    final takeaways = <String>[];
    final suggestions = <String>[];

    for (final resp in responses) {
      // Ratings
      relDist[resp.relevanceRating] = (relDist[resp.relevanceRating] ?? 0) + 1;
      useDist[resp.usefulnessRating] = (useDist[resp.usefulnessRating] ?? 0) + 1;
      satDist[resp.satisfactionRating] = (satDist[resp.satisfactionRating] ?? 0) + 1;
      sumRel += resp.relevanceRating;
      sumUse += resp.usefulnessRating;
      sumSat += resp.satisfactionRating;

      // Programme
      progDist[resp.programme] = (progDist[resp.programme] ?? 0) + 1;

      // Year of Study
      yrDist[resp.yearOfStudy] = (yrDist[resp.yearOfStudy] ?? 0) + 1;

      // Understanding
      underDist[resp.understandingImproved] = (underDist[resp.understandingImproved] ?? 0) + 1;

      // Attend More
      attDist[resp.attendMore] = (attDist[resp.attendMore] ?? 0) + 1;

      // Topics
      for (final topic in resp.futureTopics) {
        if (topic.trim().isNotEmpty) {
          topicCounts[topic] = (topicCounts[topic] ?? 0) + 1;
        }
      }

      // Qualitative text
      if (resp.mainTakeaway.trim().isNotEmpty) {
        takeaways.add(resp.mainTakeaway.trim());
      }
      if (resp.suggestions.trim().isNotEmpty) {
        suggestions.add(resp.suggestions.trim());
      }
    }

    // Sort topics descending
    final sortedTopics = topicCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 3. Time Series: Hourly and Daily
    final hourlyMap = <String, int>{};
    final hourlyDateMap = <String, DateTime>{};
    final dailyMap = <String, int>{};
    final dailyDateMap = <String, DateTime>{};

    final sortedResponses = List<FeedbackResponse>.from(responses)
      ..sort((a, b) => a.submittedAt.compareTo(b.submittedAt));

    for (final r in sortedResponses) {
      final hourKey = DateFormat('MM/dd HH:00').format(r.submittedAt);
      final hourDate = DateTime(r.submittedAt.year, r.submittedAt.month, r.submittedAt.day, r.submittedAt.hour);
      hourlyMap[hourKey] = (hourlyMap[hourKey] ?? 0) + 1;
      hourlyDateMap[hourKey] = hourDate;

      final dayKey = DateFormat('MM/dd').format(r.submittedAt);
      final dayDate = DateTime(r.submittedAt.year, r.submittedAt.month, r.submittedAt.day);
      dailyMap[dayKey] = (dailyMap[dayKey] ?? 0) + 1;
      dailyDateMap[dayKey] = dayDate;
    }

    final hourlyList = hourlyMap.entries.map((e) {
      return TimeSeriesPoint(
        timestamp: hourlyDateMap[e.key] ?? DateTime.now(),
        label: e.key,
        count: e.value,
      );
    }).toList();

    final dailyList = dailyMap.entries.map((e) {
      return TimeSeriesPoint(
        timestamp: dailyDateMap[e.key] ?? DateTime.now(),
        label: e.key,
        count: e.value,
      );
    }).toList();

    return LectureAnalyticsSummary(
      totalResponses: total,
      averageRelevance: sumRel / total,
      relevanceDistribution: relDist,
      averageUsefulness: sumUse / total,
      usefulnessDistribution: useDist,
      averageSatisfaction: sumSat / total,
      satisfactionDistribution: satDist,
      programmeDistribution: progDist,
      yearDistribution: yrDist,
      understandingDistribution: underDist,
      attendMoreDistribution: attDist,
      sortedTopics: sortedTopics,
      hourlyTimeSeries: hourlyList,
      dailyTimeSeries: dailyList,
      mainTakeaways: takeaways,
      suggestions: suggestions,
      commonTakeawayWords: extractKeywords(takeaways),
      commonSuggestionWords: extractKeywords(suggestions),
    );
  }

  /// Extracts the most frequent meaningful keywords from qualitative responses.
  static List<MapEntry<String, int>> extractKeywords(List<String> texts, {int topN = 8}) {
    if (texts.isEmpty) return [];

    const stopWords = {
      'a', 'about', 'above', 'after', 'again', 'against', 'all', 'am', 'an', 'and', 'any', 'are',
      'as', 'at', 'be', 'because', 'been', 'before', 'being', 'below', 'between', 'both', 'but',
      'by', 'cannot', 'could', 'did', 'do', 'does', 'doing', 'down', 'during', 'each', 'few', 'for',
      'from', 'further', 'had', 'has', 'have', 'having', 'he', 'her', 'here', 'hers', 'herself',
      'him', 'himself', 'his', 'how', 'i', 'if', 'in', 'into', 'is', 'it', 'its', 'itself', 'me',
      'more', 'most', 'my', 'myself', 'no', 'nor', 'not', 'of', 'off', 'on', 'once', 'only', 'or',
      'other', 'ought', 'our', 'ours', 'ourselves', 'out', 'over', 'own', 'same', 'she', 'should',
      'so', 'some', 'such', 'than', 'that', 'the', 'their', 'theirs', 'them', 'themselves', 'then',
      'there', 'these', 'they', 'this', 'those', 'through', 'to', 'too', 'under', 'until', 'up',
      'very', 'was', 'we', 'were', 'what', 'when', 'where', 'which', 'while', 'who', 'whom', 'why',
      'with', 'would', 'you', 'your', 'yours', 'yourself', 'yourselves', 'good', 'lecture', 'session',
      'sir', 'alumni', 'thank', 'thanks', 'really', 'much', 'well', 'got', 'give', 'given'
    };

    final wordCounts = <String, int>{};

    for (final text in texts) {
      final words = text.toLowerCase().split(RegExp(r'[^\w]+'));
      for (final word in words) {
        final clean = word.trim();
        if (clean.length >= 3 && !stopWords.contains(clean)) {
          wordCounts[clean] = (wordCounts[clean] ?? 0) + 1;
        }
      }
    }

    final sorted = wordCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(topN).toList();
  }
}

/// Comparison metrics for a single selected lecture.
class LectureComparisonItem {
  final Lecture lecture;
  final int totalResponses;
  final double averageRelevance;
  final double averageUsefulness;
  final double averageSatisfaction;
  final double definitelyAttendPercentage;

  const LectureComparisonItem({
    required this.lecture,
    required this.totalResponses,
    required this.averageRelevance,
    required this.averageUsefulness,
    required this.averageSatisfaction,
    required this.definitelyAttendPercentage,
  });
}

/// Global analytics summary for the Admin Dashboard.
class DashboardAnalyticsSummary {
  final int totalLectures;
  final int activeLectures;
  final int totalResponses;
  final double overallAverageSatisfaction;
  final double overallAverageRelevance;
  final double overallAverageUsefulness;

  // 1. Line graph of average overall satisfaction across academic year in date order
  final List<LectureRatingTrendPoint> satisfactionTrend;

  // 2. Second line graph for average relevance and average usefulness across lectures
  final List<LectureRatingTrendPoint> relevanceUsefulnessTrend;

  // 3. Bar chart of number of responses per lecture
  final List<MapEntry<String, int>> responsesPerLecture;

  // 4. Pie chart: responses by programme/department across all lectures
  final Map<String, int> programmeDistribution;

  // 5. Bar chart: most requested future topics across all lectures
  final List<MapEntry<String, int>> mostRequestedTopics;

  // 6. Top-rated and lowest-rated lectures (by satisfaction)
  final List<LectureRatingTrendPoint> topRatedLectures;
  final List<LectureRatingTrendPoint> lowestRatedLectures;

  // 7. Recent activity list
  final List<RecentActivityItem> recentActivities;

  const DashboardAnalyticsSummary({
    required this.totalLectures,
    required this.activeLectures,
    required this.totalResponses,
    required this.overallAverageSatisfaction,
    required this.overallAverageRelevance,
    required this.overallAverageUsefulness,
    required this.satisfactionTrend,
    required this.relevanceUsefulnessTrend,
    required this.responsesPerLecture,
    required this.programmeDistribution,
    required this.mostRequestedTopics,
    required this.topRatedLectures,
    required this.lowestRatedLectures,
    required this.recentActivities,
  });
}

class RecentActivityItem {
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final IconData icon;
  final Color color;

  const RecentActivityItem({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
    required this.color,
  });
}
