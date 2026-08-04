enum BackupImportMode { replace, merge }

class BackupPayload {
  BackupPayload({
    required this.version,
    required this.exportedAt,
    required this.appVersion,
    required this.tasks,
    required this.reminders,
    required this.ideas,
    required this.notes,
    required this.prefs,
    required this.voices,
  });

  final int version;
  final String exportedAt;
  final String appVersion;
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> reminders;
  final List<Map<String, dynamic>> ideas;
  final List<Map<String, dynamic>> notes;
  final Map<String, dynamic> prefs;

  /// Map of relative path (e.g. voice_memos/uuid.m4a) → base64.
  final Map<String, String> voices;

  Map<String, dynamic> toJson() => {
        'version': version,
        'exportedAt': exportedAt,
        'appVersion': appVersion,
        'tasks': tasks,
        'reminders': reminders,
        'ideas': ideas,
        'notes': notes,
        'prefs': prefs,
        'voices': voices,
      };

  factory BackupPayload.fromJson(Map<String, dynamic> json) {
    return BackupPayload(
      version: json['version'] as int? ?? 1,
      exportedAt: json['exportedAt'] as String? ?? '',
      appVersion: json['appVersion'] as String? ?? '',
      tasks: _mapList(json['tasks']),
      reminders: _mapList(json['reminders']),
      ideas: _mapList(json['ideas']),
      notes: _mapList(json['notes']),
      prefs: Map<String, dynamic>.from(json['prefs'] as Map? ?? {}),
      voices: Map<String, String>.from(
        (json['voices'] as Map? ?? {}).map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ),
      ),
    );
  }

  static List<Map<String, dynamic>> _mapList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
