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

class OnboardingTrabajadorScreen extends StatefulWidget {
  final Usuario usuario;
  final VoidCallback onCompleted;

  const OnboardingTrabajadorScreen({
    super.key,
    required this.usuario,
    required this.onCompleted,
  });

  @override
  State<OnboardingTrabajadorScreen> createState() =>
      _OnboardingTrabajadorScreenState();
}

class _OnboardingTrabajadorScreenState
    extends State<OnboardingTrabajadorScreen> {
  final _telefonoController = TextEditingController();
  final _bioController = TextEditingController();

  List<Categoria> _categorias = [];
  final Set<int> _selectedIds = {};
  XFile? _pickedFoto;
  Uint8List? _fotoBytes;
  bool _loadingCats = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadCategorias();
  }

  @override
  void dispose() {
    _telefonoController.dispose();
    _bioController.dispose();
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
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
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

  Future<void> _save() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccioná al menos un oficio')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (_pickedFoto != null) {
        await PerfilService().updateFoto(_pickedFoto!);
      }
      final updatedUser = await PerfilService().updatePerfil(
        telefono: _telefonoController.text.trim().isNotEmpty
            ? _telefonoController.text.trim()
            : null,
        oficiosIds: _selectedIds.toList(),
      );
      if (mounted) {
        context.read<AuthBloc>().add(UserUpdated(updatedUser));
      }
    } catch (e) {
      debugPrint('Error guardando onboarding: $e');
    }
    if (mounted) {
      setState(() => _saving = false);
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.handyman_rounded,
                            size: 36, color: AppTheme.primary),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Completá tu perfil',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textTitle,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Los clientes verán esta información para contactarte',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.textSubtitle),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // ── Foto de perfil ──────────────────────────
                    Text('Foto de perfil (opcional)',
                        style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Center(
                      child: GestureDetector(
                        onTap: _pickFoto,
                        child: CircleAvatar(
                          radius: 48,
                          backgroundColor:
                              AppTheme.primary.withValues(alpha: 0.1),
                          backgroundImage: _fotoBytes != null
                              ? MemoryImage(_fotoBytes!)
                              : null,
                          child: _fotoBytes == null
                              ? const Icon(Icons.add_a_photo_outlined,
                                  size: 32, color: AppTheme.primary)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Teléfono ─────────────────────────────────
                    Text('Teléfono de contacto',
                        style: textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _telefonoController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: '3875 XXX XXX',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Bio ───────────────────────────────────────
                    Text('Sobre vos',
                        style: textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _bioController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'Contá sobre tu experiencia y servicios...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Oficios ───────────────────────────────────
                    Text('¿En qué oficios trabajás?',
                        style: textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Seleccioná todos los que apliquen',
                        style: textTheme.bodySmall
                            ?.copyWith(color: AppTheme.textSubtitle)),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Chips de oficios
            if (_loadingCats)
              const SliverToBoxAdapter(
                child: SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator())),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _categorias.map((cat) {
                      final selected = _selectedIds.contains(cat.id);
                      return FilterChip(
                        label: Text(cat.nombre),
                        avatar: Icon(
                          iconoParaCategoria(cat.icono),
                          size: 18,
                          color: selected ? Colors.white : AppTheme.primary,
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
                          color: selected ? Colors.white : AppTheme.textTitle,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: AppTheme.surfaceCard,
                        selectedColor: AppTheme.primary,
                        side: BorderSide(
                          color:
                              selected ? AppTheme.primary : AppTheme.border,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      );
                    }).toList(),
                  ),
                ),
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                child: _saving
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Comenzar a trabajar',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
