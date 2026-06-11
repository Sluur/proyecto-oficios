import 'package:flutter/material.dart';
import '../../models/solicitud.dart';
import '../../services/resena_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/star_rating.dart';

class DejarResenaScreen extends StatefulWidget {
  final Solicitud solicitud;
  const DejarResenaScreen({super.key, required this.solicitud});

  @override
  State<DejarResenaScreen> createState() => _DejarResenaScreenState();
}

class _DejarResenaScreenState extends State<DejarResenaScreen> {
  final _comentarioController = TextEditingController();
  int _puntaje = 5;
  bool _sending = false;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() => _sending = true);
    try {
      await ResenaService().crearResena(
        solicitudId: widget.solicitud.id,
        puntaje: _puntaje,
        comentario: _comentarioController.text.trim(),
      );
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        messenger.showSnackBar(
          const SnackBar(content: Text('¡Gracias por tu reseña!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo enviar la reseña')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Dejar reseña')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.solicitud.titulo,
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            Text('¿Cómo calificarías el trabajo?',
                style: textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Center(
              child: StarRating(
                rating: _puntaje.toDouble(),
                size: 40,
                onChanged: (v) => setState(() => _puntaje = v),
              ),
            ),
            const SizedBox(height: 28),
            Text('Comentario (opcional)',
                style: textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _comentarioController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Contá tu experiencia...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: _sending
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _enviar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Enviar reseña',
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
