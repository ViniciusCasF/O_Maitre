import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Modelos/order_manager.dart';
import '../Modelos/Pedidos.dart';
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

  Future<void> _enviarPedidos(int numeroMesa) async {
    setState(() => enviando = true);

    try {
      final pedidosRef = db.collection('pedidos');

      for (var item in widget.order.items) {
        // Define tipo: 1 = bebida (garçom), 0 = comida (cozinha)
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

      widget.order.clear();

      if (mounted) {
        await _mostrarPopupSucesso(context);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PaginaCardapio()),
              (r) => false,
        );
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

  void _onDetect(BarcodeCapture capture) async {
    if (leituraConcluida || enviando) return;

    final code = capture.barcodes.first.rawValue;
    if (code == null) return;

    setState(() => leituraConcluida = true);

    try {
      final numeroMesa = int.tryParse(code.replaceAll(RegExp(r'[^0-9]'), ''));

      if (numeroMesa == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR Code inválido.')),
        );
        setState(() => leituraConcluida = false);
        return;
      }

      await _enviarPedidos(numeroMesa);
    } catch (e) {
      setState(() => leituraConcluida = false);
    }
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
          MobileScanner(
            onDetect: _onDetect,
          ),
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
        ],
      ),
    );
  }
}