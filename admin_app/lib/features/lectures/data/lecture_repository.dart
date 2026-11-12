import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/lecture_model.dart';
import '../domain/feedback_response_model.dart';

/// Repository for Cloud Firestore lecture operations.
class LectureRepository {
  final FirebaseFirestore _firestore;

  LectureRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _lecturesCollection =>
      _firestore.collection('lectures');

  /// Real-time stream of all responses for a given lecture.
  Stream<List<FeedbackResponse>> watchResponses(String lectureId) {
    return _lecturesCollection
        .doc(lectureId)
        .collection('responses')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FeedbackResponse.fromFirestore(doc))
          .toList();
    });
  }

  /// Real-time stream of all feedback responses across all lectures (via collectionGroup).
  Stream<List<FeedbackResponse>> watchAllResponses() {
    return _firestore
        .collectionGroup('responses')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FeedbackResponse.fromFirestore(doc))
          .toList();
    });
  }

  /// Real-time stream of all lectures, ordered by date descending.
  Stream<List<Lecture>> watchLectures() {
    return _lecturesCollection
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Lecture.fromFirestore(doc)).toList();
    });
  }

  /// Real-time stream of a single lecture document.
  Stream<Lecture?> watchLecture(String id) {
    return _lecturesCollection.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Lecture.fromFirestore(doc);
    });
  }

  /// One-time fetch of a single lecture.
  Future<Lecture?> getLecture(String id) async {
    final doc = await _lecturesCollection.doc(id).get();
    if (!doc.exists) return null;
    return Lecture.fromFirestore(doc);
  }

  /// Creates a new lecture in Firestore.
  /// Generates a document ID if not provided.
  Future<String> createLecture(Lecture lecture) async {
    final docRef = lecture.id.isEmpty
        ? _lecturesCollection.doc()
        : _lecturesCollection.doc(lecture.id);

    final finalLecture = lecture.copyWith(
      id: docRef.id,
      createdAt: DateTime.now(),
      responseCount: 0,
    );

    await docRef.set(finalLecture.toMap());
    return docRef.id;
  }

  /// Updates an existing lecture.
  Future<void> updateLecture(Lecture lecture) async {
    await _lecturesCollection.doc(lecture.id).update(lecture.toMap());
  }

  /// Updates only the lifecycle status of a lecture (draft, active, closed).
  Future<void> updateStatus(String lectureId, LectureStatus newStatus) async {
    await _lecturesCollection.doc(lectureId).update({
      'status': newStatus.value,
    });
  }

  /// Deletes a lecture and its subcollections.
  Future<void> deleteLecture(String lectureId) async {
    // Delete responses subcollection documents
    final responsesSnapshot = await _lecturesCollection
        .doc(lectureId)
        .collection('responses')
        .get();

    final batch = _firestore.batch();
    for (final doc in responsesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_lecturesCollection.doc(lectureId));
    await batch.commit();
  }
}
