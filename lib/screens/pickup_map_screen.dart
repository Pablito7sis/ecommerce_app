import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
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
  static const int _movementSteps = 60;

  final MapController _mapController = MapController();
  final Distance _distance = const Distance();

  StreamSubscription<Position>? _positionSubscription;
  Timer? _simulationTimer;
  LatLng _userLocation = _fallbackUserStart;
  List<LatLng> _routePoints = [_fallbackUserStart, _storeLocation];
  List<LatLng> _movementRoute = [_fallbackUserStart, _storeLocation];
  String _status = 'Buscando tu ubicacion...';
  bool _isMovingToStore = false;
  LatLng? _movementStart;
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
    final routePoints = _routePoints.length > 1
        ? _routePoints
        : [_userLocation, _storeLocation];
    final distanceKm = _routeLength(routePoints) / 1000;

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isMovingToStore
                    ? _stopMovementToStore
                    : _startMovementToStore,
                icon: Icon(
                  _isMovingToStore
                      ? Icons.pause_circle_outline
                      : Icons.navigation_outlined,
                ),
                label: Text(
                  _isMovingToStore
                      ? 'Detener movimiento'
                      : 'Mover ruta hasta la tienda',
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
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
          ],
        ),
      ),
    );
  }

  Future<void> _startLocationTracking() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await _loadStreetRoute(_userLocation);
        if (!mounted) return;
        setState(
          () => _status = 'Ubicacion no disponible. Puedes simular la ruta.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await _loadStreetRoute(_userLocation);
        if (!mounted) return;
        setState(() => _status = 'Permiso denegado. Puedes simular la ruta.');
        return;
      }

      await _loadStreetRoute(_userLocation);

      final currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;

      final currentLocation = LatLng(
        currentPosition.latitude,
        currentPosition.longitude,
      );
      setState(() => _status = 'Ubicacion real activa');
      setState(() => _userLocation = currentLocation);
      _mapController.move(currentLocation, 14);
      await _loadStreetRoute(currentLocation);
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen((position) {
            final nextLocation = LatLng(position.latitude, position.longitude);
            if (!mounted || _isMovingToStore) return;
            setState(() => _userLocation = nextLocation);
            _mapController.move(nextLocation, 14);
            _loadStreetRoute(nextLocation);
          });
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _status = 'No se pudo leer tu ubicacion. Puedes simular la ruta.',
      );
    }
  }

  Future<void> _loadStreetRoute(LatLng start) async {
    final uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/${start.longitude},${start.latitude};${_storeLocation.longitude},${_storeLocation.latitude}',
      {'overview': 'full', 'geometries': 'geojson'},
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode != 200) {
        throw Exception('Route service failed');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>;
      if (routes.isEmpty) {
        throw Exception('No route found');
      }

      final geometry = routes.first['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List<dynamic>;
      final nextRoute = coordinates.map((coordinate) {
        final point = coordinate as List<dynamic>;
        return LatLng(
          (point[1] as num).toDouble(),
          (point[0] as num).toDouble(),
        );
      }).toList();

      if (!mounted || nextRoute.length < 2) return;
      setState(() {
        _routePoints = nextRoute;
        _status = 'Ruta real por calles lista';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _routePoints = [start, _storeLocation];
        _status = 'No se pudo cargar la ruta por calles';
      });
    }
  }

  Future<void> _startMovementToStore() async {
    _positionSubscription?.pause();
    _simulationTimer?.cancel();
    await _loadStreetRoute(_userLocation);
    _movementRoute = _routeWithCurrentStart(_userLocation);
    _movementStart = _userLocation;
    _simulationStep = 0;
    setState(() {
      _isMovingToStore = true;
      _status = 'Moviendo la ruta hacia la tienda';
    });

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 120), (
      timer,
    ) {
      _simulationStep = (_simulationStep + 1).clamp(0, _movementSteps);
      final progress = _simulationStep / _movementSteps;
      final nextLocation = _getRouteLocationAt(progress);

      if (!mounted) {
        return;
      }

      setState(() {
        _userLocation = nextLocation;
        _routePoints = _remainingRouteFrom(nextLocation);
      });
      _mapController.move(nextLocation, 14);

      if (_simulationStep == _movementSteps) {
        timer.cancel();
        setState(() {
          _isMovingToStore = false;
          _status = 'Llegaste a la tienda';
        });
      }
    });
  }

  LatLng _getRouteLocationAt(double progress) {
    final route = _movementRoute.length > 1
        ? _movementRoute
        : [_movementStart ?? _userLocation, _storeLocation];
    final totalMeters = _routeLength(route);
    final targetMeters = totalMeters * progress.clamp(0, 1);
    var traveledMeters = 0.0;

    for (var index = 0; index < route.length - 1; index++) {
      final from = route[index];
      final to = route[index + 1];
      final segmentMeters = _distance.as(LengthUnit.Meter, from, to);
      if (traveledMeters + segmentMeters >= targetMeters) {
        if (segmentMeters == 0) {
          return to;
        }
        final segmentProgress = (targetMeters - traveledMeters) / segmentMeters;
        return LatLng(
          from.latitude + ((to.latitude - from.latitude) * segmentProgress),
          from.longitude + ((to.longitude - from.longitude) * segmentProgress),
        );
      }
      traveledMeters += segmentMeters;
    }

    return _storeLocation;
  }

  List<LatLng> _remainingRouteFrom(LatLng currentLocation) {
    final route = _movementRoute;
    if (route.length < 2) {
      return [currentLocation, _storeLocation];
    }

    var closestIndex = 0;
    var closestDistance = double.infinity;
    for (var index = 0; index < route.length; index++) {
      final distance = _distance.as(
        LengthUnit.Meter,
        currentLocation,
        route[index],
      );
      if (distance < closestDistance) {
        closestDistance = distance;
        closestIndex = index;
      }
    }

    return [currentLocation, ...route.skip(closestIndex + 1)];
  }

  List<LatLng> _routeWithCurrentStart(LatLng start) {
    if (_routePoints.length < 2) {
      return [start, _storeLocation];
    }

    final startsNearRoute =
        _distance.as(LengthUnit.Meter, start, _routePoints.first) < 8;
    return [if (!startsNearRoute) start, ..._routePoints];
  }

  double _routeLength(List<LatLng> route) {
    var meters = 0.0;
    for (var index = 0; index < route.length - 1; index++) {
      meters += _distance.as(LengthUnit.Meter, route[index], route[index + 1]);
    }
    return meters;
  }

  void _stopMovementToStore() {
    _simulationTimer?.cancel();
    _positionSubscription?.resume();
    setState(() {
      _isMovingToStore = false;
      _status = 'Movimiento detenido';
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
