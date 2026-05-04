// Model i pajisjes GPS nga Traccar API
// GPS Device model from Traccar API

class Device {
  final int id;
  final String name;
  final String uniqueId;
  final String status; // 'online', 'offline', 'unknown'
  final String? lastUpdate;
  final int? positionId;
  final int? groupId;
  final Map<String, dynamic> attributes;

  Device({
    required this.id,
    required this.name,
    required this.uniqueId,
    required this.status,
    this.lastUpdate,
    this.positionId,
    this.groupId,
    this.attributes = const {},
  });

  /// Krijon një Device nga JSON / Creates a Device from JSON
  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      uniqueId: json['uniqueId'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      lastUpdate: json['lastUpdate'] as String?,
      positionId: json['positionId'] as int?,
      groupId: json['groupId'] as int?,
      attributes: (json['attributes'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Konverton Device në JSON / Converts Device to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'uniqueId': uniqueId,
      'status': status,
      'lastUpdate': lastUpdate,
      'positionId': positionId,
      'groupId': groupId,
      'attributes': attributes,
    };
  }

  @override
  String toString() => 'Device(id: $id, name: $name, status: $status)';
}
