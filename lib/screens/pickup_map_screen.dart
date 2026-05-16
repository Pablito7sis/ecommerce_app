import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../state/cart_controller.dart';

class PickupMapScreen extends StatefulWidget {
  const PickupMapScreen({super.key, required this.cartController});

  final CartController cartController;

  @override
  State<PickupMapScreen> createState() => _PickupMapScreenState();
}

class _PickupMapScreenState extends State<PickupMapScreen> {
  static const LatLng _storeLocation = LatLng(4.1229, -73.6266);
  static const LatLng _fallbackUserStart = LatLng(4.1429, -73.6466);

  final MapController _mapController = MapController();
  final Distance _distance = const Distance();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _simulationTimer;
  LatLng _userLocation = _fallbackUserStart;
  String _status = 'Buscando tu ubicacion...';
  int _simulationStep = 0;

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routePoints = [_userLocation, _storeLocation];
    final distanceKm = _distance.as(
      LengthUnit.Kilometer,
      _userLocation,
      _storeLocation,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Ruta a la tienda')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _storeLocation,
              initialZoom: 13,
              minZoom: 3,
              maxZoom: 19,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.ecommerce_app',
                maxNativeZoom: 19,
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _storeLocation,
                    width: 52,
                    height: 52,
                    child: _MapPin(
                      icon: Icons.store,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Marker(
                    point: _userLocation,
                    width: 52,
                    height: 52,
                    child: const _MapPin(
                      icon: Icons.person_pin_circle,
                      color: Color(0xFFE4572E),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.route_outlined),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_status)),
                    Text('${distanceKm.toStringAsFixed(2)} km'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: widget.cartController.isCheckingOut
              ? null
              : () => _confirmPickup(context),
          icon: widget.cartController.isCheckingOut
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline),
          label: const Text('Confirmar recogida'),
        ),
      ),
    );
  }

  Future<void> _startLocationTracking() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _startSimulatedMovement();
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _startSimulatedMovement();
        return;
      }

      setState(() => _status = 'Ubicacion real activa');
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen((position) {
            final nextLocation = LatLng(position.latitude, position.longitude);
            setState(() => _userLocation = nextLocation);
            _mapController.move(nextLocation, 14);
          });
    } catch (_) {
      _startSimulatedMovement();
    }
  }

  void _startSimulatedMovement() {
    setState(() => _status = 'Simulando movimiento hacia la tienda');
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _simulationStep = (_simulationStep + 1).clamp(0, 100);
      final progress = _simulationStep / 100;
      final nextLocation = LatLng(
        _fallbackUserStart.latitude +
            ((_storeLocation.latitude - _fallbackUserStart.latitude) *
                progress),
        _fallbackUserStart.longitude +
            ((_storeLocation.longitude - _fallbackUserStart.longitude) *
                progress),
      );

      if (!mounted) {
        return;
      }

      setState(() => _userLocation = nextLocation);
      _mapController.move(nextLocation, 14);

      if (_simulationStep == 100) {
        timer.cancel();
      }
    });
  }

  Future<void> _confirmPickup(BuildContext context) async {
    try {
      await widget.cartController.checkout();
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pedido para recoger en tienda')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo confirmar la recogida')),
        );
      }
    }
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 34),
    );
  }
}
