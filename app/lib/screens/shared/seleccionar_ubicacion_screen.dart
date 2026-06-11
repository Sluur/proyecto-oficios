import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/location_helper.dart';

class SeleccionarUbicacionScreen extends StatefulWidget {
  const SeleccionarUbicacionScreen({super.key});

  @override
  State<SeleccionarUbicacionScreen> createState() =>
      _SeleccionarUbicacionScreenState();
}

class _SeleccionarUbicacionScreenState
    extends State<SeleccionarUbicacionScreen> {
  final _direccionController = TextEditingController();
  double _lat = LocationHelper.saltaLat;
  double _lon = LocationHelper.saltaLon;
  bool _loading = true;
  bool _gettingGps = false;

  @override
  void initState() {
    super.initState();
    _cargarActual();
  }

  @override
  void dispose() {
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _cargarActual() async {
    final actual = await LocationHelper.getUbicacionGuardada();
    if (mounted) {
      setState(() {
        _direccionController.text = actual.nombre;
        _lat = actual.lat;
        _lon = actual.lon;
        _loading = false;
      });
    }
  }

  Future<void> _usarUbicacionActual() async {
    setState(() => _gettingGps = true);
    final pos = await LocationHelper.getPosition();
    if (mounted) {
      setState(() {
        _lat = pos.latitude;
        _lon = pos.longitude;
        _gettingGps = false;
        if (_direccionController.text.trim().isEmpty ||
            _direccionController.text.trim() == LocationHelper.saltaNombre) {
          _direccionController.text = 'Mi ubicación actual';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ubicación actual obtenida')),
      );
    }
  }

  Future<void> _guardar() async {
    final nombre = _direccionController.text.trim();
    await LocationHelper.guardarUbicacion(
      lat: _lat,
      lon: _lon,
      nombre: nombre.isNotEmpty ? nombre : LocationHelper.saltaNombre,
    );
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tu ubicación')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usamos tu ubicación para mostrarte solicitudes y '
                    'trabajadores cercanos.',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: AppTheme.textSubtitle),
                  ),
                  const SizedBox(height: 24),
                  Text('Tu dirección',
                      style: textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _direccionController,
                    decoration: const InputDecoration(
                      hintText: 'Ej: Av. San Martín 450, Salta',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _gettingGps ? null : _usarUbicacionActual,
                      icon: _gettingGps
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: const Text('Usar mi ubicación actual'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Guardar ubicación',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
