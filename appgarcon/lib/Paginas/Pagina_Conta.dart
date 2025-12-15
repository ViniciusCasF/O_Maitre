// lib/Paginas/Pagina_Conta.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../Modelos/Itens.dart';
import 'Pagina_Pagamento.dart';
import 'Pagina_Pagamento_Aprovado.dart'; // ✅ NECESSÁRIO

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

  // =====================================================
  // 🔵 CARREGAR PEDIDOS + TAXA SALVA
  // =====================================================
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

    final data = contaSnap.data()!;
    final pedidosIds = List<String>.from(data['pedidos'] ?? []);

    addService = data['taxaDeServico'] ?? true;

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
        temp.add(Item(
          d['nomeProduto'] ?? '',
          1,
          _toDouble(d['preco']),
          '',
          d['descricao'] ?? '',
        ));
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

    setState(() {
      items = qtd.entries.map((e) {
        return Item(
          e.key,
          e.value,
          preco[e.key] ?? 0.0,
          '',
          desc[e.key] ?? '',
        );
      }).toList();

      carregando = false;
    });
  }

  // =====================================================
  // 🔵 CRIAR PIX
  // =====================================================
  Future<Map<String, dynamic>> criarPagamentoPix(double valor) async {
    final url = Uri.parse(
      "https://us-central1-o-maitre.cloudfunctions.net/api/pix",
    );

    final resp = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"valor": valor}),
    );

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      throw Exception("Erro ao gerar PIX: ${resp.body}");
    }
  }

  double _toDouble(dynamic v) =>
      v is int ? v.toDouble() : (v is double ? v : 0.0);

  double subtotal() => items.fold(0.0, (s, it) => s + it.qty * it.price);

  double service() => addService ? subtotal() * 0.10 : 0.0;

  double total() => subtotal() + service();

  // =====================================================
  // 🔵 UI PRINCIPAL
  // =====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mesa $numeroMesa - Resumo do Pedido"),
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // 🔵 LISTA
  // =====================================================
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
            height: 230,
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, i) {
                final it = items[i];
                return Row(
                  children: [
                    Expanded(flex: 3, child: Text(it.name)),
                    Expanded(flex: 2, child: Text("${it.qty}", textAlign: TextAlign.center)),
                    Expanded(flex: 2, child: Text("R\$ ${it.price.toStringAsFixed(2)}", textAlign: TextAlign.center)),
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

  // =====================================================
  // 🔵 TOTAIS + PAGAMENTOS
  // =====================================================
  Widget _totais() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Text("Adicionar taxa de serviço (10%)", style: TextStyle(fontSize: 16))),
              Switch(
                value: addService,
                onChanged: (v) async {
                  setState(() => addService = v);
                  await db.collection('contas').doc('mesa_$numeroMesa').set({
                    'taxaDeServico': v,
                    'lastActivity': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));
                },
              ),
            ],
          ),

          _linhaValor("Subtotal", subtotal()),
          _linhaValor("Taxa de serviço", service()),
          const Divider(),
          _linhaValor("Total", total(), isTotal: true),
          const SizedBox(height: 16),

          // ---------- BOTÃO PIX ----------
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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
                        idPagamento: pix["id"].toString(),
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
              child: const Text("Pagar com Pix", style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),

          const SizedBox(height: 12),

          // ---------- BOTÃO PAGAMENTO MANUAL ----------
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: items.isEmpty ? null : () async => await _pagarManual(),
              child: const Text(
                "Pagar com Cartão ou Dinheiro",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // 🔥 PAGAMENTO MANUAL
  // =====================================================
  Future<void> _pagarManual() async {
    final contaRef = db.collection("contas").doc("mesa_$numeroMesa");
    final snap = await contaRef.get();
    if (!snap.exists) return;

    final data = snap.data()!;
    final subtotal = (data["total"] ?? 0).toDouble();
    final custoTotal = (data["custoTotal"] ?? 0).toDouble();
    final taxa = data["taxaDeServico"] ?? true;
    final pedidos = List<String>.from(data["pedidos"] ?? []);

    final valorTaxa = taxa ? subtotal * 0.10 : 0.0;
    final totalFinal = subtotal + valorTaxa;

    await db.collection("historico_contas").add({
      "mesaNumero": numeroMesa,
      "pedidos": pedidos,
      "subtotal": subtotal,
      "taxaDeServico": taxa,
      "valorTaxa": valorTaxa,
      "totalFinal": totalFinal,
      "custoTotal": custoTotal,
      "lucro": totalFinal - custoTotal,
      "status": "paga",
      "timestamp_fechamento": FieldValue.serverTimestamp(),
    });

    for (final id in pedidos) {
      await db.collection("pedidos").doc(id).update({
        "status": -1,
        "archivedAt": FieldValue.serverTimestamp(),
      });
    }

    await contaRef.set({
      "mesaNumero": numeroMesa,
      "pedidos": [],
      "total": 0.0,
      "custoTotal": 0.0,
      "taxaDeServico": false,
      "status": "fechada",
      "status_pagamento": "aprovado",
      "resetAt": FieldValue.serverTimestamp(),
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PaginaPagamentoAprovado(numeroMesa: numeroMesa),
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
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          Text(
            "R\$ ${valor.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
