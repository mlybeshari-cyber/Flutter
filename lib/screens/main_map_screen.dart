import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../models/position.dart';
import '../models/session.dart';
import '../services/traccar_service.dart';
import 'login_screen.dart';
import 'map_screen.dart';

// Ekrani kryesor me hartë të plotë / Main full-screen map screen

// Statuset e mundshme të ikonave / Possible icon states
enum DeviceMarkerState {
  moving,   // 🟢 Shigjetë jeshile — ignition=true, speed > 2 km/h
  idle,     // 🔵 Pause blu    — ignition=true, speed < 1 km/h
  parked,   // 🟡 Parking      — ignition=false
  pending,  // 🟠 Satelit      — satellites > 4 (por nuk ka lëvizje/ignicion)
  offline,  // 🔴 Offline      — lastUpdate > 10 minuta
  unknown,  // ⚫ E panjohur
}

class MainMapScreen extends StatefulWidget {
  final Session session;

  const MainMapScreen({super.key, required this.session});

  @override
  State<MainMapScreen> createState() => _MainMapScreenState();
}

class _MainMapScreenState extends State<MainMapScreen> {
  List<Device> _devices = [];
  List<Position> _positions = [];
  final MapController _mapController = MapController();

  Timer? _refreshTimer;

  int _currentLayer = 0;
  final List<Map<String, String>> _layers = [
    {'name': 'Standard', 'url': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'},
    {
      'name': 'Satellite',
      'url': 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
    },
    {'name': 'Terrain', 'url': 'https://tile.opentopomap.org/{z}/{x}/{y}.png'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _silentRefresh(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _silentRefresh() async {
    if (!mounted) return;
    try {
      final service = context.read<TraccarService>();
      final results = await Future.wait([
        service.getDevices(),
        service.getPositions(),
      ]);
      if (mounted) {
        setState(() {
          _devices = results[0] as List<Device>;
          _positions = results[1] as List<Position>;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    try {
      final service = context.read<TraccarService>();
      final results = await Future.wait([
        service.getDevices(),
        service.getPositions(),
      ]);
      if (mounted) {
        setState(() {
          _devices = results[0] as List<Device>;
          _positions = results[1] as List<Position>;
        });
      }
    } catch (_) {}
  }

  Position? _getPosition(int deviceId) {
    try {
      return _positions.firstWhere((p) => p.deviceId == deviceId);
    } catch (_) {
      return null;
    }
  }

  // ─── Logjika e statusit të markerit / Marker state logic ──────────────────
  //
  // 1. OFFLINE   → lastUpdate > 10 min (kontrollohet tek Device)
  // 2. MOVING    → ignition=true  AND  speed > 2 km/h  → shigjetë jeshile
  // 3. IDLE      → ignition=true  AND  speed < 1 km/h  → pause blu
  // 4. PARKED    → ignition=false                       → P jeshile
  // 5. PENDING   → satellites > 4 (por pa ignicion/lëvizje të qartë)
  // 6. UNKNOWN   → gjithçka tjetër
  DeviceMarkerState _getMarkerState(Device device, Position? pos) {
    // Kontrollo offline: device.status == 'offline' OSE lastUpdate > 10 min
    if (device.status == 'offline') return DeviceMarkerState.offline;

    if (device.lastUpdate != null) {
      try {
        final last = DateTime.parse(device.lastUpdate!);
        if (DateTime.now().difference(last).inMinutes > 10) {
          return DeviceMarkerState.offline;
        }
      } catch (_) {}
    }

    if (pos == null) return DeviceMarkerState.unknown;

    final ignition = pos.ignition;
    final speedKmh = pos.speedKmh;
    final satellites = (pos.attributes['sat'] as num?)?.toInt() ??
        (pos.attributes['satellites'] as num?)?.toInt() ?? 0;

    // Moving: ignition=true dhe speed > 2 km/h
    if (ignition == true && speedKmh > 2) return DeviceMarkerState.moving;

    // Idle: ignition=true dhe speed < 1 km/h
    if (ignition == true && speedKmh < 1) return DeviceMarkerState.idle;

    // Parked: ignition=false
    if (ignition == false) return DeviceMarkerState.parked;

    // Pending: satelitë > 4 (por ignicion i panjohur)
    if (satellites > 4) return DeviceMarkerState.pending;

    return DeviceMarkerState.unknown;
  }

  // Ikona dhe ngjyra sipas statusit / Icon and color by state
  IconData _markerIcon(DeviceMarkerState state) {
    switch (state) {
      case DeviceMarkerState.moving:  return Icons.navigation;        // shigjetë
      case DeviceMarkerState.idle:    return Icons.pause_circle_filled; // pause
      case DeviceMarkerState.parked:  return Icons.local_parking;     // P
      case DeviceMarkerState.pending: return Icons.satellite_alt;      // satelit
      case DeviceMarkerState.offline: return Icons.signal_wifi_off;    // offline
      case DeviceMarkerState.unknown: return Icons.help_outline;
    }
  }

  Color _markerColor(DeviceMarkerState state) {
    switch (state) {
      case DeviceMarkerState.moving:  return Colors.green;
      case DeviceMarkerState.idle:    return const Color(0xFF1E88E5); // blu
      case DeviceMarkerState.parked:  return Colors.amber.shade700;
      case DeviceMarkerState.pending: return Colors.orange;
      case DeviceMarkerState.offline: return Colors.red;
      case DeviceMarkerState.unknown: return Colors.grey;
    }
  }

  String _markerLabel(DeviceMarkerState state) {
    switch (state) {
      case DeviceMarkerState.moving:  return 'Lëvizje';
      case DeviceMarkerState.idle:    return 'Ndal';
      case DeviceMarkerState.parked:  return 'Parkuar';
      case DeviceMarkerState.pending: return 'Në pritje';
      case DeviceMarkerState.offline: return 'Offline';
      case DeviceMarkerState.unknown: return 'I panjohur';
    }
  }

  Future<void> _logout() async {
    _refreshTimer?.cancel();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Shkyçu / Logout'),
        content: const Text('Jeni i sigurt?\nAre you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anulo'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Shkyçu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      final service = context.read<TraccarService>();
      await service.logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      if (mounted) {
        _refreshTimer = Timer.periodic(
          const Duration(seconds: 5),
          (_) => _silentRefresh(),
        );
      }
    }
  }

  void _openDeviceList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        minChildSize: 0.3,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, color: Color(0xFF1565C0)),
                    const SizedBox(width: 8),
                    Text('Pajisjet (${_devices.length})',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: _devices.length,
                  itemBuilder: (_, i) {
                    final d = _devices[i];
                    final pos = _getPosition(d.id);
                    final state = _getMarkerState(d, pos);
                    return ListTile(
                      leading: Icon(_markerIcon(state),
                          color: _markerColor(state), size: 28),
                      title: Text(d.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: _buildDeviceSubtitle(d, pos, state),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        if (pos != null) {
                          _mapController.move(
                              LatLng(pos.latitude, pos.longitude), 15.0);
                        }
                        Future.delayed(const Duration(milliseconds: 200), () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => MapScreen(device: d)),
                          );
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceSubtitle(Device d, Position? pos, DeviceMarkerState state) {
    final label = _markerLabel(state);
    final speedText = pos != null && pos.speedKmh > 0.5
        ? ' • ${pos.speedKmh.toStringAsFixed(0)} km/h'
        : '';
    final satellites = (pos?.attributes['sat'] as num?)?.toInt() ??
        (pos?.attributes['satellites'] as num?)?.toInt();
    final satText = satellites != null ? ' • 🛰 $satellites' : '';
    return Text(
      '$label$speedText$satText',
      style: TextStyle(fontSize: 12, color: _markerColor(state)),
    );
  }

  void _openMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF1565C0),
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
              title: Text(widget.session.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(widget.session.email),
            ),
            const Divider(),
            // Legjenda / Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Wrap(
                spacing: 12,
                runSpacing: 4,
                children: DeviceMarkerState.values.map((s) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_markerIcon(s), color: _markerColor(s), size: 16),
                    const SizedBox(width: 4),
                    Text(_markerLabel(s),
                        style: const TextStyle(fontSize: 11)),
                  ],
                )).toList(),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.directions_car,
                  color: Color(0xFF1565C0)),
              title: Text('Pajisjet (${_devices.length}) / Devices'),
              onTap: () {
                Navigator.pop(context);
                _openDeviceList();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Shkyçu / Logout'),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _switchLayer() {
    setState(() {
      _currentLayer = (_currentLayer + 1) % _layers.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Harta e plotë / Full map ────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(41.3275, 19.8187),
              initialZoom: 7.0,
            ),
            children: [
              TileLayer(
                urlTemplate: _layers[_currentLayer]['url']!,
                userAgentPackageName: 'com.traccar.flutter',
              ),
              MarkerLayer(
                markers: _devices.map((device) {
                  final pos = _getPosition(device.id);
                  if (pos == null) return null;
                  return Marker(
                    point: LatLng(pos.latitude, pos.longitude),
                    width: 72,
                    height: 60,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => MapScreen(device: device)),
                        );
                      },
                      child: _buildMarker(device, pos),
                    ),
                  );
                }).whereType<Marker>().toList(),
              ),
            ],
          ),

          // ── Menu sipër majtë / Top-left menu ───────────────────────────────
          Positioned(
            top: 40,
            left: 12,
            child: _mapButton(icon: Icons.menu, onTap: _openMenu),
          ),

          // ── Butonat djathtas / Right buttons ───────────────────────────────
          Positioned(
            top: 40,
            right: 12,
            child: Column(
              children: [
                _mapButton(
                  icon: Icons.layers,
                  onTap: _switchLayer,
                  tooltip: _layers[_currentLayer]['name']!,
                ),
                const SizedBox(height: 8),
                _mapButton(
                  icon: Icons.zoom_out_map,
                  onTap: () =>
                      _mapController.move(LatLng(41.3275, 19.8187), 7.0),
                ),
                const SizedBox(height: 8),
                _mapButton(
                  icon: Icons.my_location,
                  onTap: () =>
                      _mapController.move(LatLng(41.3275, 19.8187), 7.0),
                ),
              ],
            ),
          ),

          // ── Butonat poshtë majtë / Bottom-left buttons ─────────────────────
          Positioned(
            bottom: 32,
            left: 12,
            child: Column(
              children: [
                _mapButton(
                  icon: Icons.directions_car,
                  onTap: _openDeviceList,
                  badge:
                      _devices.isNotEmpty ? '${_devices.length}' : null,
                ),
                const SizedBox(height: 8),
                _mapButton(
                  icon: Icons.show_chart,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reports — duke ardhur')),
                  ),
                ),
                const SizedBox(height: 8),
                _mapButton(
                  icon: Icons.warning_amber_rounded,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alerts — duke ardhur')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Ndërtimi i markerit sipas statusit / Build marker by state ────────────
  Widget _buildMarker(Device device, Position pos) {
    final state = _getMarkerState(device, pos);
    final icon = _markerIcon(state);
    final color = _markerColor(state);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label me emrin e pajisjes / Device name label
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            device.name,
            style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                overflow: TextOverflow.ellipsis),
          ),
        ),

        // Ikona e statusit / Status icon
        // Nëse lëviz, rrotulloje sipas drejtimit / If moving, rotate by course
        state == DeviceMarkerState.moving
            ? Transform.rotate(
                angle: pos.course * (3.14159265 / 180),
                child: Icon(
                  icon,
                  color: color,
                  size: 30,
                  shadows: const [
                    Shadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2))
                  ],
                ),
              )
            : Icon(
                icon,
                color: color,
                size: 30,
                shadows: const [
                  Shadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2))
                ],
              ),
      ],
    );
  }

  Widget _mapButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 22, color: Colors.black87),
            if (badge != null)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
