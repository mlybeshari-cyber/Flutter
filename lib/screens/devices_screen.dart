import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../models/session.dart';
import '../services/traccar_service.dart';
import '../widgets/device_card.dart';
import 'login_screen.dart';
import 'map_screen.dart';

// Ekrani i listës së pajisjeve / Devices list screen

class DevicesScreen extends StatefulWidget {
  final Session session;

  const DevicesScreen({super.key, required this.session});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  List<Device> _devices = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Timer për auto-refresh çdo 4 sekonda / Auto-refresh timer every 4 seconds
  Timer? _refreshTimer;
  static const int _refreshIntervalSeconds = 4;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    // Ndalo timerin kur ekrani mbyllet / Stop timer when screen is closed
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Fillon auto-refresh çdo 4 sekonda / Starts auto-refresh every 4 seconds
  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(
      const Duration(seconds: _refreshIntervalSeconds),
      (_) => _loadDevices(silent: true),
    );
  }

  // Ngarkon listën e pajisjeve / Loads devices list
  // silent=true: nuk tregon loading spinner (për auto-refresh)
  // silent=true: doesn't show loading spinner (for auto-refresh)
  Future<void> _loadDevices({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final service = context.read<TraccarService>();
      final devices = await service.getDevices();
      if (mounted) {
        setState(() {
          _devices = devices;
          if (!silent) _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Shkyçja / Logout
  Future<void> _logout() async {
    _refreshTimer?.cancel();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Shkyçu / Logout'),
        content: const Text(
          'Jeni i sigurt që dëshironi të shkyçeni?\nAre you sure you want to logout?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anulo / Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Shkyçu / Logout',
                style: TextStyle(color: Colors.white)),
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
      // Rinis timerin nëse anulojmë / Restart timer if cancelled
      _startAutoRefresh();
    }
  }

  // Hap ekranin e hartës / Opens map screen
  void _openMap(Device device) {
    // Ndalo timerin gjatë hartës / Pause timer during map view
    _refreshTimer?.cancel();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapScreen(device: device),
      ),
    ).then((_) {
      // Rinis timerin kur kthehemi / Restart timer when we return
      _loadDevices();
      _startAutoRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pajisjet / Devices',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              widget.session.name,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          // Tregues i auto-refresh / Auto-refresh indicator
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${_refreshIntervalSeconds}s',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
          // Butoni i rifreskimit manual / Manual refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rifresko / Refresh',
            onPressed: _isLoading ? null : () => _loadDevices(),
          ),
          // Butoni i daljes / Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Shkyçu / Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _devices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Duke ngarkuar pajisjet...\nLoading devices...'),
          ],
        ),
      );
    }

    if (_errorMessage != null && _devices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadDevices,
                icon: const Icon(Icons.refresh),
                label: const Text('Provo përsëri / Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices_other, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Nuk ka pajisje.\nNo devices found.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Pull-to-refresh lista / Pull-to-refresh list
    return RefreshIndicator(
      onRefresh: _loadDevices,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _devices.length,
        itemBuilder: (context, index) {
          final device = _devices[index];
          return DeviceCard(
            device: device,
            onTap: () => _openMap(device),
          );
        },
      ),
    );
  }
}
