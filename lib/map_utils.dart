import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// A utility class for handling map-related actions.
class MapUtils {
  // Making the constructor private prevents instantiation of the class.
  MapUtils._();

  /// Opens the default map application to the given [latitude] and [longitude].
  ///
  /// Constructs a universal Google Maps URL that works on web and mobile.
  /// Throws an exception if the URL cannot be launched.
  static Future<void> openMap(double latitude, double longitude) async {
    // Universal URL that works on both web and mobile
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $googleMapsUrl';
      }
    } catch (e) {
      debugPrint('Error launching map: $e');
      // Optionally, show a snackbar or dialog to the user.
    }
  }
}
