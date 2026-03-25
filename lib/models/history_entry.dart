// ─── history_entry.dart ───────────────────────────────────────────────────────

class HistoryEntry {
  final int id; // unix ms timestamp — also used as Hive key
  final String breed;
  final double confidence;
  final String percentage;
  final String emoji;
  final String? origin;
  final String? group;
  final List<String> alternatives; // top 2-3 breed names only
  final String? imageBase64; // ~200×200 JPEG thumbnail, base64
  final bool isDemo;
  final DateTime timestamp;

  const HistoryEntry({
    required this.id,
    required this.breed,
    required this.confidence,
    required this.percentage,
    required this.emoji,
    this.origin,
    this.group,
    this.alternatives = const [],
    this.imageBase64,
    this.isDemo = false,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'breed': breed,
        'confidence': confidence,
        'percentage': percentage,
        'emoji': emoji,
        'origin': origin,
        'group': group,
        'alternatives': alternatives,
        'imageBase64': imageBase64,
        'isDemo': isDemo,
        'timestamp': timestamp.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'] as int,
        breed: json['breed'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        percentage: json['percentage'] as String,
        emoji: json['emoji'] as String? ?? '🐕',
        origin: json['origin'] as String?,
        group: json['group'] as String?,
        alternatives: List<String>.from(json['alternatives'] ?? []),
        imageBase64: json['imageBase64'] as String?,
        isDemo: json['isDemo'] as bool? ?? false,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  /// Confidence category for badge colouring
  String get confidenceLabel {
    if (confidence >= 0.80) return 'High';
    if (confidence >= 0.50) return 'Medium';
    return 'Low';
  }
}