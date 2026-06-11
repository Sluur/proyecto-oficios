import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/categoria.dart';
import '../../services/categoria_service.dart';
import '../../services/solicitud_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/location_helper.dart';
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
  Position? _position;
  File? _fotoFile;
  bool _loadingCats = true;
  bool _loadingGps = true;
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
    _loadGps();
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

  Future<void> _loadGps() async {
    // Usamos la ubicación guardada como punto de partida (instantánea) y,
    // si el GPS responde, la reemplazamos por la posición real del usuario.
    final ubicacion = await LocationHelper.getUbicacionGuardada();
    if (mounted) {
      setState(() {
        _position = Position(
          latitude: ubicacion.lat,
          longitude: ubicacion.lon,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        _loadingGps = false;
      });
    }
    LocationHelper.getPosition().then((pos) {
      if (mounted) setState(() => _position = pos);
    });
  }

  Future<void> _pickFoto() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _fotoFile = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleccioná una categoría')));
      return;
    }
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Esperá a que se obtenga tu ubicación')));
      return;
    }

    setState(() => _saving = true);
    try {
      await SolicitudService().createSolicitud(
        titulo: _tituloController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        categoriaId: _categoriaSeleccionada!.id,
        latitud: _position!.latitude,
        longitud: _position!.longitude,
        fotoPath: _fotoFile?.path,
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
                  hintText:
                      'Describí el trabajo con más detalle...',
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
                  child: _fotoFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.file(_fotoFile!, fit: BoxFit.cover),
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

              // Ubicación
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: AppTheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _loadingGps
                            ? 'Obteniendo ubicación...'
                            : _position != null
                                ? '${_position!.latitude.toStringAsFixed(4)}°, '
                                    '${_position!.longitude.toStringAsFixed(4)}°'
                                : 'Ubicación no disponible',
                        style: textTheme.bodySmall?.copyWith(
                          color: _position != null
                              ? AppTheme.textTitle
                              : AppTheme.textSubtitle,
                        ),
                      ),
                    ),
                    if (_loadingGps)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),
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
