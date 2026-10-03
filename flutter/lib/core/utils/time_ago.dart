/// Compact relative time used on cards, e.g. "· 5m", "· 2h", "· 3d".
String timeAgo(int? createdAtSeconds) {
  if (createdAtSeconds == null) return '';
  final diff = DateTime.now().difference(
    DateTime.fromMillisecondsSinceEpoch(createdAtSeconds * 1000),
  );
  if (diff.inDays >= 1) return '· ${diff.inDays}d';
  if (diff.inHours >= 1) return '· ${diff.inHours}h';
  if (diff.inMinutes >= 1) return '· ${diff.inMinutes}m';
  return '· now';
}
