// Testet bazë për modelet e të dhënave
// Basic tests for data models

import 'package:flutter_test/flutter_test.dart';
import 'package:traccar_flutter/models/device.dart';
import 'package:traccar_flutter/models/position.dart';
import 'package:traccar_flutter/models/session.dart';

void main() {
  group('Device Model', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 1,
        'name': 'Vehicle 1',
        'uniqueId': 'ABC123',
        'status': 'online',
        'lastUpdate': '2024-01-01T00:00:00Z',
        'positionId': 42,
        'groupId': 1,
        'attributes': {},
      };

      final device = Device.fromJson(json);

      expect(device.id, 1);
      expect(device.name, 'Vehicle 1');
      expect(device.uniqueId, 'ABC123');
      expect(device.status, 'online');
    });

    test('fromJson handles missing fields with defaults', () {
      final device = Device.fromJson({});

      expect(device.id, 0);
      expect(device.name, '');
      expect(device.status, 'unknown');
      expect(device.attributes, {});
    });

    test('toJson round-trip', () {
      final device = Device(
        id: 5,
        name: 'Test',
        uniqueId: 'ID5',
        status: 'offline',
      );
      final json = device.toJson();

      expect(json['id'], 5);
      expect(json['name'], 'Test');
      expect(json['status'], 'offline');
    });
  });

  group('Position Model', () {
    test('fromJson parses coordinates', () {
      final json = {
        'id': 10,
        'deviceId': 1,
        'latitude': 41.3275,
        'longitude': 19.8187,
        'altitude': 120.0,
        'speed': 50.0,
        'course': 90.0,
        'fixTime': '2024-01-01T12:00:00Z',
        'attributes': {},
      };

      final pos = Position.fromJson(json);

      expect(pos.latitude, 41.3275);
      expect(pos.longitude, 19.8187);
      expect(pos.speed, 50.0);
    });

    test('fromJson handles missing fields with defaults', () {
      final pos = Position.fromJson({});

      expect(pos.latitude, 0.0);
      expect(pos.longitude, 0.0);
      expect(pos.speed, 0.0);
    });
  });

  group('Session Model', () {
    test('fromJson parses admin field', () {
      final json = {
        'id': 1,
        'name': 'Admin User',
        'email': 'admin@test.com',
        'administrator': true,
        'zoom': 14,
        'attributes': {},
      };

      final session = Session.fromJson(json);

      expect(session.name, 'Admin User');
      expect(session.email, 'admin@test.com');
      expect(session.admin, true);
      expect(session.zoom, 14);
    });
  });
}
