import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../models/propuesta.dart';
import '../../models/solicitud.dart';
import '../../services/propuesta_service.dart';
import '../../services/solicitud_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/time_ago.dart';
import '../../widgets/categoria_card.dart';
import 'dejar_resena_screen.dart';
import 'enviar_propuesta_screen.dart';

class DetalleSolicitudScreen extends StatefulWidget {
  final Solicitud solicitud;
  const DetalleSolicitudScreen({super.key, required this.solicitud});

  @override
  State<DetalleSolicitudScreen> createState() =>
      _DetalleSolicitudScreenState();
}

class _DetalleSolicitudScreenState extends State<DetalleSolicitudScreen> {
  late Solicitud _solicitud;
  List<Propuesta> _propuestas = [];
  bool _loadingPropuestas = false;
  bool _processing = false;
  bool _yaEnviadaPropuesta = false;

  @override
  void initState() {
    super.initState();
    _solicitud = widget.solicitud;
    _maybeLoadPropuestas();
    _checkPropuestaEnviada();
  }

  Future<void> _checkPropuestaEnviada() async {
    if (_rol != 'trabajador') return;
    try {
      final propuestas = await PropuestaService().getMisPropuestas();
      final yaEnviada = propuestas.any((p) => p.solicitudId == _solicitud.id);
      if (mounted) setState(() => _yaEnviadaPropuesta = yaEnviada);
    } catch (_) {}
  }

  int? get _usuarioId {
    final state = context.read<AuthBloc>().state;
    return state is Authenticated ? state.usuario.id : null;
  }

  String get _rol {
    final state = context.read<AuthBloc>().state;
    return state is Authenticated ? state.usuario.rol : '';
  }

  bool get _esClienteDueno => _usuarioId == _solicitud.clienteId;

  bool get _esTrabajadorAceptado =>
      _usuarioId != null && _usuarioId == _solicitud.trabajadorAceptadoId;

  Future<void> _maybeLoadPropuestas() async {
    if (!_esClienteDueno || _solicitud.estado != 'abierta') return;
    setState(() => _loadingPropuestas = true);
    try {
      final list =
          await PropuestaService().getPropuestasDeSolicitud(_solicitud.id);
      if (mounted) {
        setState(() {
          _propuestas = list;
          _loadingPropuestas = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingPropuestas = false);
    }
  }

  Future<void> _aceptarPropuesta(Propuesta propuesta) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Aceptar propuesta'),
        content: Text(
          '¿Aceptás la propuesta de ${propuesta.trabajadorNombre} '
          'por \$${propuesta.precioEstimado.toStringAsFixed(0)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    setState(() => _processing = true);
    try {
      await PropuestaService().aceptarPropuesta(propuesta.id);
      final actualizada = await SolicitudService().getSolicitud(_solicitud.id);
      if (mounted) {
        setState(() {
          _solicitud = actualizada;
          _processing = false;
        });
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Propuesta aceptada'),
            content: Text(
              actualizada.trabajadorAceptadoTelefono != null
                  ? 'Podés contactar a ${actualizada.trabajadorAceptadoNombre ?? 'el trabajador'} '
                      'al teléfono ${actualizada.trabajadorAceptadoTelefono}.'
                  : 'El trabajador fue notificado.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo aceptar la propuesta')),
        );
      }
    }
  }

  Future<void> _enviarPropuesta() async {
    final enviado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EnviarPropuestaScreen(solicitudId: _solicitud.id),
      ),
    );
    if (enviado == true && mounted) {
      setState(() => _yaEnviadaPropuesta = true);
    }
  }

  Future<void> _cerrarSolicitud() async {
    setState(() => _processing = true);
    try {
      await SolicitudService().cerrarSolicitud(_solicitud.id);
      final actualizada = await SolicitudService().getSolicitud(_solicitud.id);
      if (mounted) {
        setState(() {
          _solicitud = actualizada;
          _processing = false;
        });
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DejarResenaScreen(solicitud: actualizada),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cerrar la solicitud')),
        );
      }
    }
  }

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'abierta':
        return AppTheme.successColor;
      case 'en_progreso':
        return AppTheme.secondary;
      case 'cerrada':
        return AppTheme.textSubtitle;
      default:
        return AppTheme.errorColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final authState = context.read<AuthBloc>().state;
    final miNombre = authState is Authenticated
        ? authState.usuario.nombreCompleto
        : '';

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de la solicitud')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_solicitud.foto != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  _solicitud.foto!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            if (_solicitud.foto != null) const SizedBox(height: 20),

            Row(
              children: [
                if (_solicitud.categoriaNombre != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          iconoParaCategoria(_solicitud.categoriaNombre ?? ''),
                          size: 14,
                          color: AppTheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _solicitud.categoriaNombre!,
                          style: textTheme.labelSmall?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _colorEstado(_solicitud.estado).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _solicitud.estado.replaceAll('_', ' ').toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: _colorEstado(_solicitud.estado),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              _solicitud.titulo,
              style: textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.access_time,
                    size: 14, color: AppTheme.textSubtitle),
                const SizedBox(width: 4),
                Text(
                  timeAgo(_solicitud.createdAt),
                  style: textTheme.bodySmall
                      ?.copyWith(color: AppTheme.textSubtitle),
                ),
                if (_solicitud.latitud != null &&
                    _solicitud.longitud != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: AppTheme.textSubtitle),
                  const SizedBox(width: 4),
                  Text(
                    '${_solicitud.latitud!.toStringAsFixed(3)}°, '
                    '${_solicitud.longitud!.toStringAsFixed(3)}°',
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppTheme.textSubtitle),
                  ),
                ],
              ],
            ),

            if (_solicitud.descripcion.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Descripción',
                style: textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                _solicitud.descripcion,
                style: textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.textSubtitle),
              ),
            ],

            // Mapa de ubicación
            if (_solicitud.latitud != null && _solicitud.longitud != null) ...[
              const SizedBox(height: 20),
              _buildMapa(),
            ],

            // Datos de contacto cuando hay trabajo en progreso o cerrado
            if (_solicitud.estado != 'abierta' &&
                _solicitud.trabajadorAceptadoId != null) ...[
              const SizedBox(height: 20),
              _ContactoCard(
                titulo: _esClienteDueno ? 'Trabajador asignado' : 'Cliente',
                nombre: _esClienteDueno
                    ? (_solicitud.trabajadorAceptadoNombre ?? '')
                    : (_solicitud.clienteNombre ?? ''),
                telefono: _esClienteDueno
                    ? _solicitud.trabajadorAceptadoTelefono
                    : _solicitud.clienteTelefono,
                mensajeWa: _esClienteDueno
                    ? 'Hola, te contacto por la solicitud "${_solicitud.titulo}" en Chamba.'
                    : 'Hola, soy $miNombre de Chamba. '
                        'Aceptaste mi propuesta para: ${_solicitud.titulo}. '
                        '¿Cuándo coordinamos?',
              ),
            ],

            // Lista de propuestas para el cliente dueño
            if (_esClienteDueno && _solicitud.estado == 'abierta') ...[
              const SizedBox(height: 24),
              Text(
                'Propuestas recibidas',
                style:
                    textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (_loadingPropuestas)
                const Center(child: CircularProgressIndicator())
              else if (_propuestas.isEmpty)
                Text(
                  'Todavía no recibiste propuestas para este trabajo.',
                  style: textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.textSubtitle),
                )
              else
                ..._propuestas.map((p) => _PropuestaTile(
                      propuesta: p,
                      processing: _processing,
                      onAceptar: () => _aceptarPropuesta(p),
                    )),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildMapa() {
    final lat = _solicitud.latitud!;
    final lon = _solicitud.longitud!;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 180,
        child: AbsorbPointer(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(lat, lon),
              initialZoom: 14.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.chamba',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(lat, lon),
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
    );
  }

  Widget? _buildBottomBar() {
    Widget? child;

    if (_rol == 'trabajador' && _solicitud.estado == 'abierta') {
      child = ElevatedButton.icon(
        onPressed: (_processing || _yaEnviadaPropuesta)
            ? null
            : _enviarPropuesta,
        icon: Icon(_yaEnviadaPropuesta
            ? Icons.check_circle_outline
            : Icons.send_outlined),
        label: Text(_yaEnviadaPropuesta
            ? 'Ya enviaste una propuesta'
            : 'Enviar propuesta'),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _yaEnviadaPropuesta ? AppTheme.textSubtitle : AppTheme.accent,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      );
    } else if (_solicitud.estado == 'en_progreso' &&
        (_esClienteDueno || _esTrabajadorAceptado)) {
      child = ElevatedButton.icon(
        onPressed: _processing ? null : _cerrarSolicitud,
        icon: const Icon(Icons.check_circle_outline),
        label: const Text('Marcar como terminado'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accent,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      );
    }

    if (child == null) return null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: _processing
            ? const Center(child: CircularProgressIndicator())
            : child,
      ),
    );
  }
}

class _ContactoCard extends StatelessWidget {
  final String titulo;
  final String nombre;
  final String? telefono;
  final String mensajeWa;

  const _ContactoCard({
    required this.titulo,
    required this.nombre,
    required this.telefono,
    required this.mensajeWa,
  });

  String? _waUrl() {
    if (telefono == null || telefono!.isEmpty) return null;
    var num = telefono!.replaceAll(RegExp(r'[^\d]'), '');
    if (num.isEmpty) return null;
    if (!num.startsWith('549')) {
      if (num.startsWith('54')) {
        num = '549${num.substring(2)}';
      } else {
        if (num.startsWith('0')) num = num.substring(1);
        num = '549$num';
      }
    }
    return 'https://wa.me/$num?text=${Uri.encodeComponent(mensajeWa)}';
  }

  Future<void> _launch(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: textTheme.labelSmall
                  ?.copyWith(color: AppTheme.textSubtitle)),
          const SizedBox(height: 4),
          Text(nombre.isNotEmpty ? nombre : '—',
              style: textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          if (telefono != null && telefono!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.phone_outlined,
                    size: 13, color: AppTheme.textSubtitle),
                const SizedBox(width: 4),
                Text(telefono!,
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppTheme.textSubtitle)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _launch('tel:$telefono'),
                    icon: const Icon(Icons.phone, size: 16),
                    label: const Text('Llamar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.successColor,
                      side: const BorderSide(color: AppTheme.successColor),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final url = _waUrl();
                      if (url != null) _launch(url);
                    },
                    icon: const Icon(Icons.chat, size: 16),
                    label: const Text('WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PropuestaTile extends StatelessWidget {
  final Propuesta propuesta;
  final bool processing;
  final VoidCallback onAceptar;

  const _PropuestaTile({
    required this.propuesta,
    required this.processing,
    required this.onAceptar,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  propuesta.trabajadorNombre,
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '\$${propuesta.precioEstimado.toStringAsFixed(0)}',
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          if (propuesta.mensaje.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              propuesta.mensaje,
              style:
                  textTheme.bodySmall?.copyWith(color: AppTheme.textSubtitle),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: processing ? null : onAceptar,
              child: const Text('Aceptar propuesta'),
            ),
          ),
        ],
      ),
    );
  }
}
