import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Resultado devuelto por el selector de ubicación
class LocationPickerResult {
  final String address;
  final double latitude;
  final double longitude;

  LocationPickerResult({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class LocationPickerScreen extends StatefulWidget {
  final String? initialAddress;
  final double? initialLat;
  final double? initialLng;

  const LocationPickerScreen({
    super.key,
    this.initialAddress,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  LatLng? _selectedPoint;
  LatLng? _userLocation;
  String _address = '';
  bool _isLoadingAddress = false;
  bool _isLoadingLocation = false;
  LatLng _initialCenter = const LatLng(-12.0651, -75.2049); // Huancayo

  @override
  void initState() {
    super.initState();

    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedPoint = LatLng(widget.initialLat!, widget.initialLng!);
      _initialCenter = _selectedPoint!;
      _address = widget.initialAddress ?? '';
    }

    _requestLocationAndCenter();
  }

  Future<void> _requestLocationAndCenter() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Habilita el servicio de ubicación para usar tu posición',
            ),
          ),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Se necesita permiso de ubicación')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        showDialog(
          context: context,
          builder:
              (ctx) => AlertDialog(
                title: const Text('Permiso requerido'),
                content: const Text(
                  'Necesitamos acceder a tu ubicación. Habilita el permiso en la configuración.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await Geolocator.openAppSettings();
                    },
                    child: const Text('Abrir Configuración'),
                  ),
                ],
              ),
        );
      }
      return;
    }

    // Tenemos permiso → obtener ubicación
    _goToCurrentLocation();
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final userLoc = LatLng(position.latitude, position.longitude);

      setState(() {
        _userLocation = userLoc;
        _isLoadingLocation = false;
      });

      // Solo centrar si el usuario no ha seleccionado un punto previo
      if (_selectedPoint == null) {
        _mapController.move(userLoc, 15);
      }
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener ubicación: $e')),
        );
      }
    }
  }

  Future<void> _onMapTap(TapPosition tapPosition, LatLng point) async {
    setState(() {
      _selectedPoint = point;
      _isLoadingAddress = true;
      _address = 'Obteniendo dirección...';
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        point.latitude,
        point.longitude,
      );

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = <String>[
          if (p.street != null && p.street!.isNotEmpty) p.street!,
          if (p.subLocality != null && p.subLocality!.isNotEmpty)
            p.subLocality!,
          if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
          if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty)
            p.administrativeArea!,
        ];

        setState(() {
          _address =
              parts.isNotEmpty ? parts.join(', ') : 'Ubicación seleccionada';
          _isLoadingAddress = false;
        });
      } else {
        setState(() {
          _address = 'Ubicación seleccionada';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      setState(() {
        _address =
            '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
        _isLoadingAddress = false;
      });
    }
  }

  void _confirmSelection() {
    if (_selectedPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toca el mapa para seleccionar una ubicación'),
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      LocationPickerResult(
        address: _address,
        latitude: _selectedPoint!.latitude,
        longitude: _selectedPoint!.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF66BB6A) : Colors.green.shade600;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // ── Mapa ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialCenter,
              initialZoom: 14,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.taller_proyectos_1',
              ),
              MarkerLayer(
                markers: [
                  // Marcador de ubicación del usuario (azul)
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person,
                            color: Colors.blue,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  // Marcador del punto seleccionado (verde/rojo)
                  if (_selectedPoint != null)
                    Marker(
                      point: _selectedPoint!,
                      width: 50,
                      height: 50,
                      alignment: Alignment.topCenter,
                      child: Icon(
                        Icons.location_on,
                        color: accent,
                        size: 50,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ── Header ──
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _buildHeaderButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                    theme: theme,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardColor.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(14),
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
                          Icon(Icons.map_outlined, color: accent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Toca el mapa para elegir ubicación',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: cs.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── FAB mi ubicación ──
          Positioned(
            right: 16,
            bottom: _selectedPoint != null ? 200 : 140,
            child: FloatingActionButton.small(
              heroTag: 'my_location',
              onPressed: _isLoadingLocation ? null : _goToCurrentLocation,
              backgroundColor: theme.cardColor,
              foregroundColor: Colors.blue,
              elevation: 4,
              child:
                  _isLoadingLocation
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Icon(
                        _userLocation != null
                            ? Icons.my_location
                            : Icons.location_searching,
                      ),
            ),
          ),

          // ── Panel inferior ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: cs.onSurface.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      // Dirección seleccionada o instrucciones
                      if (_selectedPoint == null)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.touch_app,
                                color: accent,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Toca un punto en el mapa',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Se mostrará la dirección automáticamente',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: cs.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? cs.surfaceContainerHighest
                                    : accent.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: accent.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.location_on, color: accent, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isLoadingAddress
                                          ? 'Buscando dirección...'
                                          : _address,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                    Text(
                                      '${_selectedPoint!.latitude.toStringAsFixed(4)}, ${_selectedPoint!.longitude.toStringAsFixed(4)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cs.onSurface.withOpacity(0.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_isLoadingAddress)
                                SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: accent,
                                  ),
                                ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Botón confirmar
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton.icon(
                          onPressed:
                              _selectedPoint != null ? _confirmSelection : null,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'Confirmar Ubicación',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            disabledBackgroundColor: cs.onSurface.withOpacity(
                              0.12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.95),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(onPressed: onTap, icon: Icon(icon, size: 20)),
    );
  }
}
