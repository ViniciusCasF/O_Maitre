import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'Pagina_Conta.dart';

class PaginaLeitorMesaGarcom extends StatefulWidget {
  const PaginaLeitorMesaGarcom({Key? key}) : super(key: key);

  @override
  State<PaginaLeitorMesaGarcom> createState() =>
      _PaginaLeitorMesaGarcomState();
}



  class _PaginaLeitorMesaGarcomState extends State<PaginaLeitorMesaGarcom> {
    bool leituraConcluida = false;

    void _onDetect(BarcodeCapture capture) {
      if (leituraConcluida) return;

      final code = capture.barcodes.first.rawValue;
      if (code == null) return;

      try {
        final uri = Uri.parse(code);

        // Lê SOMENTE o parâmetro ?mesa=
        final mesaStr = uri.queryParameters['mesa'];
        final mesa = int.tryParse(mesaStr ?? '');

        if (mesa == null) {
          _erro('QR Code inválido (mesa não encontrada)');
          return;
        }

        setState(() => leituraConcluida = true);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaginaConta(numeroMesa: mesa),
          ),
        );
      } catch (e) {
        _erro('QR Code inválido');
      }
  }

    void _erro(String msg) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.redAccent,
        ),
      );
    }



    @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear Mesa'),
        centerTitle: true,
        backgroundColor: const Color(0xFF448AFF),
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
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Text(
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
