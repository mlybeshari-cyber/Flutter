import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/device.dart';
import '../models/position.dart';
import '../services/traccar_service.dart';

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

  Widget _buildInfoPanel() {
    final pos = _position!;
    return Card(
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      elevation: 8,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Titull i panelit / Panel title
          InkWell(
            onTap: () => setState(
                () => _infoPanelExpanded = !_infoPanelExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF1565C0)),
                  const SizedBox(width: 8),
                  Text(
                    'Detajet e Pozicionit / Position Details',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _infoPanelExpanded
                        ? Icons.expand_more
                        : Icons.expand_less,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          if (_infoPanelExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Rreshti 1: Koordinatat / Row 1: Coordinates
                  _buildInfoRow(
                    Icons.my_location,
                    'Koordinatat / Coordinates',
                    '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}',
                  ),
                  const SizedBox(height: 8),

                  // Rreshti 2: Shpejtësia / Row 2: Speed
                  _buildInfoRow(
                    Icons.speed,
                    'Shpejtësia / Speed',
                    _formatSpeed(pos.speed),
                  ),
                  const SizedBox(height: 8),

                  // Rreshti 3: Lartësia / Row 3: Altitude
                  _buildInfoRow(
                    Icons.landscape,
                    'Lartësia / Altitude',
                    '${pos.altitude.toStringAsFixed(0)} m',
                  ),
                  const SizedBox(height: 8),

                  // Rreshti 4: Drejtimi / Row 4: Course
                  _buildInfoRow(
                    Icons.navigation,
                    'Drejtimi / Course',
                    _formatCourse(pos.course),
                  ),
                  const SizedBox(height: 8),

                  // Rreshti 5: Koha / Row 5: Time
                  _buildInfoRow(
                    Icons.access_time,
                    'Koha / Time',
                    _formatTime(pos.fixTime),
                  ),

                  // Adresa nëse ekziston / Address if exists
                  if (pos.address != null && pos.address!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.place,
                      'Adresa / Address',
                      pos.address!,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1565C0)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
