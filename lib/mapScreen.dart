import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  CameraPosition? _initialCameraPosition;
  Set<Marker> _markers = {};
  Set<Circle> _circles = {};
  late Timer _locationUpdateTimer;

  @override
  void initState() {
    super.initState();
    _setInitialCameraPosition();
    _addMarkers();
    _addCircle();
    _startLocationUpdates(); // Start location updates using Timer
  }

  void _startLocationUpdates() {
    const updateInterval = Duration(minutes: 15); // Set your desired interval
    _locationUpdateTimer = Timer.periodic(updateInterval, (timer) {
      _backgroundFetchCallback(''); // Call the background fetch callback
    });
  }

  void _backgroundFetchCallback(String taskId) async {
    print('[BackgroundFetch] Event received: $taskId');

    final BackgroundLocationService locationService = BackgroundLocationService();

    await locationService.sendLocationData();

    if (_hasUserArrived()) {
      _stopIntervalCalculation();
      _locationUpdateTimer.cancel(); // Stop the location updates
    }
  }

  bool _hasUserArrived() {
    return false;
  }

  void _stopBackgroundService() {
    _stopIntervalCalculation();
    _locationUpdateTimer.cancel(); // Stop the location updates
    print('Background service stopped.');
  }

  void _stopIntervalCalculation() {
    print('Interval calculation stopped.');
  }

  Future<void> _addCircle() async {
    setState(() {
      _circles.add(
        Circle(
          circleId: const CircleId('destination_circle'),
          center: const LatLng(37.7749, -122.4194), // Replace with your destination coordinates
          radius: 5000, // Radius in meters
          strokeWidth: 2,
          strokeColor: Colors.blue,
          fillColor: Colors.blue.withOpacity(0.1),
        ),
      );
    });
  }

  Future<void> _setInitialCameraPosition() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _initialCameraPosition = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 15.0, // You can adjust the zoom level
      );
    });
  }

  Future<void> _addMarkers() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    double distanceToDestination = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      37.7749, // Replace with destination latitude
      -122.4194, // Replace with destination longitude
    );

    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('user_location'),
          position: LatLng(position.latitude, position.longitude),
          icon: BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: 'Your Location'),
        ),
      );

      _markers.add(
        Marker(
          markerId: MarkerId('destination'),
          position: LatLng(37.7749, -122.4194),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(title: 'Destination'),
        ),
      );

      if (distanceToDestination <= 5000) {
        _stopIntervalCalculation(); // Stop interval calculation upon arrival
        print('You have arrived at your destination.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Location Tracker')),
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) {
              },
              initialCameraPosition: _initialCameraPosition ?? const CameraPosition(
                target: LatLng(37.7749, -122.4194),
                zoom: 12.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _markers,
              circles: _circles,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _stopBackgroundService,
                child: Text('Stop Background Service'),
              ),
              SizedBox(width: 16.0),
              ElevatedButton(
                onPressed: _stopIntervalCalculation,
                child: Text('Stop Interval Calculation'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BackgroundLocationService {
  final CollectionReference locationCollection =
  FirebaseFirestore.instance.collection('locations');

  Future<void> sendLocationData() async {
    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await locationCollection.add({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print('Location data sent to Firestore.');
    } catch (error) {
      print('Error sending location data: $error');
    }
  }
}

