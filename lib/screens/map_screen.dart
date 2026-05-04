import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/device.dart';
import '../models/position.dart';
import '../services/traccar_service.dart';
import 'device_detail_screen.dart';

// Ekrani i hartës / Map screen

class MapScreen extends StatefulWidget {
  final Device device;

  const MapScreen({super.key, required this.device});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Position? _position;
  bool _isLoading = false;
  String? _errorMessage;
  bool _infoPanelExpanded = true;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadPosition();
  }

  // Ngarkon pozicionin aktual / Loads current position
  Future<void> _loadPosition() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = context.read<TraccarService>();
      final positions = await service.getPositions(deviceId: widget.device.id);
      if (mounted) {
        setState(() {
          _position = positions.isNotEmpty ? positions.first : null;
        });
        // Lëviz hartën te pozicioni / Move map to position
        if (_position != null) {
          _mapController.move(
            LatLng(_position!.latitude, _position!.longitude),
            15.0,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Formon shpejtësinë / Format speed
  String _formatSpeed(double speedKnots) {
    // Konverto nga nodi në km/h / Convert from knots to km/h
    final kmh = speedKnots * 1.852;
    return '${kmh.toStringAsFixed(1)} km/h';
  }

  // Formon kohën / Format time
  String _formatTime(String? isoTime) {
    if (isoTime == null) return 'N/A';
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      return DateFormat('dd/MM/yyyy HH:mm:ss').format(dt);
    } catch (_) {
      return isoTime;
    }
  }

  // Formon drejtimin / Format course
  // Shkurtesat: N=Veri, NE=Veri-Lindje, E=Lindje, SE=Jug-Lindje,
  //             S=Jug, SW=Jug-Perëndim, W=Perëndim, NW=Veri-Perëndim
  String _formatCourse(double course) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((course + 22.5) / 45).floor() % 8;
    return '${course.toStringAsFixed(0)}° ${directions[index]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.device.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rifresko / Refresh',
            onPressed: _isLoading ? null : _loadPosition,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Harta / Map
          _buildMap(),

          // Paneli i informacionit / Info panel
          if (_position != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildInfoPanel(),
            ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),

          // Error overlay
          if (_errorMessage != null && !_isLoading)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red.shade700, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            setState(() => _errorMessage = null),
                        iconSize: 20,
                        color: Colors.red.shade700,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  
  Widget _buildBottomSheet() {
    final pos = _position!;
    final totalDistance = pos.totalDistance ?? pos.odometer;
    final todayDistance = totalDistance != null
        ? '${(totalDistance / 1000).toStringAsFixed(0)} km driven today'
        : 'No distance data';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.image, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            '1 of 12',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 16),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 16),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.device.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: pos.speedKmh < 1.0 ? Colors.red : Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      pos.speedKmh < 1.0 ? 'Parked' : 'Moving',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (pos.address != null)
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pos.address!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      todayDistance,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DeviceDetailScreen(
                            device: widget.device,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View more',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    // Pozicioni fillestar / Default position (Tirana, Albania)
    final defaultCenter = LatLng(41.3275, 19.8187);
    final center = _position != null
        ? LatLng(_position!.latitude, _position!.longitude)
        : defaultCenter;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: _position != null ? 15.0 : 10.0,
      ),
      children: [
        // OpenStreetMap tiles
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.traccar.flutter',
        ),

        // Markeri i pajisjes / Device marker
        if (_position != null)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(_position!.latitude, _position!.longitude),
                width: 60,
                height: 60,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.device.name,
                        style: const TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 32,
                    ),
                  ],
                ),
              ),
            ],
          ),
      ],
    );
  }

  

