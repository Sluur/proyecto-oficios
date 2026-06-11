import 'package:flutter/material.dart';
import '../../models/categoria.dart';
import '../../services/categoria_service.dart';
import '../../widgets/categoria_card.dart';
import 'trabajadores_categoria_screen.dart';

class TodasCategoriasScreen extends StatefulWidget {
  const TodasCategoriasScreen({super.key});

  @override
  State<TodasCategoriasScreen> createState() => _TodasCategoriasScreenState();
}

class _TodasCategoriasScreenState extends State<TodasCategoriasScreen> {
  List<Categoria> _categorias = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cats = await CategoriaService().getCategorias();
      if (mounted) {
        setState(() {
          _categorias = cats;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'No se pudieron cargar las categorías';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todos los servicios')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.88,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _categorias.length,
      itemBuilder: (context, index) => CategoriaCard(
        categoria: _categorias[index],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                TrabajadoresCategoriaScreen(categoria: _categorias[index]),
          ),
        ),
      ),
    );
  }
}
