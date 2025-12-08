// lib/Paginas/Pagina_Conta.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../Modelos/Itens.dart';
import '../Modelos/MesaHelper.dart';
import 'Pagina_Pagamento.dart';

class PaginaConta extends StatefulWidget {
  const PaginaConta({Key? key}) : super(key: key);

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
    numeroMesa = MesaHelper.detectarMesa();
    carregarPedidos();
  }

  Future<void> carregarPedidos() async {
    setState(() => carregando = true);

    final contaRef = db.collection('contas').doc('mesa_$numeroMesa');
    final contaSnap = await contaRef.get();

    // ❌ Não carrega conta fechada
    if (contaSnap.exists && contaSnap.data()?['status'] == 'fechada') {
      setState(() {
        items = [];
        carregando = false;
      });
      return;
    }

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

    final List<Item> temp = [];

    for (final id in pedidosIds) {
      final p = await db.collection('pedidos').doc(id).get();
      if (p.exists) {
        final d = p.data()!;
        temp.add(
          Item(
            d['nomeProduto'] ?? '',
            1,
            _toDouble(d['preco']),
            '',
            d['descricao'] ?? '',
          ),
        );
      }
    }

    final Map<String, int> qtd = {};
    final Map<String, double> preco = {};
    final Map<String, String> desc = {};

    for (final it in temp) {
      qtd[it.name] = (qtd[it.name] ?? 0) + 1;
      preco[it.name] = it.price;
      desc[it.name] = it.description;
    }

    items = qtd.entries.map((e) {
      return Item(
        e.key,
        e.value,
        preco[e.key] ?? 0.0,
        '',
        desc[e.key] ?? '',
      );
    }).toList();

    setState(() => carregando = false);
  }

  double _toDouble(dynamic v) => v is int ? v.toDouble() : (v is double ? v : 0.0);

  double subtotal() => items.fold(0.0, (s, it) => s + it.qty * it.price);
  double service() => addService ? subtotal() * 0.10 : 0.0;
  double total() => subtotal() + service();

  Future<Map<String, dynamic>> criarPagamentoPix(double valor) async {
    print("ENVIANDO PARA PIX: $valor");

    final url = Uri.parse(
      "https://us-central1-o-maitre.cloudfunctions.net/api/pix",
    );

    final resp = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"valor": double.parse(valor.toStringAsFixed(2))}),
    );

    print("RESPOSTA PIX: ${resp.body}");

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      throw Exception("Erro: ${resp.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mesa $numeroMesa - Resumo do Pedido"),
        centerTitle: true,
        backgroundColor: const Color(0xFF448AFF),
      ),

      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _listaProdutos(),
              _totais(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _listaProdutos() {
    return Container(
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
              Expanded(flex: 3, child: Text("Produto", style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text("Qtd", textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text("Unitário", textAlign: TextAlign.center)),
              Expanded(flex: 2, child: Text("Total", textAlign: TextAlign.right)),
            ],
          ),
          const Divider(),

          SizedBox(
            height: 240,
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, i) {
                final it = items[i];
                return Row(
                  children: [
                    Expanded(flex: 3, child: Text(it.name)),
                    Expanded(flex: 2, child: Text("${it.qty}", textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text("R\$ ${it.price}", textAlign: TextAlign.center)),
                    Expanded(
                      flex: 2,
                      child: Text(
                        "R\$ ${(it.qty * it.price).toStringAsFixed(2)}",
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _totais() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text("Adicionar taxa de serviço (10%)", style: TextStyle(fontSize: 16)),
              ),
              Switch(value: addService, onChanged: (v) => setState(() => addService = v)),
            ],
          ),

          _linhaValor("Subtotal", subtotal()),
          _linhaValor("Taxa de serviço", service()),
          const Divider(),
          _linhaValor("TOTAL", total(), isTotal: true),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF448AFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: items.isEmpty
                  ? null
                  : () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );

                try {
                  final pix = await criarPagamentoPix(total());

                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaginaPagamento(
                        numeroMesa: numeroMesa,
                        total: total(),
                        qrCodeBase64: pix["qr_code_base64"],
                        copiaECola: pix["copia_e_cola"],
                        idPagamento: pix["id"],
                      ),
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erro ao gerar PIX: $e")),
                  );
                }
              },
              child: const Text(
                "Confirmar e ir para pagamento",
                style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
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
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 18 : 16,
              ),
            ),
          ),
          Text(
            "R\$ ${valor.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 16,
            ),
          ),
        ],
      ),
    );
  }
}
