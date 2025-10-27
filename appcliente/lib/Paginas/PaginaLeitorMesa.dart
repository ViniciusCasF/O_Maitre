import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Modelos/order_manager.dart';
import 'Pagina_Cardapio.dart';
import '../Modelos/ContaManager.dart';

class PaginaLeitorMesa extends StatefulWidget {
  final OrderManager order;
  const PaginaLeitorMesa({Key? key, required this.order}) : super(key: key);

  @override
  State<PaginaLeitorMesa> createState() => _PaginaLeitorMesaState();
}

class _PaginaLeitorMesaState extends State<PaginaLeitorMesa> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final contaManager = ContaManager();

  bool enviando = false;
  bool leituraConcluida = false;
  bool cozinhaAberta = true;
  bool restauranteAberto = true;

  @override
  void initState() {
    super.initState();
    carregarEstados();
  }

  Future<void> carregarEstados() async {
    await Future.wait([carregarEstadoCozinha(), carregarEstadoRestaurante()]);
  }

  Future<void> carregarEstadoCozinha() async {
    try {
      final doc = await db.collection('estados').doc('cozinha').get();
      if (doc.exists && doc.data()?['aberta'] != null) {
        setState(() => cozinhaAberta = doc['aberta'] == true);
      }
    } catch (e) {
      debugPrint('Erro estado cozinha: $e');
    }
  }

  Future<void> carregarEstadoRestaurante() async {
    try {
      final doc = await db.collection('estados').doc('restaurante').get();
      if (doc.exists && doc.data()?['aberto'] != null) {
        setState(() => restauranteAberto = doc['aberto'] == true);
      }
    } catch (e) {
      debugPrint('Erro estado restaurante: $e');
    }
  }

  Future<bool> verificarEAtualizarEstoque() async {
    final produtosRef = db.collection('produtos');
    final insumosRef = db.collection('insumos');
    final Map<String, double> consumoTotal = {};

    for (var item in widget.order.items) {
      final q = await produtosRef.where('nome', isEqualTo: item.name).limit(1).get();
      if (q.docs.isEmpty) continue;

      final data = q.docs.first.data();
      final List<dynamic>? insumos = data['insumos'] as List<dynamic>?;

      if (insumos != null) {
        for (var insumoMap in insumos) {
          final nomeInsumo = insumoMap['nome']?.toString();
          final qtdStr = insumoMap['quantidade']?.toString() ?? '0';
          final qtdUnit = double.tryParse(qtdStr.replaceAll(',', '.')) ?? 0.0;
          if (nomeInsumo == null || nomeInsumo.isEmpty) continue;

          final total = qtdUnit * item.qty;
          consumoTotal[nomeInsumo] = (consumoTotal[nomeInsumo] ?? 0) + total;
        }
      }
    }

    // checa disponibilidade
    for (var e in consumoTotal.entries) {
      final nomeInsumo = e.key;
      final qtdNec = e.value;

      final q = await insumosRef.where('nome', isEqualTo: nomeInsumo).limit(1).get();
      if (q.docs.isEmpty) {
        _erro('❌ Insumo "$nomeInsumo" não encontrado.');
        return false;
      }
      final data = q.docs.first.data();
      final qtdAtual = (data['quantidade'] ?? 0).toDouble();
      if (qtdAtual < qtdNec) {
        _erro('❌ Insumo "$nomeInsumo" em falta (precisa ${qtdNec.toStringAsFixed(2)}, tem ${qtdAtual.toStringAsFixed(2)}).');
        return false;
      }
    }

    // consome estoque
    for (var e in consumoTotal.entries) {
      final nome = e.key;
      final qtd = e.value;
      final q = await insumosRef.where('nome', isEqualTo: nome).limit(1).get();
      if (q.docs.isNotEmpty) {
        final doc = q.docs.first;
        final atual = (doc['quantidade'] ?? 0).toDouble();
        await insumosRef.doc(doc.id).update({'quantidade': atual - qtd});
      }
    }
    return true;
  }

  Future<void> _enviarPedidos(int numeroMesa) async {
    setState(() => enviando = true);

    try {
      await carregarEstadoRestaurante();
      if (!restauranteAberto) {
        _erro('❌ O restaurante está encerrado.');
        setState(() => enviando = false);
        return;
      }

      final estoqueOk = await verificarEAtualizarEstoque();
      if (!estoqueOk) {
        setState(() => enviando = false);
        return;
      }

      await carregarEstadoCozinha();

      final pedidosRef = db.collection('pedidos');
      final produtosRef = db.collection('produtos');

      // abre/garante conta
      await contaManager.abrirOuCriarConta(numeroMesa);

      // se cozinha fechada, bloqueia itens de cozinha
      if (!cozinhaAberta) {
        for (var it in widget.order.items) {
          final q = await produtosRef.where('nome', isEqualTo: it.name).limit(1).get();
          if (q.docs.isNotEmpty) {
            final tipo = q.docs.first.data()['tipo'] ?? 'garcom';
            if (tipo == 'cozinha') {
              _erro('❌ A cozinha está encerrada. Remova itens de cozinha.');
              setState(() => enviando = false);
              return;
            }
          }
        }
      }

      // envia pedidos
      for (var it in widget.order.items) {
        final q = await produtosRef.where('nome', isEqualTo: it.name).limit(1).get();
        String tipo = 'garcom';
        double preco = 0.0;

        if (q.docs.isNotEmpty) {
          final data = q.docs.first.data();
          tipo = data['tipo'] ?? 'garcom';
          final dynamic p = data['preco'];
          preco = p is int ? p.toDouble() : (p is double ? p : 0.0);
        }

        final status = (tipo == 'garcom') ? 1 : 2;

        for (int i = 0; i < it.qty; i++) {
          final doc = await pedidosRef.add({
            'nomeProduto': it.name,
            'mesa': numeroMesa,
            'descricao': it.description ?? '',
            'preco': preco, // ✅ gravando o preço no pedido
            'status': status,
            'startTime': FieldValue.serverTimestamp(),
          });

          // vincula à conta e soma preço
          await contaManager.adicionarPedido(numeroMesa, doc.id, preco);
        }
      }

      widget.order.clear();

      if (mounted) {
        await _ok(context);
        Navigator.of(context).popUntil((route) => route.isFirst);

      }
    } catch (e) {
      _erro('Erro ao enviar pedidos: $e');
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (leituraConcluida || enviando) return;
    final code = capture.barcodes.first.rawValue;
    if (code == null) return;

    setState(() => leituraConcluida = true);
    try {
      final numeroMesa = int.tryParse(code.replaceAll(RegExp(r'[^0-9]'), ''));
      if (numeroMesa == null) {
        _erro('QR Code inválido.');
        setState(() => leituraConcluida = false);
        return;
      }
      await _enviarPedidos(numeroMesa);
    } catch (_) {
      setState(() => leituraConcluida = false);
    }
  }

  void _erro(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _ok(BuildContext ctx) {
    return showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('✅ Pedido enviado!'),
        content: const Text('Seu pedido foi enviado com sucesso.'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF448AFF),
        title: const Text('Escanear QR da Mesa'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          Center(
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (enviando)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          Positioned(
            bottom: 80, left: 0, right: 0,
            child: const Text(
              'Aponte a câmera para o QR Code da mesa',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          if (!restauranteAberto)
            _banner('🍽️ O restaurante está encerrado.'),
          if (restauranteAberto && !cozinhaAberta)
            _banner('🍳 A cozinha está encerrada. Apenas itens de garçom.'),
        ],
      ),
    );
  }

  Widget _banner(String text) => Positioned(
    top: 0, left: 0, right: 0,
    child: Container(
      color: Colors.orange.shade50,
      padding: const EdgeInsets.all(12),
      child: Text(text, textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w600)),
    ),
  );
}
