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

  // Timer — NDALON vetëm në dispose() dhe logout()
  // Timer — stops ONLY on dispose() and logout()
  Timer? _refreshTimer;

  int _currentLayer = 0;
  final List<Map<String, String>> _layers = [
    {'name': 'Standard', 'url': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'},
    {'name': 'Satellite', 'url': 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'},
    {'name': 'Terrain', 'url': 'https://tile.opentopomap.org/{z}/{x}/{y}.png'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    // Fillo timerin — NUK ndalet kurrë derisa të shkyçesh
    // Start timer — NEVER stops until logout
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

  // Refresh i heshtur çdo 5 sek — GJITHMONË aktiv
  // Silent refresh every 5s — ALWAYS active
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
    } catch (_) {
      // Injoro gabimet e rrjetit / Ignore network errors silently
    }
  }

  // Ngarkim fillestar / Initial load
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

  // Ngjyra sipas statusit / Color by status
  Color _deviceColor(Device device) {
    if (device.disabled) return Colors.grey;
    switch (device.status) {
      case 'online': return Colors.green;
      case 'offline': return Colors.red;
      default: return Colors.orange;
    }
  }

  // Shkyçja — vetëm këtu anulohet timeri
  // Logout — only here the timer is cancelled
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
      // Nëse anuloi logout, rinis timerin
      if (mounted) {
        _refreshTimer = Timer.periodic(
          const Duration(seconds: 5),
          (_) => _silentRefresh(),
        );
      }
    }
  }

  void _openDeviceList() {
    // NUK anulojmë timerin / Do NOT cancel timer
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
                width: 40, height: 4,
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
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    return ListTile(
                      leading: Icon(Icons.directions_car, color: _deviceColor(d)),
                      title: Text(d.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: _buildDeviceSubtitle(d, pos),
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
                            MaterialPageRoute(builder: (_) => MapScreen(device: d)),
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

  // Tregon statusin dhe shpejtësinë / Shows status and speed
  Widget _buildDeviceSubtitle(Device d, Position? pos) {
    final statusText = d.disabled ? 'I çaktivizuar' : d.status;
    final speedText = pos != null && pos.speedKmh > 0
        ? ' • ${pos.speedKmh.toStringAsFixed(0)} km/h'
        : '';
    final ignText = pos?.ignition == true ? ' • 🔑 ON' : (pos?.ignition == false ? ' • 🔑 OFF' : '');
    return Text(
      '$statusText$speedText$ignText',
      style: TextStyle(fontSize: 12, color: _deviceColor(d)),
    );
  }

  void _openMenu() {
    // NUK anulojmë timerin / Do NOT cancel timer
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
              width: 40, height: 4,
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
              subtitle: Text(widget.session.email ?? 'GPS Tracking'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.directions_car, color: Color(0xFF1565C0)),
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
          // ── Harta e plotë / Full map ────────────────────────────────────
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
                    width: 70,
                    height: 58,
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

          // ── Menu sipër majtë / Top-left menu ───────────────────────────
          Positioned(
            top: 40, left: 12,
            child: _mapButton(icon: Icons.menu, onTap: _openMenu),
          ),

          // ── Butonat djathtas / Right buttons ───────────────────────────
          Positioned(
            top: 40, right: 12,
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
                  onTap: () => _mapController.move(LatLng(41.3275, 19.8187), 7.0),
                ),
                const SizedBox(height: 8),
                _mapButton(
                  icon: Icons.my_location,
                  onTap: () => _mapController.move(LatLng(41.3275, 19.8187), 7.0),
                ),
              ],
            ),
          ),

          // ── Butonat poshtë majtë / Bottom-left buttons ─────────────────
          Positioned(
            bottom: 32, left: 12,
            child: Column(
              children: [
                _mapButton(
                  icon: Icons.directions_car,
                  onTap: _openDeviceList,
                  badge: _devices.isNotEmpty ? '${_devices.length}' : null,
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

  // Markeri i pajisjes mbi hartë / Device marker on map
  Widget _buildMarker(Device device, Position pos) {
    final color = _deviceColor(device);
    // Rrotullim sipas drejtimit / Rotate by course
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
        Transform.rotate(
          angle: pos.course * (3.14159265 / 180),
          child: Icon(
            Icons.navigation,
            color: color,
            size: 30,
            shadows: const [
              Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
            ],
          ),
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
        width: 44, height: 44,
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
                top: 4, right: 4,
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
