/// Reads `user_id` from a financial row map.
String? userIdFromRow(Map<String, dynamic> map) {
  final raw = map['user_id']?.toString().trim();
  if (raw == null || raw.isEmpty) return null;
  return raw;
}
