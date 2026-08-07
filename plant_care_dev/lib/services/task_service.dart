import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task.dart';
import 'auth_service.dart';

/// Reads and writes care tasks.
///
/// The deck on Home, the "what to do" block on a plant and the all-tasks screen
/// are three views of this one collection — SPEC v3 requires their state to stay
/// in sync in both directions, which only holds if nobody keeps a private copy.
class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _collection = 'tasks';

  /// Every open task of the signed-in user, newest ordering applied client-side
  /// so the sort rules live in one place ([sortTasks]) rather than in an index.
  Stream<List<CareTask>> watchOpenTasks() {
    final user = AuthService.currentUser;
    if (user == null) return Stream.value(const []);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .where('done', isEqualTo: false)
        .snapshots()
        .map(_decode)
        // Not swallowed: an empty list and a failed query look identical on
        // screen, and that is exactly how the health-check history bug hid.
        .handleError((Object error, StackTrace stack) {
          print('❌ TaskService: open-tasks query failed: $error');
          Error.throwWithStackTrace(error, stack);
        });
  }

  /// Open tasks of one plant, watering included — the scheduler does store it as
  /// a task, because the home deck shows it. The plant screen filters the
  /// scheduled watering chore out itself ([TodoBlock.visibleTasks]), since its
  /// hero widget already owns it (SPEC 3.3).
  Stream<List<CareTask>> watchPlantTasks(String plantId) {
    final user = AuthService.currentUser;
    if (user == null) return Stream.value(const []);

    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .where('plantId', isEqualTo: plantId)
        .where('done', isEqualTo: false)
        .snapshots()
        .map(_decode)
        .handleError((Object error, StackTrace stack) {
          print('❌ TaskService: plant-tasks query failed: $error');
          Error.throwWithStackTrace(error, stack);
        });
  }

  List<CareTask> _decode(QuerySnapshot<Map<String, dynamic>> snap) {
    final out = <CareTask>[];
    for (final doc in snap.docs) {
      try {
        out.add(CareTask.fromMap({...doc.data(), 'id': doc.id}));
      } catch (e) {
        // One malformed document must not blank the whole list.
        print('⚠️ TaskService: skipping task ${doc.id}: $e');
      }
    }
    return out;
  }

  /// Marks a task done. The trigger that created it is considered satisfied, so
  /// it never comes back (SPEC 1.3.5).
  Future<void> complete(String taskId) async {
    await _firestore.collection(_collection).doc(taskId).update({
      'done': true,
      'completedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Undoes a [complete] — the tick in "what to do" is a toggle, and a misplaced
  /// tap must be recoverable without waiting for the scheduler to notice.
  Future<void> reopen(String taskId) async {
    await _firestore.collection(_collection).doc(taskId).update({
      'done': false,
      'completedAt': null,
    });
  }

  /// "Later" — the task stays, the counter stays, it only moves to the end of
  /// its own priority group and comes back (SPEC 1.3.4). Overdue tasks keep
  /// their overdue status, so postponing never drops one below a fresh task.
  Future<void> postpone(String taskId) async {
    await _firestore.collection(_collection).doc(taskId).update({
      'postponedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Writes the recommendations of a finished analysis straight into the plan —
  /// there is no "add to plan" button any more (SPEC 3.4). They are the same
  /// objects the result screen lists, so the titles match by construction.
  ///
  /// [dueAt] defaults to now, which keeps `ageDays = 0`: a recommendation the
  /// user has only just received can never be shown as overdue (SPEC 1.3.6).
  Future<List<String>> createFromAnalysis({
    required String plantId,
    required List<CareTask> tasks,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not authenticated');
    if (tasks.isEmpty) return const [];

    final batch = _firestore.batch();
    final ids = <String>[];
    for (final task in tasks) {
      final ref = _firestore.collection(_collection).doc();
      ids.add(ref.id);
      batch.set(ref, {
        ...task.toMap(),
        'id': ref.id,
        'plantId': plantId,
        'userId': user.uid,
        'source': TaskSource.analysis.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return ids;
  }

  /// Records a one-off the owner agreed to in chat.
  ///
  /// `source: chat` rather than `analysis` because the two behave differently
  /// on the way out: analysis advice carries a health-score penalty while it is
  /// open, and this does not. It is not `schedule` either — a recompute would
  /// delete it, and no rule would ever bring it back.
  Future<String?> createFromChat({
    required String plantId,
    required String title,
    required int dueInDays,
    required TaskCategory category,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final ref = _firestore.collection(_collection).doc();
    await ref.set({
      'id': ref.id,
      'plantId': plantId,
      'userId': user.uid,
      'title': title,
      'category': category.name,
      'source': TaskSource.chat.name,
      'dueAt': DateTime.now().add(Duration(days: dueInDays)).toIso8601String(),
      'postponedAt': null,
      'done': false,
      'completedAt': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Closes every open task of a given category for a plant — used when a
  /// trigger is satisfied elsewhere: a finished health check retires the
  /// "rescan" task, logging a watering retires the watering task.
  ///
  /// [source] narrows it to one origin. Watering passes `schedule`, because
  /// closing the chore must not also retire an analysis recommendation like
  /// "let the soil dry out more" — that is advice the user has not acted on,
  /// and silently clearing it hands back the health-score penalty it carries.
  Future<int> completeCategory(
    String plantId,
    TaskCategory category, {
    TaskSource? source,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) return 0;

    final snap = await _firestore
        .collection(_collection)
        .where('userId', isEqualTo: user.uid)
        .where('plantId', isEqualTo: plantId)
        .where('category', isEqualTo: category.name)
        .where('done', isEqualTo: false)
        .get();

    final docs = source == null
        ? snap.docs
        : snap.docs.where((d) => d.data()['source'] == source.name).toList();
    if (docs.isEmpty) return 0;

    final batch = _firestore.batch();
    final now = DateTime.now().toIso8601String();
    for (final doc in docs) {
      batch.update(doc.reference, {'done': true, 'completedAt': now});
    }
    await batch.commit();
    return docs.length;
  }

  // There is deliberately no deleteForPlant. Removing a plant leaves its tasks
  // where they are, along with its conversation and everything the assistant
  // learned about it. They do not reappear anywhere: each screen that lists
  // tasks intersects them with the plants the user still has.
}
