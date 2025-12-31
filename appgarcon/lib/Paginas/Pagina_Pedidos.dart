// lib/Paginas/PaginaPedidos.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../Modelos/order_manager.dart';
import '../Modelos/ContaManager.dart';
import '../firebase_options.dart';
import 'PaginaLeitorMesa.dart';

class PaginaPedidos extends StatefulWidget {
  const PaginaPedidos({Key? key}) : super(key: key);

  @override
  State<PaginaPedidos> createState() => _PaginaPedidosState();
}

class _PaginaPedidosState extends State<PaginaPedidos> {
  final OrderManager order = OrderManager();
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final ContaManager contaManager = ContaManager();

  bool enviando = false;

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // =================================================
  // 🔍 OBTÉM O TIPO DO PRODUTO (garcom / cozinha)
  // =================================================
  Future<String> obterTipoProduto(String nomeProduto) async {
    final query = await db
        .collection('produtos')
        .where('nome', isEqualTo: nomeProduto)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      // padrão seguro: manda pra cozinha
      return 'cozinha';
    }

    return query.docs.first.data()['tipo'] ?? 'cozinha';
  }

  // =================================================
  // 💰 CUSTO DOS INSUMOS
  // =================================================
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
      final double qtd =
          double.tryParse(item['quantidade'].toString()) ?? 0.0;

      final insumoQuery = await db
          .collection('insumos')
          .where('nome', isEqualTo: nomeInsumo)
          .limit(1)
          .get();

      if (insumoQuery.docs.isEmpty) continue;

      final insumo = insumoQuery.docs.first.data();
      final double precoUnitario =
      (insumo['preco'] ?? 0).toDouble();

      custoTotal += precoUnitario * qtd;
    }

    return custoTotal;
  }

  // =================================================
  // 📉 REDUZIR INSUMOS NO ESTOQUE
  // =================================================
  Future<void> reduzirInsumos(String nomeProduto, int quantidade) async {
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
      final double qtd =
          double.tryParse(item['quantidade'].toString()) ?? 0.0;

      final double totalGasto = qtd * quantidade;

      final insumoQuery = await db
          .collection('insumos')
          .where('nome', isEqualTo: nomeInsumo)
          .limit(1)
          .get();

      if (insumoQuery.docs.isEmpty) continue;

      await insumoQuery.docs.first.reference.update({
        'quantidade': FieldValue.increment(-totalGasto),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // =================================================
  // 🚀 ENVIO FINAL (APÓS QR)
  // =================================================
  Future<void> enviarPedidosComMesa(int numeroMesa) async {
    setState(() => enviando = true);

    try {
      final pedidosRef = db.collection('pedidos');

      await contaManager.abrirOuCriarConta(numeroMesa);

      for (var item in order.items) {
        final tipoProduto = await obterTipoProduto(item.name);
        final int statusInicial = tipoProduto == 'garcom' ? 1 : 2;

        // Buscar preço e produtoId
        final prodQuery = await db
            .collection("produtos")
            .where("nome", isEqualTo: item.name)
            .limit(1)
            .get();

        if (prodQuery.docs.isEmpty) {
          throw Exception("Produto '${item.name}' não encontrado na coleção produtos.");
        }

        final prodDoc = prodQuery.docs.first;
        final String produtoId = prodDoc.id;
        final double preco = (prodDoc["preco"] ?? 0).toDouble();

        // Calcular custo de insumos (correto!)
        final double custoInsumos = await calcularCustoInsumos(item.name);

        // Criar os pedidos (um por quantidade)
        for (int i = 0; i < item.qty; i++) {
          final doc = await pedidosRef.add({
            'produtoId': produtoId,
            'nomeProduto': item.name,
            'descricao': item.description ?? '',
            'mesa': numeroMesa,
            'preco': preco,            // ✔ AGORA EXISTE
            'custoInsumos': custoInsumos,
            'status': statusInicial,
            'tipo': tipoProduto,
            'startTime': FieldValue.serverTimestamp(),
          });

          await contaManager.adicionarPedido(
            numeroMesa,
            doc.id,
            preco,                   // ✔ preço correto para a conta
            custoInsumos: custoInsumos,
          );
        }

        await reduzirInsumos(item.name, item.qty);
      }

      order.clear();

      if (mounted) {
        await _mostrarPopupSucesso(context);
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


  // =================================================
  // 🎉 POPUP
  // =================================================
  Future<void> _mostrarPopupSucesso(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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

  // =================================================
  // 🖼️ UI (IGUAL À ORIGINAL)
  // =================================================
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
                    ? const Center(
                  child: Text('Seu pedido está vazio.'),
                )
                    : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                  const Divider(),
                  itemBuilder: (_, i) {
                    final it = items[i];
                    return ListTile(
                      title: Text(it.name),
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
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context)
                            .popUntil((r) => r.isFirst);
                      },
                      child:
                      const Text('Adicionar mais produtos'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: items.isEmpty || enviando
                          ? null
                          : () async {
                        final numeroMesa =
                        await Navigator.push<int>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PaginaLeitorMesa(order: order),
                          ),
                        );

                        if (numeroMesa != null) {
                          await enviarPedidosComMesa(
                              numeroMesa);
                        }
                      },
                      child: enviando
                          ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
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
