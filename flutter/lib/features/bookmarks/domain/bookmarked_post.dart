
class BookmarkedPost {
  final String postId;
  final String title;
  final String author;
  final int? createdAtSeconds;

  const BookmarkedPost({
    required this.postId,
    required this.title,
    required this.author,
    this.createdAtSeconds,
  });

  factory BookmarkedPost.fromDoc(String postId, Map<String, dynamic> data) {
    return BookmarkedPost(
      postId: postId,
      title: (data['title'] as String?) ?? '',
      author: (data['author'] as String?) ?? '',
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