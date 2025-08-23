import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import 'dart:async';
import '../widgets/search_page.dart';
import '../widgets/showCameraImage.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  LatLng? _currentPosition;
  String? _errorMessage;
  MapController? _mapController;
  late Future<List<dynamic>> _cameraPosition;
  Timer? _timer;
  bool _mapReady = false;
  bool isSearching = false;

  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();

  LatLng? _startLocation;
  LatLng? _endLocation;
  List<LatLng>? _routePoints;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  void _initializeApp() async {
    try {
      // Initialize camera data
      _cameraPosition = ApiService().fetchCameraLocationData();

      // Get current position
      await _determinePosition();

      // Set up periodic refresh
      _timer = Timer.periodic(const Duration(minutes: 1), (_) {
        _fetchCameraData();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Initialization failed: $e';
      });
    }
  }

  void _fetchCameraData() async {
    try {
      final cameras = await ApiService().fetchCameraLocationData();
      setState(() {
        _cameraPosition = Future.value(cameras);
      });
      debugPrint('Camera data refreshed');
    } catch (e) {
      debugPrint('Failed to refresh camera data: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _errorMessage = 'Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _errorMessage = 'Location permissions are denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _errorMessage =
        'Location permissions are permanently denied, cannot request.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _errorMessage = null;
      });

      // Move map only if it's ready and controller exists
      if (_currentPosition != null && _mapReady && _mapController != null) {
        _mapController!.move(_currentPosition!, 15.0);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get current location: $e';
      });
    }
  }

  void _goToMyLocation() {
    if (_currentPosition != null && _mapReady && _mapController != null) {
      _mapController!.move(_currentPosition!, 15.0);
    }
  }

  Future<void> _generateRoute() async {
    if (_startLocation == null || _endLocation == null) return;

    try {
      final route = await RoutingService().getDrivingRoute(_startLocation!, _endLocation!);

      setState(() {
        _routePoints = route;
      });

      // Fit camera to route if map is ready
      if (_routePoints != null &&
          _routePoints!.isNotEmpty &&
          _mapReady &&
          _mapController != null) {
        final bounds = LatLngBounds.fromPoints(_routePoints!);
        _mapController!.fitCamera(
          CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(50.0)
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate route: $e';
      });
    }
  }

  void _onSearchLocationSelected(LatLng location, bool isStart) {
    setState(() {
      if (isStart) {
        _startLocation = location;
      } else {
        _endLocation = location;
      }
    });

    if (_mapReady && _mapController != null) {
      _mapController!.move(location, 15.0);
    }

    _generateRoute();
  }

  void _onMapReady() {
    setState(() {
      _mapReady = true;
    });

    // Move to current position if available
    if (_currentPosition != null && _mapController != null) {
      _mapController!.move(_currentPosition!, 15.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text(widget.title),
      ),
      body: _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
                _initializeApp();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : Stack(
        children: [
          // Map (full screen)
          FlutterMap(
            mapController: _mapController ??= MapController(),
            options: MapOptions(
              initialCenter: _currentPosition ?? const LatLng(1.3521, 103.8198),
              initialZoom: 15.0,
              minZoom: 12.0,
              onMapReady: _onMapReady,
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(
                  LatLng(1.144, 103.58), // Southwest corner
                  LatLng(1.494, 104.102), // Northeast corner
                ),
              ),
            ),
            children: [
                TileLayer( urlTemplate: 'https://www.onemap.gov.sg/maps/tiles/Night/{z}/{x}/{y}.png'),
              // Route polyline
              if (_routePoints != null && _routePoints!.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints!,
                      color: Colors.red,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              // Markers
              FutureBuilder<List<dynamic>>(
                future: _cameraPosition,
                builder: (context, snapshot) {
                  List<Marker> markers = [];

                  // Current position marker
                  if (_currentPosition != null) {
                    markers.add(
                      Marker(
                        point: _currentPosition!,
                        width: 40.0,
                        height: 40.0,
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                    );
                  }

                  // Start location marker
                  if (_startLocation != null) {
                    markers.add(
                      Marker(
                        point: _startLocation!,
                        width: 40.0,
                        height: 40.0,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                    );
                  }

                  // End location marker
                  if (_endLocation != null) {
                    markers.add(
                      Marker(
                        point: _endLocation!,
                        width: 40.0,
                        height: 40.0,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 24,
                        ),
                      ),
                    );
                  }

                  // Camera markers
                  if (snapshot.hasData && snapshot.data != null) {
                    try {
                      // If polyline points exist, filter cameras only along the route
                      if (_routePoints != null && _routePoints!.isNotEmpty) {
                        bool _isPointNearRoute(LatLng point, List<LatLng> route, {double tolerance = 0.0005}) {
                          for (int i = 0; i < route.length - 1; i++) {
                            final LatLng start = route[i];
                            final LatLng end = route[i + 1];
                            final double dx = end.latitude - start.latitude;
                            final double dy = end.longitude - start.longitude;

                            final double t = ((point.latitude - start.latitude) * dx + (point.longitude - start.longitude) * dy) /
                                (dx * dx + dy * dy);

                            double nearestLat, nearestLng;

                            if (t < 0) {
                              nearestLat = start.latitude;
                              nearestLng = start.longitude;
                            } else if (t > 1) {
                              nearestLat = end.latitude;
                              nearestLng = end.longitude;
                            } else {
                              nearestLat = start.latitude + t * dx;
                              nearestLng = start.longitude + t * dy;
                            }

                            final double distance = ((point.latitude - nearestLat).abs() + (point.longitude - nearestLng).abs());
                            if (distance <= tolerance) {
                              return true;
                            }
                          }
                          return false;
                        }
                        markers.addAll(snapshot.data!.where((camera) {
                          final LatLng cameraPos = camera['LatLng'] as LatLng;
                          return _isPointNearRoute(cameraPos, _routePoints!);
                        }).map<Marker>((camera) {
                          return Marker(
                            point: camera['LatLng'] as LatLng,
                            width: 40.0,
                            height: 40.0,
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    contentPadding: EdgeInsets.zero,
                                    content: Stack(
                                      children: [
                                        ShowCameraImage(imageUrl: camera['image'] as String),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () => Navigator.pop(context),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              padding: const EdgeInsets.all(8), // very tight padding
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList());


                      } else {
                        debugPrint('No route, showing all cameras');
                        // If no route, show all cameras
                        markers.addAll(snapshot.data!.map<Marker>((camera) {
                          return Marker(
                            point: camera['LatLng'] as LatLng,
                            width: 40.0,
                            height: 40.0,
                            child: IconButton(
                              icon: const Icon(
                                Icons.camera_alt,
                                color: Colors.white60,
                                size: 20,
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    contentPadding: EdgeInsets.zero,
                                    content: ShowCameraImage(imageUrl: camera['image'] as String),
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList());

                      }
                    } catch (e) {
                      debugPrint('Error adding camera markers: $e');
                    }
                  }

                  return MarkerLayer(markers: markers);
                },
              ),
            ],
          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
            top: isSearching ? 0 : -300, // hide above screen
            left: 0,
            right: 0,
            child: SearchPage(
              startController: _startController,
              endController: _endController,
              onSearch: _onSearchLocationSelected,
            ),
          ),
          Positioned(
              bottom: 32,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    onPressed: _goToMyLocation,
                    tooltip: 'My Location',
                    child: const Icon(Icons.my_location),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_routePoints != null && !isSearching) ...[
                        const SizedBox(height: 16),
                        FloatingActionButton(
                            onPressed: () {
                              setState(() {
                                _startLocation = null;
                                _endLocation = null;
                                _routePoints = null;
                                _startController.clear();
                                _endController.clear();
                                isSearching = false;
                              });
                            },
                            tooltip: 'Clear Route',
                            child:
                            const Text("Clear Route", textAlign: TextAlign.center,)
                        ),
                      ],
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        onPressed: () {
                          setState(() {
                            isSearching = !isSearching;
                          });
                        },
                        tooltip: 'Search',
                        child: Icon(isSearching ? Icons.close : Icons.directions),
                      ),
                    ],
                  ),
                ],
              ))
        ],
      ),
    );
  }

  void _showCameraImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Traffic Camera'),
          content: SizedBox(
            width: double.maxFinite,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text('Failed to load image'),
                );
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}
