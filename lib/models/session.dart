// Model i sesionit të përdoruesit nga Traccar API
// User session model from Traccar API

class Session {
  final int id;
  final String name;
  final String email;
  final bool admin;
  final String? map;
  final double latitude;
  final double longitude;
  final int zoom;
  final bool readonly;
  final bool deviceReadonly;
  final String? phone;
  final bool limitCommands;
  final String? poiLayer;
  final Map<String, dynamic> attributes;

  Session({
    required this.id,
    required this.name,
    required this.email,
    this.admin = false,
    this.map,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.zoom = 12,
    this.readonly = false,
    this.deviceReadonly = false,
    this.phone,
    this.limitCommands = false,
    this.poiLayer,
    this.attributes = const {},
  });

  /// Krijon një Session nga JSON / Creates a Session from JSON
  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      admin: json['administrator'] as bool? ?? false,
      map: json['map'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      zoom: json['zoom'] as int? ?? 12,
      readonly: json['readonly'] as bool? ?? false,
      deviceReadonly: json['deviceReadonly'] as bool? ?? false,
      phone: json['phone'] as String?,
      limitCommands: json['limitCommands'] as bool? ?? false,
      poiLayer: json['poiLayer'] as String?,
      attributes: (json['attributes'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Konverton Session në JSON / Converts Session to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'administrator': admin,
      'map': map,
      'latitude': latitude,
      'longitude': longitude,
      'zoom': zoom,
      'readonly': readonly,
      'deviceReadonly': deviceReadonly,
      'phone': phone,
      'limitCommands': limitCommands,
      'poiLayer': poiLayer,
      'attributes': attributes,
    };
  }

  @override
  String toString() => 'Session(id: $id, name: $name, email: $email)';
}
