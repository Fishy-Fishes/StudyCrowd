import '../../../core/utils/event_date.dart';
import '../../../core/utils/time_ago.dart' as time;

class StudyPost {
  final String id;
  final String title;
  final String author;
  final String? authorName;
  final String? authorAvatar;
  final String? serverName;
  final String? embedMessageId;
  final String? uuid;
  final int? createdAtSeconds;

  /// The day the bot parsed from the message ("tomorrow", "next thursday"), if any.
  final int? eventAtSeconds;
  final List<String> attending;
  final Map<String, String> attendeeNameById;

  const StudyPost({
    required this.id,
    required this.title,
    required this.author,
    this.authorName,
    this.authorAvatar,
    this.serverName,
    this.embedMessageId,
    this.uuid,
    this.createdAtSeconds,
    this.eventAtSeconds,
    this.attending = const [],
    this.attendeeNameById = const {},
  });

  factory StudyPost.fromDoc(String id, Map<String, dynamic> data) {
    final attending = data['attending'];
    return StudyPost(
      id: id,
      title: (data['title'] as String?) ?? '',
      author: (data['author'] as String?) ?? '',
      authorName: data['author_name'] as String?,
      authorAvatar: data['author_avatar'] as String?,
      serverName: data['server_name'] as String?,
      embedMessageId: data['embed_message_id'] as String?,
      uuid: data['uuid'] as String?,
      createdAtSeconds: data['createdAt'] is num
          ? (data['createdAt'] as num).toInt()
          : null,
      attending: attending is List
          ? attending.map((e) => e.toString()).toList()
          : const [],
      eventAtSeconds: (data['timestamp'] as num?)?.toInt(),
      attendeeNameById:
          (data['attendee_names'] as Map?)?.cast<String, String>() ?? const {},
    );
  }

  int get attendeeCount => attending.length;

  /// Names of attendees in RSVP order, skipping anyone whose name isn't known.
  String get attendeeNames =>
      attending.map((id) => attendeeNameById[id]).whereType<String>().join(', ');

  
  String get timeAgo => time.timeAgo(createdAtSeconds);

  String? get eventDate => eventAtSeconds == null
      ? null
      : formatEventDate(
          DateTime.fromMillisecondsSinceEpoch(eventAtSeconds! * 1000),
        );
}