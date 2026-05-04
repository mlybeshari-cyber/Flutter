// Model i pozicionit GPS nga Traccar API
// GPS Position model from Traccar API

class Position {
  final int id;
  final int deviceId;
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed;    // knots nga API
  final double course;  // degrees
  final String? address;
  final String? fixTime;
  final String? deviceTime;
  final String? serverTime;
  final bool valid;
  final int accuracy;
  final String? network;
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
    this.deviceTime,
    this.serverTime,
    this.valid = true,
    this.accuracy = 0,
    this.network,
    this.attributes = const {},
  });

  // Shpejtësia në km/h / Speed in km/h
  double get speedKmh => speed * 1.852;

  // Ignicion nga attributes / Ignition from attributes
  bool? get ignition => attributes['ignition'] as bool?;

  // Lëvizje / Motion
  bool? get motion => attributes['motion'] as bool?;

  // Niveli i baterisë / Battery level
  double? get batteryLevel => (attributes['batteryLevel'] as num?)?.toDouble();

  // Tensioni / Voltage
  double? get power => (attributes['power'] as num?)?.toDouble();

  // Kilometrazha / Odometer
  double? get odometer => (attributes['odometer'] as num?)?.toDouble();

  // Distanca totale / Total distance
  double? get totalDistance => (attributes['totalDistance'] as num?)?.toDouble();

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
      deviceTime: json['deviceTime'] as String?,
      serverTime: json['serverTime'] as String?,
      valid: json['valid'] as bool? ?? true,
      accuracy: (json['accuracy'] as num?)?.toInt() ?? 0,
      network: json['network'] as String?,
      attributes: (json['attributes'] as Map<String, dynamic>?) ?? {},
    );
  }

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
      'deviceTime': deviceTime,
      'serverTime': serverTime,
      'valid': valid,
      'accuracy': accuracy,
      'network': network,
      'attributes': attributes,
    };
  }

  @override
  String toString() =>
      'Position(id: $id, deviceId: $deviceId, lat: $latitude, lon: $longitude, speed: ${speedKmh.toStringAsFixed(1)} km/h)';
}
