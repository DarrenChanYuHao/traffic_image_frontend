// This contains the necessary API calls for the app
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:latlong2/latlong.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';

class ApiService {
  Future<List<dynamic>> fetchCameraLocationData() async {
    // This fetch the latitude and longitude of the cameras from
    // https://api.data.gov.sg/v1/transport/traffic-images

    final url = Uri.parse(
        'https://api.data.gov.sg/v1/transport/traffic-images');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Get only the latitude and longitude of the cameras
        final cameras = data['items'][0]['cameras'];
        final cameraLocations = cameras.map((camera) {
          return {'camera_id': camera['camera_id'],
            'LatLng': LatLng(camera['location']['latitude'],
                camera['location']['longitude']),
            'image': camera['image']
          };
        }).toList();
        return cameraLocations;
      } else {
        print('Failed to load camera location data');
        return [];
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }
}

class RoutingService {
  Future<List<LatLng>> getDrivingRoute(LatLng start, LatLng end) async {
    final url = Uri.parse(
      'https://traffic-api.darrenchanyuhao.com/route'
          '?start=${start.latitude},${start.longitude}'
          '&end=${end.latitude},${end.longitude}'
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch route: HTTP ${response.statusCode}');
    }

    final data = json.decode(response.body);
    if (data['route_geometry'] == null) {
      throw Exception('No valid route found. Response: ${data.toString()}');
    }

    // Decode the polyline string
    final String encoded = data['route_geometry'];
    final List<List<num>> decoded = decodePolyline(encoded);

    // Convert to List<LatLng>
    return decoded
        .map((coords) => LatLng(coords[0].toDouble(), coords[1].toDouble()))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getSearchLocationLatLng(String query) async {
    final url = Uri.parse(
        'https://traffic-api.darrenchanyuhao.com/search?searchVal=$query');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final results = data['results'] as List?;
      if (results != null && results.isNotEmpty) {
        return results.map((result) {
          final lat = double.parse(result['LATITUDE']);
          final lng = double.parse(result['LONGITUDE']);
          final address = result['ADDRESS'];
          return {
            'address': address,
            'latlng': LatLng(lat, lng),
          };
        }).toList();
      } else {
        return [];
      }
    } else {
      throw Exception('Failed to fetch location: ${response.statusCode}');
    }
  }
}