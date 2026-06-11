import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../src/theme_provider.dart';
import '../src/firebase_service.dart';
import '../api_constants.dart';
import '../widgets/widgets.dart';
import 'package:go_router/go_router.dart';

class WalkPetPage extends StatefulWidget {
  const WalkPetPage({super.key});

  @override
  State<WalkPetPage> createState() => _WalkPetPageState();
}

class _WalkPetPageState extends State<WalkPetPage> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  Position? _lastPosition;
  double _totalDistanceMeters = 0;
  double _unsyncedDistanceMeters = 0;
  bool _isWalking = false;
  bool _isLoading = false;
  StreamSubscription<Position>? _positionStreamSubscription;

  final Set<Polyline> _polylines = {};
  final List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError("Location services are disabled.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError("Location permissions are denied");
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _showError("Location permissions are permanently denied.");
      return;
    }

    // Get initial position
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      _showError("Failed to get initial location.");
    }
  }

  void _startWalk() {
    setState(() {
      _isWalking = true;
      _routePoints.clear();
      _polylines.clear();
      _totalDistanceMeters = 0;
      _unsyncedDistanceMeters = 0;
      if (_currentPosition != null) {
        _lastPosition = _currentPosition;
        _routePoints.add(LatLng(_currentPosition!.latitude, _currentPosition!.longitude));
      }
    });

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      )
    ).listen((Position position) {
      if (!mounted) return;

      if (_lastPosition != null) {
        double distance = Geolocator.distanceBetween(
          _lastPosition!.latitude, _lastPosition!.longitude,
          position.latitude, position.longitude,
        );
        
        setState(() {
          _totalDistanceMeters += distance;
          _unsyncedDistanceMeters += distance;
          _currentPosition = position;
          _lastPosition = position;
          _routePoints.add(LatLng(position.latitude, position.longitude));
          
          _polylines.add(Polyline(
            polylineId: const PolylineId('route'),
            points: _routePoints,
            color: Colors.blue,
            width: 5,
          ));
        });

        _mapController?.animateCamera(CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude)
        ));

        // Auto-sync every 100 meters
        if (_unsyncedDistanceMeters >= 100) {
          _syncWalk();
        }
      } else {
        setState(() {
          _currentPosition = position;
          _lastPosition = position;
          _routePoints.add(LatLng(position.latitude, position.longitude));
        });
      }
    });
  }

  void _stopWalk() {
    _positionStreamSubscription?.cancel();
    setState(() {
      _isWalking = false;
    });
    if (_unsyncedDistanceMeters > 0) {
      _syncWalk();
    }
  }

  Future<void> _syncWalk() async {
    if (_unsyncedDistanceMeters <= 0) return;
    
    final distanceToSync = _unsyncedDistanceMeters;
    setState(() {
      _isLoading = true;
      _unsyncedDistanceMeters = 0; // Optimistic reset
    });

    try {
      final headers = await getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/pet-walk-sync'),
        headers: headers,
        body: jsonEncode({
          'distance_meters': distanceToSync,
        })
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Synced ${distanceToSync.toStringAsFixed(0)}m! +${data['reward']} DOGE'), backgroundColor: Colors.green),
          );
        }
      } else {
        // Failed, add back the unsynced amount
        setState(() {
          _unsyncedDistanceMeters += distanceToSync;
        });
        _showError(data['error'] ?? "Sync failed");
      }
    } catch (e) {
      setState(() {
        _unsyncedDistanceMeters += distanceToSync;
      });
      _showError("Network error during sync");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: const GlobalAppBar(),
      drawer: const AppDrawer(),
      body: PageWithFooter(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
                    onPressed: () => context.go('/'),
                  ),
                  const Expanded(
                    child: Text(
                      "Walk Your Shiba!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance icon space
                ],
              ),
            ),
            
            // Stats Panel
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text("Distance", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text("${_totalDistanceMeters.toStringAsFixed(0)} m", style: const TextStyle(fontSize: 20, color: Colors.blue)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text("Unsynced", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text("${_unsyncedDistanceMeters.toStringAsFixed(0)} m", style: const TextStyle(fontSize: 20, color: Colors.orange)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Map Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: _currentPosition == null
                    ? const Center(child: CircularProgressIndicator())
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                          zoom: 16,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        polylines: _polylines,
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                        },
                      ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Controls
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: _isLoading 
                ? const CircularProgressIndicator()
                : _isWalking
                  ? ElevatedButton.icon(
                      onPressed: _stopWalk,
                      icon: const Icon(Icons.stop),
                      label: const Text("End Walk & Sync"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    )
                  : ElevatedButton.icon(
                      onPressed: _startWalk,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Start Walk"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
