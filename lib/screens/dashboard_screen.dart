import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hive/hive.dart';
import 'package:unotask/models/data_model.dart';
import 'package:unotask/notification_service.dart';
import 'package:unotask/location_card.dart';
// import 'package:unotask/services/notification_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  Box<LocationRecord>? _box;
  String _buttonText = "Start Tracking";
  bool _isTracking = false;
  final NotificationService _notifications = NotificationService();
  List<LocationRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkServiceStatus();
    // Initialize notifications here for the UI part
    _initHiveAndLoadData();

    // Listen for updates from the background service
    FlutterBackgroundService().on('update').listen((event) {
      if (event != null) {
        final newRecord = LocationRecord(
          time: event['time'],
          latitude: event['latitude'],
          longitude: event['longitude'],
          address: event['address'],
        );
        setState(() {
          // Add the new record to the top of our local list
          _records.insert(0, newRecord);
        });
      }
    });
  }

  Future<void> _initHiveAndLoadData() async {
    await _notifications.init();
    _box = await Hive.openBox<LocationRecord>('locations');
    setState(() {
      // Load initial data from the box
      _records = _box!.values.toList().reversed.toList();
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // When the app is resumed, reload the data from the box to ensure UI is up-to-date.
      setState(() {
        _records = _box?.values.toList().reversed.toList() ?? [];
      });
    }
  }

  void _checkServiceStatus() async {
    bool isRunning = await FlutterBackgroundService().isRunning();
    setState(() {
      _isTracking = isRunning;
      _buttonText = isRunning ? "Stop Tracking" : "Start Tracking";
    });
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Request notification permissions first
    await _notifications.requestPermissions();

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location services are disabled. Please enable the services',
          ),
        ),
      );
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are denied')),
          );
        }
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied, we cannot request permissions.',
            ),
          ),
        );
      }
      return false;
    }
    return true;
  }

  void _toggleTracking() async {
    final service = FlutterBackgroundService();
    var isRunning = await service.isRunning();
    if (isRunning) {
      _records.clear();
      service.invoke(
        "stopService",
      ); // This will clear the box in the background
    } else {
      final hasPermission = await _handleLocationPermission();
      if (hasPermission) {
        service.startService();
      }
    }
    setState(() {
      _isTracking = !isRunning;
      _buttonText = !isRunning ? "Stop Tracking" : "Start Tracking";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Location Tracker")),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _toggleTracking,
                child: Text(_buttonText),
              ),
            ],
          ),
          _isLoading
              ? const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              : Expanded(
                  child: ListView.builder(
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final record = _records[index];
                      return LocationCard(record: record);
                    },
                  ),
                ),
        ],
      ),
    );
  }
}
