import '../../../core/utils/time_ago.dart' as time;

/// A comment on a post (posts/{postId}/comments). Comments written in Discord
/// carry the ID of their Discord message; app comments get one once the bot
/// has mirrored them into the post's Discord thread.
class Comment {
  final String id;
  final String author;
  final String authorName;
  final String? authorAvatar;
  final String text;
  final int? createdAtSeconds;

  const Comment({
    required this.id,
    required this.author,
    required this.authorName,
    required this.text,
    this.authorAvatar,
    this.createdAtSeconds,
  });

  factory Comment.fromDoc(String id, Map<String, dynamic> data) {
    final author = (data['author'] as String?) ?? '';
    return Comment(
      id: id,
      author: author,
      authorName: (data['author_name'] as String?) ?? '@$author',
      authorAvatar: data['author_avatar'] as String?,
      text: (data['text'] as String?) ?? '',
      createdAtSeconds: (data['createdAt'] as num?)?.toInt(),
    );
  }

  String get timeAgo => time.timeAgo(createdAtSeconds);
}
