import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../models/categoria.dart';
import '../../services/categoria_service.dart';
import '../../services/solicitud_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/categoria_card.dart';

class CreateSolicitudScreen extends StatefulWidget {
  final Categoria? categoriaPreseleccionada;
  const CreateSolicitudScreen({super.key, this.categoriaPreseleccionada});

  @override
  State<CreateSolicitudScreen> createState() => _CreateSolicitudScreenState();
}

class _CreateSolicitudScreenState extends State<CreateSolicitudScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descripcionController = TextEditingController();

  List<Categoria> _categorias = [];
  Categoria? _categoriaSeleccionada;
  LatLng? _selectedLatLng;
  XFile? _pickedFoto;
  Uint8List? _fotoBytes;
  bool _loadingCats = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _categoriaSeleccionada = widget.categoriaPreseleccionada;
    if (widget.categoriaPreseleccionada == null) {
      _loadCategorias();
    } else {
      _loadingCats = false;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategorias() async {
    try {
      final cats = await CategoriaService().getCategorias();
      if (mounted) {
        setState(() {
          _categorias = cats;
          _loadingCats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCats = false);
    }
  }

  Future<void> _pickFoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedFoto = picked;
        _fotoBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccioná una categoría')));
      return;
    }
    if (_selectedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marcá la ubicación en el mapa')));
      return;
    }

    setState(() => _saving = true);
    try {
      await SolicitudService().createSolicitud(
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        categoriaId: _categoriaSeleccionada!.id,
        latitud: _selectedLatLng!.latitude,
        longitud: _selectedLatLng!.longitude,
        foto: _pickedFoto,
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud publicada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final categoriaFija = widget.categoriaPreseleccionada != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva solicitud')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Categoría
              if (categoriaFija) ...[
                Text('Categoría',
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        iconoParaCategoria(
                            widget.categoriaPreseleccionada!.icono),
                        color: AppTheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.categoriaPreseleccionada!.nombre,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.lock_outline,
                          size: 14, color: AppTheme.primary),
                    ],
                  ),
                ),
              ] else ...[
                Text('Categoría',
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _loadingCats
                    ? const Center(
                        child: SizedBox(
                            height: 56,
                            child: CircularProgressIndicator()))
                    : DropdownButtonFormField<Categoria>(
                        initialValue: _categoriaSeleccionada,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.work_outline),
                          hintText: 'Seleccioná una categoría',
                        ),
                        items: _categorias
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c.nombre),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _categoriaSeleccionada = v),
                        validator: (v) =>
                            v == null ? 'Seleccioná una categoría' : null,
                      ),
              ],
              const SizedBox(height: 20),

              // Título
              Text('¿Qué necesitás?',
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  hintText: 'Ej: Instalar split en living',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Ingresá un título'
                    : null,
              ),
              const SizedBox(height: 16),

              // Descripción
              Text('Descripción (opcional)',
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Describí el trabajo con más detalle...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              // Foto
              Text('Foto del problema (opcional)',
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickFoto,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: _fotoBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.memory(_fotoBytes!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt_outlined,
                                size: 32, color: AppTheme.textSubtitle),
                            SizedBox(height: 6),
                            Text('Tocá para agregar foto',
                                style: TextStyle(
                                    color: AppTheme.textSubtitle,
                                    fontSize: 13)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Ubicación del servicio
              Text('Ubicación del servicio',
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(
                'Tocá el mapa para marcar dónde necesitás el servicio',
                style: textTheme.bodySmall
                    ?.copyWith(color: AppTheme.textSubtitle),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 250,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: const LatLng(-24.7821, -65.4120),
                      initialZoom: 14.0,
                      onTap: (tapPosition, latLng) {
                        setState(() => _selectedLatLng = latLng);
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.chamba',
                      ),
                      if (_selectedLatLng != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLatLng!,
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              if (_selectedLatLng != null) ...[
                const SizedBox(height: 6),
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Ubicación seleccionada ✓',
                      style: TextStyle(color: Colors.green, fontSize: 13),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                child: _saving
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                          padding:
                              const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Publicar solicitud',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
