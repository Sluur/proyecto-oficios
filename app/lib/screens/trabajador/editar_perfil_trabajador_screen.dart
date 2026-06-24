import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../models/categoria.dart';
import '../../models/usuario.dart';
import '../../services/categoria_service.dart';
import '../../services/perfil_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/categoria_card.dart';

class EditarPerfilTrabajadorScreen extends StatefulWidget {
  final Usuario usuario;
  const EditarPerfilTrabajadorScreen({super.key, required this.usuario});

  @override
  State<EditarPerfilTrabajadorScreen> createState() =>
      _EditarPerfilTrabajadorScreenState();
}

class _EditarPerfilTrabajadorScreenState
    extends State<EditarPerfilTrabajadorScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _bioController;
  late final TextEditingController _telefonoController;

  List<Categoria> _categorias = [];
  late Set<int> _selectedIds;
  XFile? _pickedFoto;
  Uint8List? _fotoBytes;
  bool _loadingCats = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.usuario.firstName);
    _lastNameController = TextEditingController(text: widget.usuario.lastName);
    _bioController = TextEditingController(text: widget.usuario.bio ?? '');
    _telefonoController =
        TextEditingController(text: widget.usuario.telefono ?? '');
    _selectedIds = Set<int>.from(widget.usuario.oficiosIds);
    _loadCategorias();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  Future<void> _loadCategorias() async {
    try {
      final cats = await CategoriaService().getCategorias();
      if (mounted) setState(() { _categorias = cats; _loadingCats = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingCats = false);
    }
  }

  Future<void> _pickFoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      final bytes = await picked.readAsBytes();
      setState(() { _pickedFoto = picked; _fotoBytes = bytes; });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      if (_pickedFoto != null) {
        await PerfilService().updateFoto(_pickedFoto!);
      }
      final updated = await PerfilService().updatePerfil(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        bio: _bioController.text.trim(),
        telefono: _telefonoController.text.trim(),
        oficiosIds: _selectedIds.toList(),
      );
      if (mounted) {
        context.read<AuthBloc>().add(UserUpdated(updated));
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final fotoUrl = widget.usuario.foto;
    ImageProvider? backgroundImage;
    if (_fotoBytes != null) {
      backgroundImage = MemoryImage(_fotoBytes!);
    } else if (fotoUrl != null && fotoUrl.isNotEmpty) {
      backgroundImage = NetworkImage(fotoUrl);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil'),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Guardar',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickFoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor:
                          AppTheme.primary.withValues(alpha: 0.1),
                      backgroundImage: backgroundImage,
                      child: backgroundImage == null
                          ? const Icon(Icons.person_outline,
                              size: 40, color: AppTheme.primary)
                          : null,
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_outlined,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            _label(textTheme, 'Nombre'),
            const SizedBox(height: 8),
            TextField(
              controller: _firstNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Tu nombre',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            _label(textTheme, 'Apellido'),
            const SizedBox(height: 8),
            TextField(
              controller: _lastNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'Tu apellido',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            _label(textTheme, 'Teléfono'),
            const SizedBox(height: 8),
            TextField(
              controller: _telefonoController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: '3875 XXX XXX',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 16),

            _label(textTheme, 'Descripción / Bio'),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Contá sobre tu experiencia y servicios...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),

            _label(textTheme, 'Oficios'),
            const SizedBox(height: 4),
            Text(
              'Seleccioná todos los que apliquen',
              style: textTheme.bodySmall
                  ?.copyWith(color: AppTheme.textSubtitle),
            ),
            const SizedBox(height: 12),
            _loadingCats
                ? const Center(
                    child: SizedBox(
                        height: 80,
                        child: CircularProgressIndicator()))
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _categorias.map((cat) {
                      final selected = _selectedIds.contains(cat.id);
                      return FilterChip(
                        label: Text(cat.nombre),
                        avatar: Icon(
                          iconoParaCategoria(cat.icono),
                          size: 18,
                          color: selected
                              ? Colors.white
                              : AppTheme.primary,
                        ),
                        selected: selected,
                        onSelected: (_) => setState(() {
                          if (selected) {
                            _selectedIds.remove(cat.id);
                          } else {
                            _selectedIds.add(cat.id);
                          }
                        }),
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppTheme.textTitle,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: AppTheme.surfaceCard,
                        selectedColor: AppTheme.primary,
                        side: BorderSide(
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.border,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Guardar cambios',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _label(TextTheme t, String text) => Text(
        text,
        style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      );
}
