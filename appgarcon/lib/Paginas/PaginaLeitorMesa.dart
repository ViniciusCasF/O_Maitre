import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../Modelos/order_manager.dart';

class PaginaLeitorMesa extends StatefulWidget {
  final OrderManager order;

  const PaginaLeitorMesa({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  State<PaginaLeitorMesa> createState() => _PaginaLeitorMesaState();
}

class _PaginaLeitorMesaState extends State<PaginaLeitorMesa> {
  bool leituraConcluida = false;

  void _onDetect(BarcodeCapture capture) {
    if (leituraConcluida) return;

    final code = capture.barcodes.first.rawValue;
    if (code == null) return;

    setState(() => leituraConcluida = true);

    try {
      final uri = Uri.parse(code);
      final mesaStr = uri.queryParameters['mesa'];
      final numeroMesa = int.tryParse(mesaStr ?? '');

      if (numeroMesa == null) {
        _erro('QR Code inválido.');
        setState(() => leituraConcluida = false);
        return;
      }

      // ✅ ÚNICA responsabilidade desta tela
      Navigator.pop(context, numeroMesa);
    } catch (_) {
      setState(() => leituraConcluida = false);
      _erro('QR Code inválido.');
    }
  }

  void _erro(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(m), backgroundColor: Colors.redAccent),
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
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
