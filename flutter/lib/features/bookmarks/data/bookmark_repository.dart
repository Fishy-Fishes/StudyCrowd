import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../domain/bookmarked_post.dart';


class BookmarkRepository {
  static const String _databaseId = 'studycrowd-db1';

  static FirebaseFirestore get _db => FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: _databaseId,
      );

  static CollectionReference<Map<String, dynamic>> _bookmarksFor(
          String uid) =>
      _db.collection('users').doc(uid).collection('bookmarks');

  
  static Stream<List<BookmarkedPost>> watchBookmarks(String uid) {
    return _bookmarksFor(uid)
        .orderBy('bookmarkedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BookmarkedPost.fromDoc(doc.id, doc.data()))
            .toList());
  }

  
  static Future<void> removeBookmark({
    required String userId,
    required String postId,
  }) async {
    final batch = _db.batch();
    batch.delete(_bookmarksFor(userId).doc(postId));
    batch.update(
      _db.collection('posts').doc(postId),
      {'attending': FieldValue.arrayRemove([userId])},
    );
    await batch.commit();
  }
}