
class StudyPost {
  final String id;
  final String title;
  final String author;
  final String? embedMessageId;
  final String? uuid;
  final int? createdAtSeconds;
  final List<String> attending;

  const StudyPost({
    required this.id,
    required this.title,
    required this.author,
    this.embedMessageId,
    this.uuid,
    this.createdAtSeconds,
    this.attending = const [],
  });

  factory StudyPost.fromDoc(String id, Map<String, dynamic> data) {
    final attending = data['attending'];
    return StudyPost(
      id: id,
      title: (data['title'] as String?) ?? '',
      author: (data['author'] as String?) ?? '',
      embedMessageId: data['embed_message_id'] as String?,
      uuid: data['uuid'] as String?,
      createdAtSeconds: data['createdAt'] is num
          ? (data['createdAt'] as num).toInt()
          : null,
      attending: attending is List
          ? attending.map((e) => e.toString()).toList()
          : const [],
    );
  }

  int get attendeeCount => attending.length;

  
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