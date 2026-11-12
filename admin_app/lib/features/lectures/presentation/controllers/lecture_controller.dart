import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/lecture_repository.dart';
import '../../domain/lecture_model.dart';
import '../../domain/feedback_response_model.dart';
import '../../domain/lecture_analytics_model.dart';

/// Provider for LectureRepository.
final lectureRepositoryProvider = Provider<LectureRepository>((ref) {
  return LectureRepository();
});

/// Real-time stream of all lectures from Firestore.
final lecturesStreamProvider = StreamProvider<List<Lecture>>((ref) {
  final repo = ref.watch(lectureRepositoryProvider);
  return repo.watchLectures();
});

/// Alias for screen compatibility
final allLecturesStreamProvider = lecturesStreamProvider;

/// Single lecture stream provider by lecture ID.
final lectureDetailProvider = StreamProvider.family<Lecture?, String>((ref, id) {
  final repo = ref.watch(lectureRepositoryProvider);
  return repo.watchLecture(id);
});

/// Filter states
final lectureSearchQueryProvider = StateProvider<String>((ref) => '');
final lectureStatusFilterProvider = StateProvider<String>((ref) => 'All');
final lectureAcademicYearFilterProvider = StateProvider<String>((ref) => 'All');
final lectureDepartmentFilterProvider = StateProvider<String>((ref) => 'All');

/// Filtered lectures provider computed in real-time.
final filteredLecturesProvider = Provider<AsyncValue<List<Lecture>>>((ref) {
  final lecturesAsync = ref.watch(lecturesStreamProvider);
  final searchQuery = ref.watch(lectureSearchQueryProvider).trim().toLowerCase();
  final statusFilter = ref.watch(lectureStatusFilterProvider);
  final academicYearFilter = ref.watch(lectureAcademicYearFilterProvider);
  final departmentFilter = ref.watch(lectureDepartmentFilterProvider);

  return lecturesAsync.whenData((lectures) {
    return lectures.where((lecture) {
      // 1. Search Query
      if (searchQuery.isNotEmpty) {
        final matchesTitle = lecture.title.toLowerCase().contains(searchQuery);
        final matchesSpeaker = lecture.speakerName.toLowerCase().contains(searchQuery);
        final matchesCompany = lecture.company.toLowerCase().contains(searchQuery);
        final matchesVenue = lecture.venue.toLowerCase().contains(searchQuery);
        final matchesFolderName = lecture.folderName.toLowerCase().contains(searchQuery);

        if (!matchesTitle && !matchesSpeaker && !matchesCompany && !matchesVenue && !matchesFolderName) {
          return false;
        }
      }

      // 2. Status Filter
      if (statusFilter != 'All') {
        if (lecture.status.value.toLowerCase() != statusFilter.toLowerCase()) {
          return false;
        }
      }

      // 3. Academic Year Filter
      if (academicYearFilter != 'All') {
        if (lecture.academicYear.toLowerCase() != academicYearFilter.toLowerCase()) {
          return false;
        }
      }

      // 4. Department Filter
      if (departmentFilter != 'All') {
        if (!lecture.department.toLowerCase().contains(departmentFilter.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();
  });
});

/// Dynamic list of unique academic years found in lectures for dropdown filtering.
final availableAcademicYearsProvider = Provider<List<String>>((ref) {
  final lectures = ref.watch(lecturesStreamProvider).value ?? [];
  final years = lectures.map((l) => l.academicYear.trim()).where((y) => y.isNotEmpty).toSet().toList();
  years.sort((a, b) => b.compareTo(a));
  return ['All', ...years];
});

/// Dynamic list of unique departments for dropdown filtering.
final availableDepartmentsProvider = Provider<List<String>>((ref) {
  final lectures = ref.watch(lecturesStreamProvider).value ?? [];
  final depts = lectures.map((l) => l.department.trim()).where((d) => d.isNotEmpty).toSet().toList();
  depts.sort();
  return ['All', ...depts];
});

/// Controller for executing write operations (create, update, delete, set status).
class LectureActionController extends StateNotifier<AsyncValue<void>> {
  final LectureRepository _repository;

  LectureActionController(this._repository) : super(const AsyncValue.data(null));

  Future<String?> createLecture(Lecture lecture) async {
    state = const AsyncValue.loading();
    try {
      final id = await _repository.createLecture(lecture);
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> updateLecture(Lecture lecture) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateLecture(lecture);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> setStatus(String lectureId, LectureStatus newStatus) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateStatus(lectureId, newStatus);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteLecture(String lectureId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteLecture(lectureId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final lectureActionControllerProvider =
    StateNotifierProvider<LectureActionController, AsyncValue<void>>((ref) {
  final repo = ref.watch(lectureRepositoryProvider);
  return LectureActionController(repo);
});

// =============================================================================
// RESPONSES TAB: STREAMS, SORTING, FILTERING & PAGINATION
// =============================================================================

/// Real-time stream of all student feedback responses for a specific lecture.
final lectureResponsesStreamProvider =
    StreamProvider.family<List<FeedbackResponse>, String>((ref, lectureId) {
  final repo = ref.watch(lectureRepositoryProvider);
  return repo.watchResponses(lectureId);
});

// Response Filter Providers
final responseSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');
final responseProgrammeFilterProvider = StateProvider.autoDispose<String>((ref) => 'All');
final responseYearFilterProvider = StateProvider.autoDispose<String>((ref) => 'All');
final responseSatisfactionFilterProvider = StateProvider.autoDispose<int?>((ref) => null);
final responseAttendMoreFilterProvider = StateProvider.autoDispose<String>((ref) => 'All');
final responseDateRangeFilterProvider = StateProvider.autoDispose<DateTimeRange?>((ref) => null);

// Response Sorting Providers
final responseSortColumnProvider = StateProvider.autoDispose<String>((ref) => 'submittedAt');
final responseSortAscendingProvider = StateProvider.autoDispose<bool>((ref) => false);

// Response Pagination Providers
final responseCurrentPageProvider = StateProvider.autoDispose<int>((ref) => 1);
final responsePageSizeProvider = StateProvider.autoDispose<int>((ref) => 25);

/// Filtered & Sorted Responses for a given lecture.
final filteredResponsesProvider =
    Provider.autoDispose.family<AsyncValue<List<FeedbackResponse>>, String>((ref, lectureId) {
  final responsesAsync = ref.watch(lectureResponsesStreamProvider(lectureId));
  final searchQuery = ref.watch(responseSearchQueryProvider).trim().toLowerCase();
  final programmeFilter = ref.watch(responseProgrammeFilterProvider);
  final yearFilter = ref.watch(responseYearFilterProvider);
  final satisfactionFilter = ref.watch(responseSatisfactionFilterProvider);
  final attendMoreFilter = ref.watch(responseAttendMoreFilterProvider);
  final dateRange = ref.watch(responseDateRangeFilterProvider);
  final sortColumn = ref.watch(responseSortColumnProvider);
  final sortAscending = ref.watch(responseSortAscendingProvider);

  return responsesAsync.whenData((responses) {
    // 1. Filtering
    final filtered = responses.where((resp) {
      // Search: name, register number, email
      if (searchQuery.isNotEmpty) {
        final matchesName = resp.name.toLowerCase().contains(searchQuery);
        final matchesReg = resp.registerNumber.toLowerCase().contains(searchQuery);
        final matchesEmail = resp.email.toLowerCase().contains(searchQuery);
        if (!matchesName && !matchesReg && !matchesEmail) return false;
      }

      // Programme
      if (programmeFilter != 'All' && resp.programme != programmeFilter) {
        return false;
      }

      // Year of Study
      if (yearFilter != 'All' && resp.yearOfStudy != yearFilter) {
        return false;
      }

      // Satisfaction Rating (1-5)
      if (satisfactionFilter != null && resp.satisfactionRating != satisfactionFilter) {
        return false;
      }

      // Attend More
      if (attendMoreFilter != 'All' && resp.attendMore != attendMoreFilter) {
        return false;
      }

      // Date Range
      if (dateRange != null) {
        final date = resp.submittedAt;
        final start = dateRange.start;
        final end = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day, 23, 59, 59);
        if (date.isBefore(start) || date.isAfter(end)) return false;
      }

      return true;
    }).toList();

    // 2. Sorting
    filtered.sort((a, b) {
      int comparison = 0;
      switch (sortColumn) {
        case 'name':
          comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case 'registerNumber':
          comparison = a.registerNumber.compareTo(b.registerNumber);
          break;
        case 'email':
          comparison = a.email.toLowerCase().compareTo(b.email.toLowerCase());
          break;
        case 'programme':
          comparison = a.programme.compareTo(b.programme);
          break;
        case 'yearOfStudy':
          comparison = a.yearOfStudy.compareTo(b.yearOfStudy);
          break;
        case 'lectureTitle':
          comparison = a.lectureTitle.toLowerCase().compareTo(b.lectureTitle.toLowerCase());
          break;
        case 'relevanceRating':
          comparison = a.relevanceRating.compareTo(b.relevanceRating);
          break;
        case 'usefulnessRating':
          comparison = a.usefulnessRating.compareTo(b.usefulnessRating);
          break;
        case 'understandingImproved':
          comparison = a.understandingImproved.compareTo(b.understandingImproved);
          break;
        case 'mainTakeaway':
          comparison = a.mainTakeaway.toLowerCase().compareTo(b.mainTakeaway.toLowerCase());
          break;
        case 'attendMore':
          comparison = a.attendMore.compareTo(b.attendMore);
          break;
        case 'futureTopics':
          comparison = a.futureTopics.join(', ').toLowerCase().compareTo(b.futureTopics.join(', ').toLowerCase());
          break;
        case 'suggestions':
          comparison = a.suggestions.toLowerCase().compareTo(b.suggestions.toLowerCase());
          break;
        case 'satisfactionRating':
          comparison = a.satisfactionRating.compareTo(b.satisfactionRating);
          break;
        case 'submittedAt':
        default:
          comparison = a.submittedAt.compareTo(b.submittedAt);
          break;
      }
      return sortAscending ? comparison : -comparison;
    });

    return filtered;
  });
});

/// Paginated subset of filtered responses for high-performance rendering.
final paginatedResponsesProvider =
    Provider.autoDispose.family<AsyncValue<List<FeedbackResponse>>, String>((ref, lectureId) {
  final filteredAsync = ref.watch(filteredResponsesProvider(lectureId));
  final currentPage = ref.watch(responseCurrentPageProvider);
  final pageSize = ref.watch(responsePageSizeProvider);

  return filteredAsync.whenData((responses) {
    final startIndex = (currentPage - 1) * pageSize;
    if (startIndex >= responses.length) return <FeedbackResponse>[];
    final endIndex = (startIndex + pageSize).clamp(0, responses.length);
    return responses.sublist(startIndex, endIndex);
  });
});

// =============================================================================
// GLOBAL RESPONSES STREAM & DASHBOARD ANALYTICS
// =============================================================================

/// Real-time stream of all feedback responses across all lectures.
final allResponsesStreamProvider = StreamProvider<List<FeedbackResponse>>((ref) {
  final repo = ref.watch(lectureRepositoryProvider);
  return repo.watchAllResponses();
});

/// Academic year filter for the main Dashboard.
final dashboardAcademicYearProvider = StateProvider<String>((ref) => 'All');

/// Single lecture analytics provider.
final singleLectureAnalyticsProvider =
    Provider.autoDispose.family<AsyncValue<LectureAnalyticsSummary>, String>((ref, lectureId) {
  final responsesAsync = ref.watch(lectureResponsesStreamProvider(lectureId));
  return responsesAsync.whenData((responses) => LectureAnalyticsSummary.fromResponses(responses));
});

/// Time-series aggregation period toggle ('hour' vs 'day') for lecture analytics.
final timeSeriesPeriodProvider = StateProvider.autoDispose<String>((ref) => 'hour');

/// Main Dashboard aggregated analytics provider.
final dashboardAnalyticsProvider = Provider<AsyncValue<DashboardAnalyticsSummary>>((ref) {
  final lecturesAsync = ref.watch(lecturesStreamProvider);
  final allResponsesAsync = ref.watch(allResponsesStreamProvider);
  final academicYearFilter = ref.watch(dashboardAcademicYearProvider);

  if (lecturesAsync.isLoading || allResponsesAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (lecturesAsync.hasError) {
    return AsyncValue.error(lecturesAsync.error!, lecturesAsync.stackTrace!);
  }

  final allLectures = lecturesAsync.value ?? [];
  final allResponses = allResponsesAsync.value ?? [];

  // Filter lectures by selected academic year
  final filteredLectures = academicYearFilter == 'All'
      ? allLectures
      : allLectures.where((l) => l.academicYear == academicYearFilter).toList();

  final filteredLectureIds = filteredLectures.map((l) => l.id).toSet();
  final filteredLectureTitles = {for (var l in filteredLectures) l.title: l.id};

  // Group responses by lecture
  final responsesByLectureId = <String, List<FeedbackResponse>>{};
  final relevantResponses = <FeedbackResponse>[];

  for (final resp in allResponses) {
    final matchedLectureId = filteredLectureTitles[resp.lectureTitle];
    if (matchedLectureId != null && filteredLectureIds.contains(matchedLectureId)) {
      responsesByLectureId.putIfAbsent(matchedLectureId, () => []).add(resp);
      relevantResponses.add(resp);
    }
  }

  final totalLectures = filteredLectures.length;
  final activeLectures = filteredLectures.where((l) => l.status == LectureStatus.active).length;
  final totalResponses = relevantResponses.length;

  double overallAvgSat = 0.0;
  double overallAvgRel = 0.0;
  double overallAvgUse = 0.0;

  if (relevantResponses.isNotEmpty) {
    final sumSat = relevantResponses.fold<int>(0, (sum, r) => sum + r.satisfactionRating);
    final sumRel = relevantResponses.fold<int>(0, (sum, r) => sum + r.relevanceRating);
    final sumUse = relevantResponses.fold<int>(0, (sum, r) => sum + r.usefulnessRating);
    overallAvgSat = sumSat / relevantResponses.length;
    overallAvgRel = sumRel / relevantResponses.length;
    overallAvgUse = sumUse / relevantResponses.length;
  }

  // 1. Satisfaction Trend across lectures in date order
  final sortedDateLectures = List<Lecture>.from(filteredLectures)
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

  final satisfactionTrend = <LectureRatingTrendPoint>[];
  final relevanceUsefulnessTrend = <LectureRatingTrendPoint>[];
  final responsesPerLecture = <MapEntry<String, int>>[];

  for (final lec in sortedDateLectures) {
    final resps = responsesByLectureId[lec.id] ?? [];
    double avgSat = 0.0;
    double avgRel = 0.0;
    double avgUse = 0.0;

    if (resps.isNotEmpty) {
      avgSat = resps.fold<int>(0, (sum, r) => sum + r.satisfactionRating) / resps.length;
      avgRel = resps.fold<int>(0, (sum, r) => sum + r.relevanceRating) / resps.length;
      avgUse = resps.fold<int>(0, (sum, r) => sum + r.usefulnessRating) / resps.length;
    }

    final point = LectureRatingTrendPoint(
      lectureId: lec.id,
      title: lec.title,
      speakerName: lec.speakerName,
      dateTime: lec.dateTime,
      responseCount: resps.length,
      averageSatisfaction: avgSat,
      averageRelevance: avgRel,
      averageUsefulness: avgUse,
    );

    satisfactionTrend.add(point);
    relevanceUsefulnessTrend.add(point);
    responsesPerLecture.add(MapEntry(lec.title, resps.length));
  }

  // 4. Programme distribution across all lectures
  final progDist = <String, int>{};
  for (final r in relevantResponses) {
    progDist[r.programme] = (progDist[r.programme] ?? 0) + 1;
  }

  // 5. Future topics across all lectures
  final topicCounts = <String, int>{};
  for (final r in relevantResponses) {
    for (final topic in r.futureTopics) {
      if (topic.trim().isNotEmpty) {
        topicCounts[topic] = (topicCounts[topic] ?? 0) + 1;
      }
    }
  }
  final sortedTopics = topicCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  // 6. Top-rated and lowest-rated lectures
  final ratedLectures = satisfactionTrend.where((p) => p.responseCount > 0).toList();
  final topRated = List<LectureRatingTrendPoint>.from(ratedLectures)
    ..sort((a, b) => b.averageSatisfaction.compareTo(a.averageSatisfaction));
  final lowestRated = List<LectureRatingTrendPoint>.from(ratedLectures)
    ..sort((a, b) => a.averageSatisfaction.compareTo(b.averageSatisfaction));

  // 7. Recent activity list
  final activities = <RecentActivityItem>[];
  for (final lec in allLectures.take(5)) {
    activities.add(
      RecentActivityItem(
        title: 'Lecture: ${lec.title}',
        subtitle: 'Speaker: ${lec.speakerName} • ${lec.department}',
        timestamp: lec.createdAt,
        icon: Icons.event_note_rounded,
        color: AppColors.primaryNavy,
      ),
    );
  }

  return AsyncValue.data(
    DashboardAnalyticsSummary(
      totalLectures: totalLectures,
      activeLectures: activeLectures,
      totalResponses: totalResponses,
      overallAverageSatisfaction: overallAvgSat,
      overallAverageRelevance: overallAvgRel,
      overallAverageUsefulness: overallAvgUse,
      satisfactionTrend: satisfactionTrend,
      relevanceUsefulnessTrend: relevanceUsefulnessTrend,
      responsesPerLecture: responsesPerLecture,
      programmeDistribution: progDist,
      mostRequestedTopics: sortedTopics,
      topRatedLectures: topRated.take(3).toList(),
      lowestRatedLectures: lowestRated.take(3).toList(),
      recentActivities: activities,
    ),
  );
});

// =============================================================================
// LECTURE COMPARISON PROVIDERS
// =============================================================================

/// Set of selected lecture IDs to compare.
final selectedCompareLectureIdsProvider = StateProvider<Set<String>>((ref) => {});

/// Computes comparison items for each selected lecture.
final lectureComparisonDataProvider = Provider<List<LectureComparisonItem>>((ref) {
  final selectedIds = ref.watch(selectedCompareLectureIdsProvider);
  final lectures = ref.watch(lecturesStreamProvider).value ?? [];
  final allResponses = ref.watch(allResponsesStreamProvider).value ?? [];

  if (selectedIds.isEmpty) return [];

  final selectedLectures = lectures.where((l) => selectedIds.contains(l.id)).toList();
  final titleToIdMap = {for (var l in selectedLectures) l.title: l.id};

  final responsesByLectureId = <String, List<FeedbackResponse>>{};
  for (final resp in allResponses) {
    final lecId = titleToIdMap[resp.lectureTitle];
    if (lecId != null && selectedIds.contains(lecId)) {
      responsesByLectureId.putIfAbsent(lecId, () => []).add(resp);
    }
  }

  final items = <LectureComparisonItem>[];

  for (final lec in selectedLectures) {
    final resps = responsesByLectureId[lec.id] ?? [];
    double avgRel = 0.0;
    double avgUse = 0.0;
    double avgSat = 0.0;
    double defAttendPct = 0.0;

    if (resps.isNotEmpty) {
      avgRel = resps.fold<int>(0, (sum, r) => sum + r.relevanceRating) / resps.length;
      avgUse = resps.fold<int>(0, (sum, r) => sum + r.usefulnessRating) / resps.length;
      avgSat = resps.fold<int>(0, (sum, r) => sum + r.satisfactionRating) / resps.length;
      final defCount = resps.where((r) => r.attendMore == 'Definitely').length;
      defAttendPct = (defCount / resps.length) * 100.0;
    }

    items.add(
      LectureComparisonItem(
        lecture: lec,
        totalResponses: resps.length,
        averageRelevance: avgRel,
        averageUsefulness: avgUse,
        averageSatisfaction: avgSat,
        definitelyAttendPercentage: defAttendPct,
      ),
    );
  }

  return items;
});
