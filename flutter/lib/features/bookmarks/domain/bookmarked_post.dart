
class BookmarkedPost {
  final String postId;
  final String title;
  final String author;
  final String? authorName;
  final String? authorAvatar;
  final String? serverName;
  final int? createdAtSeconds;

  const BookmarkedPost({
    required this.postId,
    required this.title,
    required this.author,
    this.authorName,
    this.authorAvatar,
    this.serverName,
    this.createdAtSeconds,
  });

  factory BookmarkedPost.fromDoc(String postId, Map<String, dynamic> data) {
    return BookmarkedPost(
      postId: postId,
      title: (data['title'] as String?) ?? '',
      author: (data['author'] as String?) ?? '',
      authorName: data['author_name'] as String?,
      authorAvatar: data['author_avatar'] as String?,
      serverName: data['server_name'] as String?,
      createdAtSeconds: data['postCreatedAt'] is num
          ? (data['postCreatedAt'] as num).toInt()
          : null,
    );
  }

  
  String get timeAgo {
    final sec = createdAtSeconds;
    if (sec == null) return '';
    final diff = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(sec * 1000));
    if (diff.inDays >= 1) return '.${diff.inDays}d';
    if (diff.inHours >= 1) return '.${diff.inHours}h';
    if (diff.inMinutes >= 1) return '.${diff.inMinutes}min';
    return '.now';
  }
}