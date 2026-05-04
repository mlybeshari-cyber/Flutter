// Model i pajisjes GPS nga Traccar API
// GPS Device model from Traccar API

class Device {
  final int id;
  final String name;
  final String uniqueId;
  final String status;       // 'online', 'offline', 'unknown'
  final String? lastUpdate;
  final int? positionId;
  final int? groupId;
  final String? phone;
  final String? model;
  final String? contact;
  final String? category;   // 'car', 'truck', 'motorcycle', etc.
  final bool disabled;
  final Map<String, dynamic> attributes;

  Device({
    required this.id,
    required this.name,
    required this.uniqueId,
    required this.status,
    this.lastUpdate,
    this.positionId,
    this.groupId,
    this.phone,
    this.model,
    this.contact,
    this.category,
    this.disabled = false,
    this.attributes = const {},
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      uniqueId: json['uniqueId'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      lastUpdate: json['lastUpdate'] as String?,
      positionId: json['positionId'] as int?,
      groupId: json['groupId'] as int?,
      phone: json['phone'] as String?,
      model: json['model'] as String?,
      contact: json['contact'] as String?,
      category: json['category'] as String?,
      disabled: json['disabled'] as bool? ?? false,
      attributes: (json['attributes'] as Map<String, dynamic>?) ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'uniqueId': uniqueId,
      'status': status,
      'lastUpdate': lastUpdate,
      'positionId': positionId,
      'groupId': groupId,
      'phone': phone,
      'model': model,
      'contact': contact,
      'category': category,
      'disabled': disabled,
      'attributes': attributes,
    };
  }

  @override
  String toString() => 'Device(id: $id, name: $name, status: $status)';
}
