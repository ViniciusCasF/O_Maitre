// lib/Paginas/PaginaPedidos.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Modelos/Itens.dart';
import '../Modelos/order_manager.dart';
import '../firebase_options.dart';
import '../Modelos/MesaHelper.dart';
import '../Modelos/ContaManager.dart';

class PaginaPedidos extends StatefulWidget {
  const PaginaPedidos({Key? key}) : super(key: key);

  @override
  State<PaginaPedidos> createState() => _PaginaPedidosState();
}

class _PaginaPedidosState extends State<PaginaPedidos> {
  final OrderManager order = OrderManager();
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final contaManager = ContaManager();
  bool enviando = false;

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // -------------------------------------------------------
  // CALCULAR CUSTO DOS INSUMOS DE UM PRODUTO
  // -------------------------------------------------------
  Future<double> calcularCustoInsumos(String nomeProduto) async {
    final query = await db
        .collection('produtos')
        .where('nome', isEqualTo: nomeProduto)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return 0.0;

    final produto = query.docs.first.data();
    final List<dynamic> insumos = produto['insumos'] ?? [];

    double custoTotal = 0.0;

    for (var item in insumos) {
      final nomeInsumo = item['nome'];
      final double qtdNecessaria =
          double.tryParse(item['quantidade'].toString()) ?? 0.0;

      final insumoQuery = await db
          .collection('insumos')
          .where('nome', isEqualTo: nomeInsumo)
          .limit(1)
          .get();

      if (insumoQuery.docs.isEmpty) continue;

      final insumo = insumoQuery.docs.first.data();
      final double precoUnitario = (insumo['preco'] ?? 0).toDouble();

      custoTotal += precoUnitario * qtdNecessaria;
    }

    return custoTotal;
  }

  // -------------------------------------------------------
  // REDUZIR INSUMOS NO ESTOQUE
  // -------------------------------------------------------
  Future<void> reduzirInsumos(String nomeProduto, int quantidadePedidos) async {
    final query = await db
        .collection('produtos')
        .where('nome', isEqualTo: nomeProduto)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return;

    final produto = query.docs.first.data();
    final List<dynamic> insumos = produto['insumos'] ?? [];

    for (var item in insumos) {
      final nomeInsumo = item['nome'];
      final String qtdStr = item['quantidade'];
      final double qtdNecessaria = double.tryParse(qtdStr) ?? 0.0;

      final double totalGasto = qtdNecessaria * quantidadePedidos;

      final insumoQuery = await db
          .collection('insumos')
          .where('nome', isEqualTo: nomeInsumo)
          .limit(1)
          .get();

      if (insumoQuery.docs.isEmpty) continue;

      final insumoRef = insumoQuery.docs.first.reference;

      await insumoRef.update({
        'quantidade': FieldValue.increment(-totalGasto),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // -------------------------------------------------------
  // ENVIAR PEDIDOS
  // -------------------------------------------------------
  Future<void> _enviarPedidos() async {
    setState(() => enviando = true);

    try {
      final numeroMesa = MesaHelper.detectarMesa();
      final pedidosRef = db.collection('pedidos');

      await contaManager.abrirOuCriarConta(numeroMesa);

      for (var item in order.items) {
        for (int i = 0; i < item.qty; i++) {
          final doc = await pedidosRef.add({
            'nomeProduto': item.name,
            'mesa': numeroMesa,
            'descricao': item.description ?? '',
            'preco': item.price,
            'status': 1,
            'startTime': FieldValue.serverTimestamp(),
          });

          // custo dos insumos para 1 unidade do produto
          final custoInsumos = await calcularCustoInsumos(item.name);

          await contaManager.adicionarPedido(
            numeroMesa,
            doc.id,
            item.price,
            custoInsumos: custoInsumos,
          );
        }

        // redução do estoque total
        await reduzirInsumos(item.name, item.qty);
      }

      order.clear();
      await _mostrarPopupSucesso(context);

      if (mounted) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar pedidos: $e')),
      );
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  // -------------------------------------------------------
  // POPUP
  // -------------------------------------------------------
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
                            leading: const Icon(Icons.fastfood, size: 40),
                            title: Text(
                              it.name,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text('Qtd: ${it.qty}'),
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
                      onPressed:
                          items.isEmpty || enviando ? null : _enviarPedidos,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF448AFF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
          ],
        ),
      ),
    );
  }
}
