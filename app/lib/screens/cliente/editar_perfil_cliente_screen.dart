import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../models/usuario.dart';
import '../../services/perfil_service.dart';
import '../../theme/app_theme.dart';

class EditarPerfilClienteScreen extends StatefulWidget {
  final Usuario usuario;
  const EditarPerfilClienteScreen({super.key, required this.usuario});

  @override
  State<EditarPerfilClienteScreen> createState() =>
      _EditarPerfilClienteScreenState();
}

class _EditarPerfilClienteScreenState
    extends State<EditarPerfilClienteScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _telefonoController;

  XFile? _pickedFoto;
  Uint8List? _fotoBytes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.usuario.firstName);
    _lastNameController = TextEditingController(text: widget.usuario.lastName);
    _telefonoController =
        TextEditingController(text: widget.usuario.telefono ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _telefonoController.dispose();
    super.dispose();
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
        telefono: _telefonoController.text.trim(),
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
                          border:
                              Border.all(color: Colors.white, width: 2),
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
