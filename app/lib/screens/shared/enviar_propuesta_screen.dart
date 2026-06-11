import 'package:flutter/material.dart';
import '../../services/propuesta_service.dart';
import '../../theme/app_theme.dart';

class EnviarPropuestaScreen extends StatefulWidget {
  final int solicitudId;
  const EnviarPropuestaScreen({super.key, required this.solicitudId});

  @override
  State<EnviarPropuestaScreen> createState() => _EnviarPropuestaScreenState();
}

class _EnviarPropuestaScreenState extends State<EnviarPropuestaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _precioController = TextEditingController();
  final _mensajeController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _precioController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _sending = true);
    try {
      await PropuestaService().enviarPropuesta(
        solicitudId: widget.solicitudId,
        precio: double.parse(_precioController.text.trim()),
        mensaje: _mensajeController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Propuesta enviada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo enviar la propuesta')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Enviar propuesta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Precio estimado',
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _precioController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: 'Ej: 15000',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                validator: (v) {
                  final value = double.tryParse((v ?? '').trim());
                  if (value == null || value <= 0) {
                    return 'Ingresá un precio válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text('Mensaje (opcional)',
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _mensajeController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describí tu experiencia con este tipo de trabajo...',
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
                        child: const Text('Enviar propuesta',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
