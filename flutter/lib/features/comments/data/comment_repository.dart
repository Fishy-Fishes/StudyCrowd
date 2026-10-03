import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../auth/domain/discord_user.dart';
import '../domain/comment.dart';

/// Comments live under posts/{postId}/comments. The Discord bot adds comments
/// from replies to the event embed, and posts app comments into its thread.
class CommentRepository {
  static FirebaseFirestore get _db => FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'studycrowd-db1',
  );

  static CollectionReference<Map<String, dynamic>> _comments(String postId) =>
      _db.collection('posts').doc(postId).collection('comments');

  static Stream<List<Comment>> watchComments(String postId) {
    return _comments(postId)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Comment.fromDoc(doc.id, doc.data()))
              .toList(),
        );
  }

  static Future<void> addComment({
    required String postId,
    required DiscordUser author,
    required String text,
  }) {
    return _comments(postId).add({
      'author': author.id,
      'author_name': author.displayName,
      'author_avatar': author.avatarUrl,
      'text': text,
      'createdAt': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }
}
