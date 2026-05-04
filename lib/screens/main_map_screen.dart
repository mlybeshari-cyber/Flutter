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
  Timer? _refreshTimer;
  final MapController _mapController = MapController();

  // Shtresat e hartës / Map tile layers
  int _currentLayer = 0;
  final List<Map<String, String>> _layers = [
    {
      'name': 'Standard',
      'url': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    },
    {
      'name': 'Satellite',
      'url':
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    },
    {
      'name': 'Terrain',
      'url': 'https://tile.opentopomap.org/{z}/{x}/{y}.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _silentRefresh(),
    );
  }

  Future<void> _silentRefresh() async {
    if (!mounted) return;
    try {
      final service = context.read<TraccarService>();
      final devices = await service.getDevices();
      final positions = await service.getPositions();
      if (mounted) {
        setState(() {
          _devices = devices;
          _positions = positions;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    try {
      final service = context.read<TraccarService>();
      final devices = await service.getDevices();
      final positions = await service.getPositions();
      if (mounted) {
        setState(() {
          _devices = devices;
          _positions = positions;
        });
      }
    } catch (_) {}
  }

  // Merr pozicionin e pajisjes / Get device position
  Position? _getPosition(int deviceId) {
    try {
      return _positions.firstWhere((p) => p.deviceId == deviceId);
    } catch (_) {
      return null;
    }
  }

  // Ikona e makinës sipas statusit / Car icon by status
  Color _deviceColor(Device device) {
    switch (device.status) {
      case 'online':
        return Colors.green;
      case 'offline':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // Shkyçja / Logout
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
            child:
                const Text('Shkyçu', style: TextStyle(color: Colors.white)),
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
      _startAutoRefresh();
    }
  }

  // Hap listën e pajisjeve si Drawer / Opens device list as drawer
  void _openDeviceList() {
    _refreshTimer?.cancel();
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car,
                        color: Color(0xFF1565C0)),
                    const SizedBox(width: 8),
                    Text(
                      'Pajisjet (${_devices.length})',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
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
                      leading: Icon(Icons.directions_car,
                          color: _deviceColor(d)),
                      title: Text(d.name,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(d.status ?? 'Unknown'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        if (pos != null) {
                          _mapController.move(
                            LatLng(pos.latitude, pos.longitude),
                            15.0,
                          );
                        }
                        Future.delayed(
                            const Duration(milliseconds: 300), () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => MapScreen(device: d)),
                          ).then((_) => _startAutoRefresh());
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
    ).then((_) => _startAutoRefresh());
  }

  // Vendos hartën te pozicioni im / Center map to my location
  void _centerToAlbania() {
    _mapController.move(LatLng(41.3275, 19.8187), 7.0);
  }

  // Ndrysho shtresën e hartës / Switch map layer
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
          // ── Harta e plotë / Full map ──────────────────────────────────────
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
              // Markerët e pajisjeve / Device markers
              MarkerLayer(
                markers: _devices.map((device) {
                  final pos = _getPosition(device.id);
                  if (pos == null) return null;
                  return Marker(
                    point: LatLng(pos.latitude, pos.longitude),
                    width: 70,
                    height: 60,
                    child: GestureDetector(
                      onTap: () {
                        _refreshTimer?.cancel();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => MapScreen(device: device)),
                        ).then((_) => _startAutoRefresh());
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
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
                          Icon(
                            Icons.directions_car,
                            color: _deviceColor(device),
                            size: 28,
                            shadows: const [
                              Shadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2))
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).whereType<Marker>().toList(),
              ),
            ],
          ),

          // ── Menu sipër majtë / Top-left menu ─────────────────────────────
          Positioned(
            top: 40,
            left: 12,
            child: _mapButton(
              icon: Icons.menu,
              onTap: () {
                _refreshTimer?.cancel();
                Scaffold.of(context).openDrawer();
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
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
                          leading: const Icon(Icons.person),
                          title: Text(widget.session.name),
                          subtitle: const Text('I kyçur / Logged in'),
                        ),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.directions_car,
                              color: Color(0xFF1565C0)),
                          title: const Text('Pajisjet / Devices'),
                          onTap: () {
                            Navigator.pop(context);
                            _openDeviceList();
                          },
                        ),
                        ListTile(
                          leading:
                              const Icon(Icons.logout, color: Colors.red),
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
                ).then((_) => _startAutoRefresh());
              },
            ),
          ),

          // ── Butonat sipër djathtas / Top-right buttons ────────────────────
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
                  icon: Icons.fullscreen,
                  onTap: () {
                    _mapController.move(LatLng(41.3275, 19.8187), 7.0);
                  },
                ),
                const SizedBox(height: 8),
                _mapButton(
                  icon: Icons.my_location,
                  onTap: _centerToAlbania,
                ),
              ],
            ),
          ),

          // ── Butonat poshtë majtë / Bottom-left buttons ────────────────────
          Positioned(
            bottom: 32,
            left: 12,
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
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Reports — duke ardhur / coming soon')),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _mapButton(
                  icon: Icons.warning_amber_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Alerts — duke ardhur / coming soon')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget i butonit të hartës / Map button widget
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
