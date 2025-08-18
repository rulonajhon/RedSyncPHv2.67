import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class ClinicLocatorScreen extends StatefulWidget {
  const ClinicLocatorScreen({super.key});

  @override
  State<ClinicLocatorScreen> createState() => _ClinicLocatorScreenState();
}

class _ClinicLocatorScreenState extends State<ClinicLocatorScreen> {
  GoogleMapController? _mapController;
  String selectedType = "clinic";
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  bool _showList = false;

  final Set<Polyline> _polylines = {};
  Map<String, dynamic>? _selectedLocation;

  // Enhanced clinics data with distance calculation support
  List<Map<String, dynamic>> clinics = [
    {
      'name': 'Dr. Heide P. Abdurahman',
      'type': 'Adult Hematologist',
      'address':
          'Metro Davao Medical & Research Center, J.P. Laurel Ave, Bajada, Davao City',
      'lat': '7.095116',
      'lng': '125.613161',
      'contact': '09099665139',
      'schedule': 'Wed & Fri 1-6 PM',
      'distance': null,
      'distanceValue': double.infinity,
    },
    {
      'name': 'Dr. Lilia Matildo Yu',
      'type': 'Pediatric Hematologist',
      'address':
          'Medical Arts Building, front of San Pedro Hospital, Guerrero St., Davao City',
      'lat': '7.078266',
      'lng': '125.614739',
      'contact': 'Call for info',
      'schedule': 'By appointment',
      'distance': null,
      'distanceValue': double.infinity,
    },
    {
      'name': 'Dr. Jeannie B. Ong',
      'type': 'Pediatric Hematologist',
      'address': 'San Pedro Hospital, Guzman St., Davao City',
      'lat': '7.078959',
      'lng': '125.614977',
      'contact': '09924722148',
      'schedule': 'Mon, Thu & Fri 10 AM-1 PM',
      'distance': null,
      'distanceValue': double.infinity,
    },
  ];

  List<Map<String, dynamic>> drugOutlets = [
    {
      'name': 'Globo Asiatico Enterprises',
      'type': 'Medical Supply',
      'address': 'Door #4 Eldec Realty Bldg., Cabaguio Ave, Agdao, Davao City',
      'lat': '7.0894',
      'lng': '125.6232',
      'contact': '+63 82 224 1234',
      'schedule': 'Mon-Sat 8 AM-6 PM',
      'distance': null,
      'distanceValue': double.infinity,
    },
    {
      'name': 'CLE Bio and Medical Supply',
      'type': 'Medical Supply',
      'address':
          '#003 Chiong Bldg, Flyover, Buhangin (JP Laurel Ave), Davao City',
      'lat': '7.0968',
      'lng': '125.6152',
      'contact': '+63 82 234 5678',
      'schedule': 'Mon-Fri 9 AM-5 PM',
      'distance': null,
      'distanceValue': double.infinity,
    },
  ];

  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    try {
      _initializeLocation();
      _updateMarkers();
    } catch (e) {
      print('Error initializing clinic locator: $e');
    }
  }

  Future<void> _initializeLocation() async {
    try {
      // Try to get location on app start
      await _getCurrentLocation();
    } catch (e) {
      print('Error initializing location: $e');
    }
  }

  // 📍 Enhanced Current Location Detection
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied');
          setState(() {
            _isLoadingLocation = false;
          });
          _showErrorMessage('Location permission is required to find nearby clinics');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('Location permission denied forever');
        setState(() {
          _isLoadingLocation = false;
        });
        _showErrorMessage('Please enable location permission in settings');
        return;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('Location services disabled');
        setState(() {
          _isLoadingLocation = false;
        });
        _showErrorMessage('Please enable location services');
        return;
      }

      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // 📏 Calculate distances and update UI
      _calculateAllDistances();
      _updateMarkers();
      _centerMapOnUser();
      
      print('Location acquired: ${position.latitude}, ${position.longitude}');
      
    } catch (e) {
      print('Error getting current location: $e');
      setState(() {
        _isLoadingLocation = false;
      });
      _showErrorMessage('Unable to get current location: ${e.toString()}');
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // 📏 Enhanced Distance Calculation
  void _calculateAllDistances() {
    if (_currentPosition == null) return;

    try {
      // Calculate distances for clinics
      for (int i = 0; i < clinics.length; i++) {
        final clinic = clinics[i];
        try {
          final lat = double.parse(clinic['lat'] ?? '0');
          final lng = double.parse(clinic['lng'] ?? '0');
          
          final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            lat,
            lng,
          );

          final distanceKm = distance / 1000;
          clinics[i]['distance'] = distanceKm.toStringAsFixed(1);
          clinics[i]['distanceValue'] = distanceKm;
        } catch (e) {
          print('Error parsing coordinates for clinic ${clinic['name']}: $e');
          clinics[i]['distance'] = 'N/A';
          clinics[i]['distanceValue'] = double.infinity;
        }
      }

      // Calculate distances for drug outlets
      for (int i = 0; i < drugOutlets.length; i++) {
        final outlet = drugOutlets[i];
        try {
          final lat = double.parse(outlet['lat'] ?? '0');
          final lng = double.parse(outlet['lng'] ?? '0');
          
          final distance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            lat,
            lng,
          );

          final distanceKm = distance / 1000;
          drugOutlets[i]['distance'] = distanceKm.toStringAsFixed(1);
          drugOutlets[i]['distanceValue'] = distanceKm;
        } catch (e) {
          print('Error parsing coordinates for outlet ${outlet['name']}: $e');
          drugOutlets[i]['distance'] = 'N/A';
          drugOutlets[i]['distanceValue'] = double.infinity;
        }
      }

      // 📊 Smart Sorting by distance
      _sortLocationsByDistance();
      
    } catch (e) {
      print('Error calculating distances: $e');
    }
  }

  // 📊 Smart Sorting Implementation
  void _sortLocationsByDistance() {
    clinics.sort((a, b) => a['distanceValue'].compareTo(b['distanceValue']));
    drugOutlets.sort(
      (a, b) => a['distanceValue'].compareTo(b['distanceValue']),
    );
  }

  // 🎨 Distance Color Coding Implementation
  Color _getDistanceColor(String? distance) {
    if (distance == null) return Colors.grey;

    double dist = double.tryParse(distance) ?? double.infinity;
    if (dist <= 2.0) return Colors.green; // Very close
    if (dist <= 5.0) return Colors.orange; // Moderate distance
    return Colors.red; // Far
  }

  // 🗺️ Enhanced Marker Updates with User Location
  void _updateMarkers() {
    Set<Marker> markers = {};

    try {
      // Add user location marker (Green marker)
      if (_currentPosition != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('user_location'),
            position: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            infoWindow: const InfoWindow(
              title: '📍 Your Location',
              snippet: 'You are here',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }

      // Add location markers based on selected type
      final currentData = _getCurrentDataList();
      for (var location in currentData) {
        try {
          // Safely parse coordinates with validation
          final latStr = location['lat'];
          final lngStr = location['lng'];
          final name = location['name'] ?? 'Unknown Location';

          if (latStr == null || lngStr == null || latStr.isEmpty || lngStr.isEmpty) {
            print('Skipping location $name: Missing coordinates');
            continue;
          }

          final lat = double.tryParse(latStr);
          final lng = double.tryParse(lngStr);

          if (lat == null || lng == null) {
            print('Skipping location $name: Invalid coordinates ($latStr, $lngStr)');
            continue;
          }

          // Validate coordinate ranges
          if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
            print('Skipping location $name: Coordinates out of range ($lat, $lng)');
            continue;
          }

          markers.add(
            Marker(
              markerId: MarkerId(name),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: name,
                snippet: location['distance'] != null
                    ? '${location['distance']} km • ${location['type'] ?? 'Location'}'
                    : location['type'] ?? 'Location',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                selectedType == "clinic"
                    ? BitmapDescriptor.hueRed
                    : BitmapDescriptor.hueBlue,
              ),
              onTap: () => _showLocationDetails(location),
            ),
          );
        } catch (e) {
          print('Error adding marker for ${location['name']}: $e');
        }
      }

      setState(() {
        _markers = markers;
      });
    } catch (e) {
      print('Error updating markers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating map markers: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Center map on user location
  void _centerMapOnUser() {
    try {
      if (_mapController != null && _currentPosition != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          ),
        );
      }
    } catch (e) {
      print('Error centering map on user: $e');
      // Don't show snackbar for this error as it's not critical
    }
  }

  // Get current data list based on selected type
  List<Map<String, dynamic>> _getCurrentDataList() {
    return selectedType == "clinic" ? clinics : drugOutlets;
  }

  // Show location details in a bottom sheet
  void _showLocationDetails(Map<String, dynamic> location) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildLocationBottomSheet(location),
    );
  }

  // Bottom sheet widget for location details
  Widget _buildLocationBottomSheet(Map<String, dynamic> location) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: selectedType == "clinic"
                        ? Colors.redAccent.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    selectedType == "clinic"
                        ? FontAwesomeIcons.userDoctor
                        : FontAwesomeIcons.pills,
                    color: selectedType == "clinic"
                        ? Colors.redAccent
                        : Colors.blue,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        location['type'],
                        style: TextStyle(
                          fontSize: 13,
                          color: selectedType == "clinic"
                              ? Colors.redAccent
                              : Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (location['distance'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDistanceColor(
                        location['distance'],
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${location['distance']} km',
                      style: TextStyle(
                        color: _getDistanceColor(location['distance']),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(FontAwesomeIcons.locationDot, location['address']),
            _buildInfoRow(FontAwesomeIcons.phone, location['contact']),
            _buildInfoRow(FontAwesomeIcons.clock, location['schedule']),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _createRouteToLocation(location),
                    icon: const Icon(FontAwesomeIcons.route, size: 16),
                    label: const Text('Show Route'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedType == "clinic"
                          ? Colors.redAccent
                          : Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(FontAwesomeIcons.xmark, size: 16),
                  label: const Text('Close'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.grey.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _createRouteToLocation(Map<String, dynamic> location) {
    // Close the bottom sheet/modal first
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Current location not available. Please enable location services.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _selectedLocation = location;
      _polylines.clear();

      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route_to_location'),
          points: [
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
            LatLng(
              double.parse(location['lat']!),
              double.parse(location['lng']!),
            ),
          ],
          color: selectedType == "clinic" ? Colors.redAccent : Colors.blue,
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.route, color: Colors.white),
            SizedBox(width: 8),
            Text('Route displayed on map'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    _fitMapToShowBothPoints(location);
  }

  void _fitMapToShowBothPoints(Map<String, dynamic> location) {
    if (_mapController == null || _currentPosition == null) return;

    try {
      final userLat = _currentPosition!.latitude;
      final userLng = _currentPosition!.longitude;
      final locLat = double.parse(location['lat']!);
      final locLng = double.parse(location['lng']!);

      final bounds = LatLngBounds(
        southwest: LatLng(
          userLat < locLat ? userLat : locLat,
          userLng < locLng ? userLng : locLng,
        ),
        northeast: LatLng(
          userLat > locLat ? userLat : locLat,
          userLng > locLng ? userLng : locLng,
        ),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    } catch (e) {
      print('Error fitting map to show both points: $e');
      // Fallback: just move to the destination
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(
            double.parse(location['lat']!),
            double.parse(location['lng']!),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Access Care Locator',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.redAccent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: selectedType == "clinic"
                  ? Colors.redAccent.withOpacity(0.1)
                  : Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton.icon(
              onPressed: _toggleLocationType,
              icon: Icon(
                selectedType == "clinic"
                    ? FontAwesomeIcons.userDoctor
                    : FontAwesomeIcons.pills,
                size: 14,
                color: selectedType == "clinic"
                    ? Colors.redAccent
                    : Colors.blue,
              ),
              label: Text(
                selectedType == "clinic" ? 'Clinics' : 'Outlets',
                style: TextStyle(
                  color: selectedType == "clinic"
                      ? Colors.redAccent
                      : Colors.blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Large Map View
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    )
                  : const LatLng(7.0731, 125.6128),
              zoom: 13,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: (controller) {
              try {
                _mapController = controller;
                if (_currentPosition != null) {
                  _centerMapOnUser();
                }
              } catch (e) {
                print('Error initializing map controller: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Map initialization error: ${e.toString()}'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Top Status Bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    selectedType == "clinic"
                        ? FontAwesomeIcons.userDoctor
                        : FontAwesomeIcons.pills,
                    color: selectedType == "clinic"
                        ? Colors.redAccent
                        : Colors.blue,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getCurrentDataList().isNotEmpty
                          ? '${_getCurrentDataList().length} ${selectedType == "clinic" ? "treatment centers" : "drug outlets"} found'
                          : 'Loading locations...',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (_isLoadingLocation)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: selectedType == "clinic"
                            ? Colors.redAccent
                            : Colors.blue,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // List Toggle Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _showList = !_showList;
                      });
                      if (_showList) {
                        _showLocationsList();
                      }
                    },
                    icon: Icon(
                      FontAwesomeIcons.list,
                      color: selectedType == "clinic"
                          ? Colors.redAccent
                          : Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // My Location Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _getCurrentLocation,
                    icon: Icon(
                      FontAwesomeIcons.locationCrosshairs,
                      color: selectedType == "clinic"
                          ? Colors.redAccent
                          : Colors.blue,
                    ),
                  ),
                ),

                const Spacer(),

                // Clear Route Button (if route exists)
                if (_polylines.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          _polylines.clear();
                          _selectedLocation = null;
                        });
                      },
                      icon: Icon(
                        FontAwesomeIcons.xmark,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleLocationType() {
    setState(() {
      selectedType = selectedType == "clinic" ? "drug" : "clinic";
      _polylines.clear();
      _selectedLocation = null;
    });
    _updateMarkers();
  }

  void _showLocationsList() {
    final dataList = _getCurrentDataList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      selectedType == "clinic"
                          ? FontAwesomeIcons.userDoctor
                          : FontAwesomeIcons.pills,
                      color: selectedType == "clinic"
                          ? Colors.redAccent
                          : Colors.blue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedType == "clinic"
                            ? 'Treatment Centers'
                            : 'Drug Outlets',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      '${dataList.length} found',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: Colors.grey.shade200),

              // List
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: dataList.length,
                  itemBuilder: (context, index) {
                    final item = dataList[index];
                    return _buildLocationListItem(item);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationListItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: selectedType == "clinic"
                      ? Colors.redAccent.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  selectedType == "clinic"
                      ? FontAwesomeIcons.userDoctor
                      : FontAwesomeIcons.pills,
                  color: selectedType == "clinic"
                      ? Colors.redAccent
                      : Colors.blue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      item['type'],
                      style: TextStyle(
                        fontSize: 13,
                        color: selectedType == "clinic"
                            ? Colors.redAccent
                            : Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (item['distance'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDistanceColor(item['distance']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${item['distance']} km',
                    style: TextStyle(
                      color: _getDistanceColor(item['distance']),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item['address'],
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _createRouteToLocation(item);
                  },
                  icon: const Icon(FontAwesomeIcons.route, size: 14),
                  label: const Text('Route'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedType == "clinic"
                        ? Colors.redAccent
                        : Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showLocationDetails(item),
                icon: const Icon(FontAwesomeIcons.circleInfo, size: 14),
                label: const Text('Info'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.grey.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
