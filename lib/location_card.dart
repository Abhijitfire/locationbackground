import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:unotask/map_utils.dart'; // This path is correct
import 'package:unotask/models/data_model.dart';

class LocationCard extends StatelessWidget {
  final LocationRecord record;

  const LocationCard({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final dateTime = DateTime.tryParse(record.time) ?? DateTime.now();
    final formattedTime = DateFormat.yMMMd().add_jms().format(dateTime);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // This is where the magic happens!
          // Print the coordinates to the debug console.
          print(
            'Tapped on card with Lat: ${record.latitude}, Lon: ${record.longitude}',
          );
          MapUtils.openMap(record.latitude, record.longitude);
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formattedTime,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text('Address: ${record.address}'),
              const SizedBox(height: 4),
              Text(
                'Coords: ${record.latitude.toStringAsFixed(4)}, ${record.longitude.toStringAsFixed(4)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
