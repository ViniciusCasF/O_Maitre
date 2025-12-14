// lib/Paginas/Pagina_Conta.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Modelos/Itens.dart';
import '../Modelos/MesaHelper.dart';
import 'Pagina_Pagamento.dart';

class PaginaConta extends StatefulWidget {
  final int numeroMesa;

  const PaginaConta({
    Key? key,
    required this.numeroMesa,
  }) : super(key: key);

  @override
  State<PaginaConta> createState() => _PaginaContaState();
}


class _PaginaContaState extends State<PaginaConta> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  late final int numeroMesa;
  List<Item> items = [];
  bool addService = true;
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    numeroMesa = widget.numeroMesa;
    carregarPedidos();
  }

  Future<void> carregarPedidos() async {
    setState(() => carregando = true);

    final contaRef = db.collection('contas').doc('mesa_$numeroMesa');
    final contaSnap = await contaRef.get();
    if (!contaSnap.exists) {
      setState(() {
        items = [];
        carregando = false;
      });
      return;
    }

    final pedidosIds = List<String>.from(contaSnap.data()?['pedidos'] ?? []);
    if (pedidosIds.isEmpty) {
      setState(() {
        items = [];
        carregando = false;
      });
      return;
    }

    // Busca dos pedidos (simples, 1 a 1; se quiser, dá pra otimizar em lotes de 10 com whereIn)
    final List<Item> temp = [];
    for (final id in pedidosIds) {
      final p = await db.collection('pedidos').doc(id).get();
      if (p.exists) {
        final d = p.data()!;
        final nome = (d['nomeProduto'] ?? '').toString();
        final double preco = _toDouble(d['preco']);
        final desc = (d['descricao'] ?? '').toString();
        temp.add(Item(nome, 1, preco, '', desc));
      }
    }

    // AGREGAÇÃO SEM MUTAR O OBJETO (evita setter em qty)
    final Map<String, int> qtdPorProduto = {};
    final Map<String, double> precoPorProduto = {};
    final Map<String, String> descPorProduto = {};

    for (final it in temp) {
      qtdPorProduto[it.name] = (qtdPorProduto[it.name] ?? 0) + it.qty;
      // mantém o último preço/desc conhecido (ou poderia validar consistência)
      precoPorProduto[it.name] = it.price;
      descPorProduto[it.name] = it.description;
    }

    final List<Item> agregados = qtdPorProduto.entries.map((e) {
      final nome = e.key;
      final qtd = e.value;
      final preco = precoPorProduto[nome] ?? 0.0;
      final desc = descPorProduto[nome] ?? '';
      return Item(nome, qtd, preco, '', desc);
    }).toList();

    setState(() {
      items = agregados;
      carregando = false;
    });
  }

  double _toDouble(dynamic v) => v is int ? v.toDouble() : (v is double ? v : 0.0);

  double subtotal() => items.fold(0.0, (s, it) => s + it.qty * it.price);
  double service() => addService ? subtotal() * 0.10 : 0.0;
  double total() => subtotal() + service();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mesa $numeroMesa - Resumo do Pedido", style: const TextStyle(fontSize: 15)),
        centerTitle: true,
        backgroundColor: const Color(0xFF448AFF),
        toolbarHeight: 50,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: carregarPedidos),
        ],
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Cabeçalho + lista com rolagem
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 6,
                      color: Colors.black.withOpacity(0.1),
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Expanded(
                          flex: 3,
                          child: Text("Produto", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text("Qtd", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text("Unitário", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text("Total", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    SizedBox(
                      height: 230,
                      child: ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const Divider(height: 16),
                        itemBuilder: (_, i) {
                          final it = items[i];
                          return Row(
                            children: [
                              Expanded(flex: 3, child: Text(it.name, style: const TextStyle(fontSize: 16))),
                              Expanded(flex: 2, child: Text('${it.qty}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16))),
                              Expanded(flex: 2, child: Text('R\$ ${it.price.toStringAsFixed(2)}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16))),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'R\$ ${(it.qty * it.price).toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Totais + botão
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(child: Text('Adicionar taxa de serviço (10%)', style: TextStyle(fontSize: 16))),
                        Switch(value: addService, onChanged: (v) => setState(() => addService = v)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _linhaValor('Subtotal', subtotal()),
                    _linhaValor('Taxa de serviço', service()),
                    const Divider(),
                    _linhaValor('Total', total(), isTotal: true),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF448AFF),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        onPressed: items.isEmpty
                            ? null
                            : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PaginaPagamento(
                                numeroMesa: numeroMesa,
                                total: total(),
                              ),
                            ),
                          ).then((_) => carregarPedidos());
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Align(
                              alignment: Alignment.center,
                              child: Text(
                                'Confirmar e ir para pagamento',
                                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Image.asset('assets/images/pix.jpg', height: 24, width: 24, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _linhaValor(String titulo, double valor, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                fontSize: isTotal ? 18 : 16,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            'R\$ ${valor.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
