import 'package:hive/hive.dart';

part 'data_model.g.dart';

@HiveType(typeId: 0)
class LocationRecord extends HiveObject {
  @HiveField(0)
  final String time;
  @HiveField(1)
  final double latitude;
  @HiveField(2)
  final double longitude;
  @HiveField(3)
  final String address;

  LocationRecord({
    required this.time,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }
}
