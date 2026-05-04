// Model i pozicionit GPS nga Traccar API
// GPS Position model from Traccar API

class Position {
  final int id;
  final int deviceId;
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed; // km/h
  final double course; // degrees
  final String? address;
  final String? fixTime;
  final Map<String, dynamic> attributes;

  Position({
    required this.id,
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    this.altitude = 0.0,
    this.speed = 0.0,
    this.course = 0.0,
    this.address,
    this.fixTime,
    this.attributes = const {},
  });

  /// Krijon një Position nga JSON / Creates a Position from JSON
  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      id: json['id'] as int? ?? 0,
      deviceId: json['deviceId'] as int? ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      altitude: (json['altitude'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      course: (json['course'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String?,
      fixTime: json['fixTime'] as String?,
      attributes: (json['attributes'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Konverton Position në JSON / Converts Position to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
      'course': course,
      'address': address,
      'fixTime': fixTime,
      'attributes': attributes,
    };
  }

  @override
  String toString() =>
      'Position(id: $id, deviceId: $deviceId, lat: $latitude, lon: $longitude)';
}
