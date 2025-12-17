import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:provider/provider.dart';
import 'package:unotask/models/data_model.dart';
import 'package:unotask/notification_service.dart';
import 'package:unotask/screens/dashboard_screen.dart';
// import 'package:unotask/features/dashboard/screens/dashboard_screen.dart';

Future<void> initializeService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'location_tracking',
      initialNotificationTitle: 'Location Tracking Active',
      initialNotificationContent: 'Monitoring location in the background.',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(autoStart: false, onForeground: onStart),
  );
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  // Initialize services once when the isolate starts.
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(LocationRecordAdapter().typeId)) {
    Hive.registerAdapter(LocationRecordAdapter());
  }
  final box = await Hive.openBox<LocationRecord>('locations');
  final notifications = NotificationService();
  await notifications.init();

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });
    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }
  service.on('stopService').listen((event) {
    box.close();
    service.stopSelf();
  });

  // The logic from _trackLocation will go here, executed periodically.
  Timer.periodic(
    const Duration(seconds: 5),
    (timer) async => await _trackLocation(service, box, notifications),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();

  // Initialize Hive for the main app isolate
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(LocationRecordAdapter().typeId)) {
    Hive.registerAdapter(LocationRecordAdapter());
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: DashboardScreen(),
    );
  }
}

Future<void> _trackLocation(
  ServiceInstance service,
  Box<LocationRecord> box,
  NotificationService notifications,
) async {
  // A. Fetch Location
  Position? pos;
  try {
    pos = await Geolocator.getCurrentPosition(
      forceAndroidLocationManager: true,
    );
  } catch (_) {
    // Could not get location, do nothing.
    return;
  }

  // If position is null, we can't proceed.
  if (pos == null) {
    return;
  }

  String addr = "Address not available";
  try {
    // B. Fetch Address
    List<Placemark> placemarks = await placemarkFromCoordinates(
      pos.latitude,
      pos.longitude,
    );
    // Construct a more detailed address
    final p = placemarks.first;
    addr = [
      p.name,
      p.street,
      p.subLocality,
      p.locality,
      p.administrativeArea,
      p.country,
    ].where((s) => s != null && s.isNotEmpty).join(', ');
    if (addr.isEmpty) {
      addr = "Address not available";
    }
  } catch (_) {
    // Ignore if geocoding fails (e.g., no network).
  }

  // C. Save to Hive
  final now = DateTime.now();
  final record = LocationRecord(
    time: now
        .toIso8601String(), // Store full ISO 8601 string for better parsing
    latitude: pos.latitude,
    longitude: pos.longitude,
    address: addr,
  );
  box.add(record);

  // D. Show Notification
  notifications.showNotification(
    "New Location Recorded",
    "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}\n$addr",
  );

  // E. Send data to the UI
  service.invoke(
    'update',
    record.toJson(), // Convert record to a map
  );
}
