import 'package:flutter/material.dart';
import '../../models/usuario.dart';
import '../cliente/home_screen.dart';
import '../cliente/mis_solicitudes_screen.dart';
import '../trabajador/explorar_screen.dart';
import '../trabajador/mis_propuestas_screen.dart';
import '../trabajador/onboarding_trabajador_screen.dart';
import 'perfil_screen.dart';

class MainNavigation extends StatefulWidget {
  final Usuario usuario;
  const MainNavigation({super.key, required this.usuario});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = _needsOnboarding(widget.usuario);
  }

  @override
  void didUpdateWidget(MainNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.usuario != widget.usuario) {
      setState(() => _showOnboarding = _needsOnboarding(widget.usuario));
    }
  }

  bool _needsOnboarding(Usuario u) =>
      u.rol == 'trabajador' && u.oficiosIds.isEmpty;

  List<Widget> get _screens {
    if (widget.usuario.rol == 'trabajador') {
      return [
        ExplorarScreen(usuario: widget.usuario),
        const MisPropuestasScreen(),
        const PerfilScreen(),
      ];
    }
    return [
      HomeScreen(usuario: widget.usuario),
      const MisSolicitudesScreen(),
      const PerfilScreen(),
    ];
  }

  List<BottomNavigationBarItem> get _items {
    if (widget.usuario.rol == 'trabajador') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.search_outlined),
          activeIcon: Icon(Icons.search),
          label: 'Explorar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.handshake_outlined),
          activeIcon: Icon(Icons.handshake),
          label: 'Mis Propuestas',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ];
    }
    return const [
      BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Inicio',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.list_alt_outlined),
        activeIcon: Icon(Icons.list_alt),
        label: 'Mis Solicitudes',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Perfil',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return OnboardingTrabajadorScreen(
        usuario: widget.usuario,
        onCompleted: () => setState(() => _showOnboarding = false),
      );
    }
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: _items,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
