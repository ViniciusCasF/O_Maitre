import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Modelos/order_manager.dart';
import 'Pagina_Cardapio.dart';

class PaginaLeitorMesa extends StatefulWidget {
  final OrderManager order;

  const PaginaLeitorMesa({Key? key, required this.order}) : super(key: key);

  @override
  State<PaginaLeitorMesa> createState() => _PaginaLeitorMesaState();
}

class _PaginaLeitorMesaState extends State<PaginaLeitorMesa> {
  final FirebaseFirestore db = FirebaseFirestore.instance;
  bool enviando = false;
  bool leituraConcluida = false;
  bool cozinhaAberta = true;
  bool restauranteAberto = true; // ✅ NOVO: estado do restaurante

  @override
  void initState() {
    super.initState();
    carregarEstados();
  }

  // =======================================================
  // ✅ CARREGAR ESTADOS DE COZINHA E RESTAURANTE
  // =======================================================
  Future<void> carregarEstados() async {
    await Future.wait([
      carregarEstadoCozinha(),
      carregarEstadoRestaurante(),
    ]);
  }

  Future<void> carregarEstadoCozinha() async {
    try {
      final doc = await db.collection('estados').doc('cozinha').get();
      if (doc.exists && doc.data()?['aberta'] != null) {
        setState(() {
          cozinhaAberta = doc['aberta'] == true;
        });
      }
    } catch (e) {
      print('Erro ao carregar estado da cozinha: $e');
    }
  }

  Future<void> carregarEstadoRestaurante() async {
    try {
      final doc = await db.collection('estados').doc('restaurante').get();
      if (doc.exists && doc.data()?['aberto'] != null) {
        setState(() {
          restauranteAberto = doc['aberto'] == true;
        });
      }
    } catch (e) {
      print('Erro ao carregar estado do restaurante: $e');
    }
  }

  // =======================================================
  // VERIFICA E ATUALIZA ESTOQUE
  // =======================================================
  Future<bool> verificarEAtualizarEstoque() async {
    final produtosRef = db.collection('produtos');
    final insumosRef = db.collection('insumos');
    Map<String, double> consumoTotal = {};

    for (var item in widget.order.items) {
      final query = await produtosRef.where('nome', isEqualTo: item.name).limit(1).get();
      if (query.docs.isEmpty) continue;

      final produtoData = query.docs.first.data();
      final List<dynamic>? insumos = produtoData['insumos'] as List<dynamic>?;

      if (insumos != null) {
        for (var insumoMap in insumos) {
          final nomeInsumo = insumoMap['nome']?.toString();
          final qtdStr = insumoMap['quantidade']?.toString() ?? '0';
          final qtdNecessariaPorItem = double.tryParse(qtdStr.replaceAll(',', '.')) ?? 0.0;

          if (nomeInsumo == null || nomeInsumo.isEmpty) continue;

          final qtdTotalNecessaria = qtdNecessariaPorItem * item.qty;
          consumoTotal[nomeInsumo] = (consumoTotal[nomeInsumo] ?? 0) + qtdTotalNecessaria;
        }
      }
    }

    // Verifica se há estoque suficiente
    for (var entry in consumoTotal.entries) {
      final nomeInsumo = entry.key;
      final qtdNecessaria = entry.value;

      final insumoQuery = await insumosRef.where('nome', isEqualTo: nomeInsumo).limit(1).get();
      if (insumoQuery.docs.isEmpty) {
        _mostrarErro('❌ Pedido cancelado! O insumo "$nomeInsumo" não foi encontrado no estoque.');
        return false;
      }

      final insumoData = insumoQuery.docs.first.data();
      final qtdAtual = (insumoData['quantidade'] ?? 0).toDouble();

      if (qtdAtual < qtdNecessaria) {
        _mostrarErro(
            '❌ Pedido cancelado! O insumo "$nomeInsumo" está em falta (necessário ${qtdNecessaria.toStringAsFixed(2)}, disponível ${qtdAtual.toStringAsFixed(2)}).');
        return false;
      }
    }

    // Atualiza o estoque (consome os insumos)
    for (var entry in consumoTotal.entries) {
      final nomeInsumo = entry.key;
      final qtdConsumir = entry.value;

      final insumoQuery = await insumosRef.where('nome', isEqualTo: nomeInsumo).limit(1).get();
      if (insumoQuery.docs.isNotEmpty) {
        final doc = insumoQuery.docs.first;
        final qtdAtual = (doc['quantidade'] ?? 0).toDouble();
        final novaQtd = qtdAtual - qtdConsumir;

        await insumosRef.doc(doc.id).update({'quantidade': novaQtd});
      }
    }

    return true;
  }

  // =======================================================
  // ENVIO DO PEDIDO
  // =======================================================
  Future<void> _enviarPedidos(int numeroMesa) async {
    setState(() => enviando = true);

    try {
      // ✅ Verifica o estado do restaurante antes de qualquer coisa
      await carregarEstadoRestaurante();
      if (!restauranteAberto) {
        _mostrarErro('❌ O restaurante está encerrado. Não é possível enviar pedidos no momento.');
        setState(() => enviando = false);
        return;
      }

      // ✅ Verifica e atualiza estoque
      final estoqueOk = await verificarEAtualizarEstoque();
      if (!estoqueOk) {
        setState(() => enviando = false);
        return;
      }

      // ✅ Verifica a cozinha
      await carregarEstadoCozinha();

      final pedidosRef = db.collection('pedidos');
      final produtosRef = db.collection('produtos');

      // 🔍 Verifica se há itens de cozinha quando a cozinha está fechada
      if (!cozinhaAberta) {
        bool possuiItensCozinha = false;

        for (var item in widget.order.items) {
          final query = await produtosRef.where('nome', isEqualTo: item.name).limit(1).get();
          if (query.docs.isNotEmpty) {
            final tipo = query.docs.first.data()['tipo'] ?? '';
            if (tipo == 'cozinha') {
              possuiItensCozinha = true;
              break;
            }
          }
        }

        if (possuiItensCozinha) {
          _mostrarErro('❌ A cozinha está encerrada. Remova os itens de cozinha para enviar o pedido.');
          setState(() => enviando = false);
          return;
        }
      }

      // ✅ Envia os pedidos
      for (var item in widget.order.items) {
        final query = await produtosRef.where('nome', isEqualTo: item.name).limit(1).get();
        String tipo = 'garcom';
        if (query.docs.isNotEmpty) {
          tipo = query.docs.first.data()['tipo'] ?? 'garcom';
        }

        final status = (tipo == 'garcom') ? 1 : 2;

        for (int i = 0; i < item.qty; i++) {
          await pedidosRef.add({
            'nomeProduto': item.name,
            'mesa': numeroMesa,
            'descricao': item.description ?? '',
            'status': status,
            'startTime': FieldValue.serverTimestamp(),
          });
        }
      }

      widget.order.clear();

      if (mounted) {
        await _mostrarPopupSucesso(context);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PaginaCardapio()),
              (r) => false,
        );
      }
    } catch (e) {
      _mostrarErro('Erro ao enviar pedidos: $e');
    } finally {
      if (mounted) setState(() => enviando = false);
    }
  }

  // =======================================================
  // UTILITÁRIOS
  // =======================================================
  void _mostrarErro(String mensagem) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagem), backgroundColor: Colors.redAccent),
      );
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

  // =======================================================
  // LEITOR DE QR CODE
  // =======================================================
  void _onDetect(BarcodeCapture capture) async {
    if (leituraConcluida || enviando) return;

    final code = capture.barcodes.first.rawValue;
    if (code == null) return;

    setState(() => leituraConcluida = true);

    try {
      final numeroMesa = int.tryParse(code.replaceAll(RegExp(r'[^0-9]'), ''));

      if (numeroMesa == null) {
        _mostrarErro('QR Code inválido.');
        setState(() => leituraConcluida = false);
        return;
      }

      await _enviarPedidos(numeroMesa);
    } catch (e) {
      setState(() => leituraConcluida = false);
    }
  }

  // =======================================================
  // INTERFACE
  // =======================================================
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
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (enviando)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: const Text(
              'Aponte a câmera para o QR Code da mesa',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),

          // ⚠️ AVISO VISUAL QUANDO FECHADO
          if (!restauranteAberto)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.red.shade50,
                padding: const EdgeInsets.all(12),
                child: const Text(
                  '🍽️ O restaurante está encerrado. Não é possível enviar pedidos no momento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else if (!cozinhaAberta)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.orange.shade50,
                padding: const EdgeInsets.all(12),
                child: const Text(
                  '🍳 A cozinha está encerrada. Apenas pedidos de garçom serão aceitos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
