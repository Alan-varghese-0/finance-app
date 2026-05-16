import 'package:finance_app/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng initialLocation;

  const LocationPickerScreen({super.key, required this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? mapController;

  late LatLng selectedLocation;

  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();

    selectedLocation = widget.initialLocation;

    markers = {
      Marker(markerId: const MarkerId("selected"), position: selectedLocation),
    };
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      selectedLocation = position;

      markers = {
        Marker(
          markerId: const MarkerId("selected"),
          position: selectedLocation,
        ),
      };
    });
  }

  Future<void> _goToCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final current = LatLng(position.latitude, position.longitude);

      setState(() {
        selectedLocation = current;

        markers = {
          Marker(markerId: const MarkerId("selected"), position: current),
        };
      });

      mapController?.animateCamera(CameraUpdate.newLatLngZoom(current, 16));
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Location")),

      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: selectedLocation,
              zoom: 15,
            ),

            onMapCreated: (controller) {
              mapController = controller;
            },

            onTap: _onMapTapped,

            markers: markers,

            myLocationEnabled: true,
            myLocationButtonEnabled: false,

            zoomControlsEnabled: false,
          ),

          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.black,
              onPressed: _goToCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),

          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.expense,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),

              onPressed: () {
                Navigator.pop(context, selectedLocation);
              },

              child: const Text(
                "Confirm Location",
                style: TextStyle(
                  color: AppColors.background,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }
}
