import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mapcn_flutter/mapcn_flutter.dart';
import '../modelos/modelo_empleo.dart';
import '../servicios/servicio_imagen.dart';
import 'pantalla_detalle_empleo.dart';

class MapaEmpleosScreen extends StatefulWidget {
  const MapaEmpleosScreen({super.key});

  @override
  State<MapaEmpleosScreen> createState() => _MapaEmpleosScreenState();
}

class _MapaEmpleosScreenState extends State<MapaEmpleosScreen>
    with SingleTickerProviderStateMixin {
  List<Job> todosEmpleos = [];
  List<Job> empleosFiltrados = [];
  List<LatLng> puntos = [];
  bool isLoading = true;
  bool isLoadingLocation = false;
  MapcnStyle currentStyle = MapcnStyle.dark;
  LatLng? ubicacionActual;
  double radioKm = 10.0;
  bool mostrarSoloCercanos = false;
  MapcnController? mapController;

  @override
  void initState() {
    super.initState();
    mapController = MapcnController(vsync: this);
    _cargarEmpleos();
  }

  Future<void> _cargarEmpleos() async {
    try {
      setState(() => isLoading = true);
      
      final snapshot = await FirebaseFirestore.instance
          .collection('wanka_jobs')
          .orderBy('postedDate', descending: true)
          .limit(100)
          .get();

      todosEmpleos = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        final job = Job.fromJson(data);
        
        // Intentar obtener coordenadas
        try {
          final locations = await locationFromAddress(job.location);
          if (locations.isNotEmpty) {
            job.lat = locations.first.latitude;
            job.lng = locations.first.longitude;
          }
        } catch (e) {
          print('No se pudo geocodificar ${job.location}');
        }
        
        todosEmpleos.add(job);
      }

      setState(() {
        empleosFiltrados = List.from(todosEmpleos);
        isLoading = false;
      });

      _actualizarPuntos();
    } catch (e) {
      print('Error cargando empleos: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _pedirPermisoUbicacion() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar si el servicio de ubicación está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El servicio de ubicación está deshabilitado. Por favor, habilítalo.')),
      );
      return;
    }

    // Verificar permisos
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se necesita permiso de ubicación para mostrar empleos cercanos')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permiso requerido'),
          content: const Text('Necesitamos acceder a tu ubicación para mostrarte empleos cercanos. Por favor, habilita el permiso en la configuración de la app.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Geolocator.openAppSettings();
              },
              child: const Text('Abrir Configuración'),
            ),
          ],
        ),
      );
      return;
    }

    // Si llegamos aquí, tenemos permiso
    _obtenerUbicacionActual();
  }

  Future<void> _obtenerUbicacionActual() async {
    setState(() => isLoadingLocation = true);
    
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        ubicacionActual = LatLng(position.latitude, position.longitude);
        isLoadingLocation = false;
      });

      // Centrar mapa en ubicación actual
      mapController?.flyTo(ubicacionActual!, zoom: 14);

      // Aplicar filtro si está activo
      if (mostrarSoloCercanos) {
        _filtrarPorDistancia();
      }
    } catch (e) {
      print('Error obteniendo ubicación: $e');
      setState(() => isLoadingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener ubicación: $e')),
      );
    }
  }

  void _filtrarPorDistancia() {
    if (ubicacionActual == null) return;

    setState(() {
      empleosFiltrados = todosEmpleos.where((job) {
        if (job.lat == null || job.lng == null) return false;
        
        final distancia = Geolocator.distanceBetween(
          ubicacionActual!.latitude,
          ubicacionActual!.longitude,
          job.lat!,
          job.lng!,
        );
        
        return distancia <= (radioKm * 1000); // Convertir a metros
      }).toList();
      
      _actualizarPuntos();
    });
  }

  void _actualizarPuntos() {
    puntos = empleosFiltrados
        .where((job) => job.lat != null && job.lng != null)
        .map((job) => LatLng(job.lat!, job.lng!))
        .toList();
  }

  double? _calcularDistancia(Job job) {
    if (ubicacionActual == null || job.lat == null || job.lng == null) {
      return null;
    }
    
    return Geolocator.distanceBetween(
      ubicacionActual!.latitude,
      ubicacionActual!.longitude,
      job.lat!,
      job.lng!,
    ) / 1000; // Convertir a km
  }

  Color _getAccentColor() {
    return switch (currentStyle) {
      MapcnStyle.midnight => const Color(0xFF64B5F6),
      MapcnStyle.silver => const Color(0xFFE91E63),
      MapcnStyle.dracula => const Color(0xFFBD93F9),
      MapcnStyle.emerald => const Color(0xFF00E676),
      MapcnStyle.dark => const Color(0xFF00E676),
      MapcnStyle.sunset => const Color(0xFFFFD54F),
      MapcnStyle.ocean => const Color(0xFF26C6DA),
      MapcnStyle.sepia => const Color(0xFFD84315),
      MapcnStyle.highContrast => const Color(0xFFFFEB3B),
      MapcnStyle.normal => const Color(0xFFF44336),
      MapcnStyle.custom => const Color(0xFF00E676),
    };
  }

  void _mostrarDetalleEmpleo(Job empleo) {
    final distancia = _calcularDistancia(empleo);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildEmpleoCard(empleo, distancia),
    );
  }

  Widget _buildEmpleoCard(Job empleo, double? distancia) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                
                // Imagen o icono
                if (empleo.imagePath.isNotEmpty && ImageService.isBase64(empleo.imagePath))
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                      ImageService.base64ToImage(empleo.imagePath),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    height: 120,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.purple.shade400],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.work, size: 60, color: Colors.white),
                    ),
                  ),
                
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              empleo.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (distancia != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.near_me, size: 16, color: Colors.green.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${distancia.toStringAsFixed(1)} km',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        empleo.company,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Chips de información
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(Icons.location_on, empleo.location, Colors.red),
                          _buildInfoChip(Icons.work, empleo.jobType, Colors.blue),
                          if (empleo.salaryMax > 0)
                            _buildInfoChip(Icons.attach_money, 'S/${empleo.salaryMin.toInt()} - ${empleo.salaryMax.toInt()}', Colors.green),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Botones de acción
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => JobDetailScreen(job: empleo),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.visibility),
                              label: const Text('Ver Detalles'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          if (distancia != null) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  // Aquí podrías abrir Google Maps con direcciones
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Navegación próximamente')),
                                  );
                                },
                                icon: const Icon(Icons.directions),
                                label: const Text('Ir'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _cambiarTema() {
    final temas = MapcnStyle.values;
    final currentIndex = temas.indexOf(currentStyle);
    final nextIndex = (currentIndex + 1) % temas.length;
    setState(() {
      currentStyle = temas[nextIndex];
    });
  }

  void _mostrarFiltros() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtros de Búsqueda',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  // Switch para mostrar solo cercanos
                  SwitchListTile(
                    title: const Text('Mostrar solo empleos cercanos'),
                    subtitle: Text('Radio: ${radioKm.toInt()} km'),
                    value: mostrarSoloCercanos,
                    onChanged: ubicacionActual != null
                        ? (value) {
                            setModalState(() => mostrarSoloCercanos = value);
                            setState(() {
                              mostrarSoloCercanos = value;
                              if (value) {
                                _filtrarPorDistancia();
                              } else {
                                empleosFiltrados = List.from(todosEmpleos);
                                _actualizarPuntos();
                              }
                            });
                          }
                        : null,
                  ),
                  
                  if (mostrarSoloCercanos) ...[
                    const SizedBox(height: 16),
                    Text('Radio de búsqueda: ${radioKm.toInt()} km'),
                    Slider(
                      value: radioKm,
                      min: 1,
                      max: 50,
                      divisions: 49,
                      label: '${radioKm.toInt()} km',
                      onChanged: (value) {
                        setModalState(() => radioKm = value);
                        setState(() {
                          radioKm = value;
                          _filtrarPorDistancia();
                        });
                      },
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  
                  if (ubicacionActual == null)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _pedirPermisoUbicacion();
                      },
                      icon: const Icon(Icons.location_searching),
                      label: const Text('Activar mi ubicación'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Empleos Cerca de Ti'),
        actions: [
          // Botón de filtros
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _mostrarFiltros,
            tooltip: 'Filtros',
          ),
          // Botón para cambiar tema del mapa
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: _cambiarTema,
            tooltip: 'Cambiar tema',
          ),
          // Botón para recargar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarEmpleos,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Mapa con Mapcn
                Mapcn(
                  controller: mapController,
                  initialCenter: ubicacionActual ?? const LatLng(-12.0464, -77.0428),
                  initialZoom: ubicacionActual != null ? 13 : 12,
                  points: puntos,
                  style: currentStyle,
                  accentColor: _getAccentColor(),
                  onPointTap: (point) {
                    final index = puntos.indexWhere((p) => 
                      (p.latitude - point.latitude).abs() < 0.0001 &&
                      (p.longitude - point.longitude).abs() < 0.0001
                    );
                    if (index != -1 && index < empleosFiltrados.length) {
                      _mostrarDetalleEmpleo(empleosFiltrados[index]);
                    }
                  },
                  showTooltip: false,
                ),
                
                // Botón de ubicación actual
                Positioned(
                  right: 16,
                  bottom: 120,
                  child: FloatingActionButton(
                    heroTag: 'location',
                    onPressed: isLoadingLocation ? null : _pedirPermisoUbicacion,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: isLoadingLocation
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Icon(
                            ubicacionActual != null ? Icons.my_location : Icons.location_searching,
                            color: Colors.white,
                          ),
                  ),
                ),
                
                // Leyenda inferior
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 80,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.map, size: 20, color: Theme.of(context).primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tema: ${currentStyle.name}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${empleosFiltrados.length} empleos mostrados',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (ubicacionActual != null && mostrarSoloCercanos)
                          Text(
                            'Radio: ${radioKm.toInt()} km desde tu ubicación',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green.shade700,
                            ),
                          ),
                      ],
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
