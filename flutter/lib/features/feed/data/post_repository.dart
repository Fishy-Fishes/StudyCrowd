import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../auth/domain/discord_user.dart';
import '../domain/study_post.dart';





class PostRepository {
  static const String _databaseId = 'studycrowd-db1';

  static FirebaseFirestore get _db => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: _databaseId,
      );

  static CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('posts');

  static CollectionReference<Map<String, dynamic>> _bookmarksFor(String uid) =>
      _db.collection('users').doc(uid).collection('bookmarks');

  
  /// Posts a study session from the app, in the same shape the Discord bot
  /// writes. It has no Discord embed, so it lives only in the app feed.
  static Future<void> createPost({
    required DiscordUser author,
    required String text,
    DateTime? date,
  }) {
    final ref = _posts.doc();
    return ref.set({
      'uuid': ref.id,
      'createdAt': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'author': author.id,
      'author_name': author.displayName,
      'author_avatar': author.avatarUrl,
      'title': text,
      'attending': [author.id],
      'attendee_names': {author.id: author.displayName},
      if (date != null) 'timestamp': date.millisecondsSinceEpoch ~/ 1000,
    });
  }

  static Stream<List<StudyPost>> watchPosts() {
    return _posts
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudyPost.fromDoc(doc.id, doc.data()))
            .toList());
  }

  static Stream<StudyPost?> watchPost(String postId) {
    return _posts
        .doc(postId)
        .snapshots()
        .map((doc) => doc.exists
            ? StudyPost.fromDoc(doc.id, doc.data()!)
            : null);
  }

  
  
  
  
  
  
  static Future<void> toggleRsvp({
    required String postId,
    required String userId,
    required String userName,
  }) async {
    final postRef = _posts.doc(postId);
    final bookmarkRef = _bookmarksFor(userId).doc(postId);

    final postSnap = await postRef.get();
    if (!postSnap.exists) return;
    final data = postSnap.data()!;
    final attending =
        (data['attending'] as List?)?.cast<String>() ?? const <String>[];
    final isGoing = attending.contains(userId);

    final batch = _db.batch();
    if (isGoing) {
      batch.update(postRef, {
        'attending': FieldValue.arrayRemove([userId]),
        'attendee_names.$userId': FieldValue.delete(),
      });
      batch.delete(bookmarkRef);
    } else {
      batch.update(postRef, {
        'attending': FieldValue.arrayUnion([userId]),
        'attendee_names.$userId': userName,
      });
      batch.set(bookmarkRef, {
        'bookmarkedAt': FieldValue.serverTimestamp(),
        'postId': postId,
        'title': data['title'] ?? '',
        'author': data['author'] ?? '',
        'postCreatedAt': data['createdAt'] ?? 0,
        'postUuid': data['uuid'],
        'author_name': data['author_name'],
        'author_avatar': data['author_avatar'],
        'server_name': data['server_name'],
      });
    }
    await batch.commit();
  }
}