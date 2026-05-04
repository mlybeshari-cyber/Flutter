import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../models/position.dart';
import '../services/traccar_service.dart';
import 'map_screen.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Position? _position;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPosition();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      final positions = await service.getPositions(deviceId: widget.device.id);
      if (mounted && positions.isNotEmpty) {
        setState(() => _position = positions.first);
      }
    } catch (_) {}
  }

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
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  bool get _isParked {
    if (_position == null) return true;
    return _position!.speedKmh < 1.0;
  }

  String get _statusText => _isParked ? 'Parked' : 'Moving';
  Color get _statusColor => _isParked ? Colors.red : Colors.green;

  String _formatTime(String? isoTime) {
    if (isoTime == null) return 'N/A';
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')} '
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return isoTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          widget.device.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF1565C0),
          labelColor: const Color(0xFF1565C0),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Status'),
            Tab(text: 'Events'),
            Tab(text: 'Trips'),
            Tab(text: 'Commands'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatusTab(),
          _buildEventsTab(),
          _buildTripsTab(),
          _buildCommandsTab(),
        ],
      ),
    );
  }

  Widget _buildStatusTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPosition,
              icon: const Icon(Icons.refresh),
              label: const Text('Provo perseri / Try again'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPosition,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(),
            const SizedBox(height: 8),
            if (_position?.address != null) _buildAddressCard(),
            const SizedBox(height: 8),
            _buildDailyStatsCard(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MAPPED FIELDS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Showing: Alphabetical, Ascending',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
            _buildMappedFieldsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: _statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _statusText,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.map_outlined, color: Colors.grey),
              onPressed: () {
                _refreshTimer?.cancel();
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (_) => MapScreen(device: widget.device),
                  ),
                )
                    .then((_) {
                  _loadPosition();
                  _startAutoRefresh();
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined,
                    color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _position!.address!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(
                'Position updated: ${_formatTime(_position!.fixTime)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyStatsCard() {
    final totalDistance = _position?.totalDistance ?? _position?.odometer;
    final todayDistance = totalDistance != null
        ? '${(totalDistance / 1000).toStringAsFixed(0)} km driven today'
        : 'No distance data';

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    color: Colors.grey.shade600, size: 18),
                const SizedBox(width: 12),
                Text(
                  todayDistance,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(
                'Started the day at 08:51:40',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMappedFieldsCard() {
    if (_position == null) return const SizedBox.shrink();

    final fields = <Map<String, dynamic>>[];

    fields.add({
      'name': 'Altitude',
      'value': '${_position!.altitude.toStringAsFixed(0)} m',
      'time': _formatTime(_position!.fixTime),
    });

    _position!.attributes.forEach((key, value) {
      String displayValue = value.toString();
      String displayName = key;

      if (key == 'batteryLevel') {
        displayValue = '${(value as num).toStringAsFixed(2)} %';
        displayName = 'Battery level';
      } else if (key == 'batteryCurrent') {
        displayValue = (value as num).toStringAsFixed(2);
        displayName = 'BatteryCurrent';
      } else if (key == 'batteryVoltage') {
        displayValue = (value as num).toStringAsFixed(2);
        displayName = 'BatteryVoltage';
      } else if (key == 'cellId') {
        displayValue = '${(value as num).toStringAsFixed(2)}';
        displayName = 'CellID';
      } else if (key == 'ignition') {
        displayValue = value.toString();
        displayName = 'Ignition';
      } else if (key == 'motion') {
        displayValue = value.toString();
        displayName = 'Motion';
      } else if (key == 'power') {
        displayValue = (value as num).toStringAsFixed(2);
        displayName = 'Power';
      } else if (key == 'odometer') {
        displayValue = '${(value as num).toStringAsFixed(0)} m';
        displayName = 'Odometer';
      } else if (key == 'totalDistance') {
        displayValue = '${((value as num) / 1000).toStringAsFixed(1)} km';
        displayName = 'Total Distance';
      } else if (key == 'analogInput1') {
        displayValue = (value as num).toStringAsFixed(2);
        displayName = 'AnalogInput1';
      }

      fields.add({
        'name': displayName,
        'value': displayValue,
        'time': _formatTime(_position!.fixTime),
      });
    });

    fields.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: fields.map((field) {
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            field['name'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Last changed: ${field['time']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      field['value'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (field != fields.last)
                Divider(height: 1, indent: 16, color: Colors.grey.shade200),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEventsTab() {
    return const Center(
      child: Text(
        'Events\nSe shpejti / Coming soon',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }

  Widget _buildTripsTab() {
    return const Center(
      child: Text(
        'Trips\nSe shpejti / Coming soon',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }

  Widget _buildCommandsTab() {
    return const Center(
      child: Text(
        'Commands\nSe shpejti / Coming soon',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey, fontSize: 16),
      ),
    );
  }
}
