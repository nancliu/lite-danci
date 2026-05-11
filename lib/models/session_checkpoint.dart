/// 学习中断恢复点。
class SessionCheckpoint {
  const SessionCheckpoint({
    required this.dayKey,
    required this.queueWordIds,
    required this.wordIndex,
    required this.stepIndex,
  });

  final String dayKey;
  final List<String> queueWordIds;
  final int wordIndex;
  final int stepIndex;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dayKey': dayKey,
      'queueWordIds': queueWordIds,
      'wordIndex': wordIndex,
      'stepIndex': stepIndex,
    };
  }

  static SessionCheckpoint? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }
    final ids = (json['queueWordIds'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList() ??
        <String>[];
    return SessionCheckpoint(
      dayKey: json['dayKey'] as String? ?? '',
      queueWordIds: ids,
      wordIndex: (json['wordIndex'] as num?)?.toInt() ?? 0,
      stepIndex: (json['stepIndex'] as num?)?.toInt() ?? 0,
    );
  }
}
