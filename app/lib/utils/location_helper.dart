import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Representa la ubicación elegida/guardada por el usuario (estilo PedidosYa):
/// una sola dirección guardada en [SharedPreferences], con Salta centro
/// como valor por defecto si todavía no eligió ninguna.
class UbicacionGuardada {
  final double lat;
  final double lon;
  final String nombre;

  const UbicacionGuardada({
    required this.lat,
    required this.lon,
    required this.nombre,
  });
}

/// Helper centralizado para obtener la ubicación del dispositivo y la
/// ubicación guardada por el usuario.
///
/// El GPS real (sobre todo en navegadores) puede tardar varios segundos
/// en responder o directamente no responder nunca si el usuario no
/// acepta el permiso. Para que ninguna pantalla quede esperando para
/// siempre, [getPosition] siempre resuelve: si el GPS no contesta dentro
/// de [timeout] o el permiso es denegado, devuelve Salta (Argentina)
/// como ubicación por defecto.
class LocationHelper {
  static const double saltaLat = -24.7821;
  static const double saltaLon = -65.4120;
  static const String saltaNombre = 'Salta Centro';

  static const _keyLat = 'ubicacion_guardada_lat';
  static const _keyLon = 'ubicacion_guardada_lon';
  static const _keyNombre = 'ubicacion_guardada_nombre';

  static Position get saltaPosition => Position(
        latitude: saltaLat,
        longitude: saltaLon,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

  static Future<Position> getPosition({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return saltaPosition;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(timeout);
    } catch (_) {
      return saltaPosition;
    }
  }

  /// Devuelve la ubicación guardada por el usuario, o Salta Centro si
  /// todavía no guardó ninguna.
  static Future<UbicacionGuardada> getUbicacionGuardada() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_keyLat);
    final lon = prefs.getDouble(_keyLon);
    final nombre = prefs.getString(_keyNombre);
    if (lat != null && lon != null) {
      return UbicacionGuardada(
        lat: lat,
        lon: lon,
        nombre: nombre ?? saltaNombre,
      );
    }
    return const UbicacionGuardada(
      lat: saltaLat,
      lon: saltaLon,
      nombre: saltaNombre,
    );
  }

  static Future<void> guardarUbicacion({
    required double lat,
    required double lon,
    required String nombre,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLat, lat);
    await prefs.setDouble(_keyLon, lon);
    await prefs.setString(_keyNombre, nombre);
  }
}
