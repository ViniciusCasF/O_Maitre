// lib/Paginas/PaginaPedidos.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Modelos/Itens.dart';
import '../Modelos/order_manager.dart';
import '../Modelos/Pedidos.dart';
import '../firebase_options.dart';
import 'Pagina_Cardapio.dart';
import 'PaginaLeitorMesa.dart';

class PaginaPedidos extends StatefulWidget {
  const PaginaPedidos({Key? key}) : super(key: key);

  @override
  State<PaginaPedidos> createState() => _PaginaPedidosState();
}

class _PaginaPedidosState extends State<PaginaPedidos> {
  final OrderManager order = OrderManager();
  final FirebaseFirestore db = FirebaseFirestore.instance;
  bool enviando = false;

  @override
  void initState() {
    super.initState();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  Future<void> _enviarPedidos() async {
    setState(() => enviando = true);

    try {
      final pedidosRef = db.collection('pedidos');
      const numeroMesa = 5;

      for (var item in order.items) {
        final tipo = item.name.toLowerCase().contains('cerveja') ||
            item.name.toLowerCase().contains('refrigerante') ||
            item.name.toLowerCase().contains('bebida')
            ? 1
            : 0;

        for (int i = 0; i < item.qty; i++) {
          final pedido = Pedido(
            nome: item.name,
            descricao: item.description ?? '',
            imagem: item.image,
            data: DateTime.now(),
            mesa: numeroMesa,
            tipo: tipo,
          );
          await pedidosRef.add(pedido.toMap());
        }
      }

      order.clear();

      if (mounted) {
        await _mostrarPopupSucesso(context);
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao enviar pedidos: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  Future<void> _mostrarPopupSucesso(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('✅ Pedido enviado!'),
        content: const Text('Seu pedido foi enviado com sucesso!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = order.items;

    return Scaffold(
      appBar: AppBar(
        title: Text('Meu Pedido (${items.length})'),
        centerTitle: true,
        backgroundColor: const Color(0xFF448AFF),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: items.isEmpty
                    ? const Center(child: Text('Seu pedido está vazio.'))
                    : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) {
                    final it = items[i];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: it.image.isNotEmpty
                            ? Image.network(
                          it.image,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                          const Icon(Icons.fastfood,
                              size: 40,
                              color: Colors.grey),
                        )
                            : const Icon(Icons.fastfood,
                            size: 40, color: Colors.grey),
                      ),
                      title: Text(
                        it.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Qtd: ${it.qty}'),
                          if (it.description.isNotEmpty)
                            Text(it.description),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () =>
                            setState(() => order.removeAt(i)),
                      ),
                    );
                  },
                ),
              ),
            ),

            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      },
                      child: const Text('Adicionar mais produtos'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: items.isEmpty || enviando
                          ? null
                          : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PaginaLeitorMesa(order: order),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF448AFF),
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: enviando
                          ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                          : const Text('Terminar pedido'),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
