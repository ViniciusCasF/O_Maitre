import 'package:flutter/material.dart';
import '../main.dart'; // IMPORTANTE! Só isso já faltava antes
import '../Widget/Nav-bar.dart';


class PaginaPagamentoAprovado extends StatelessWidget {
  final int numeroMesa;

  const PaginaPagamentoAprovado({Key? key, required this.numeroMesa})
      : super(key: key);

  void _voltarParaHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => MyHomePage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,

      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, size: 30, color: Colors.white),
            onPressed: () => _voltarParaHome(context),
          ),
        ],
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 120,
            ),

            const SizedBox(height: 20),

            const Text(
              "Pagamento Aprovado!",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "Mesa $numeroMesa",
              style: const TextStyle(
                fontSize: 20,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => _voltarParaHome(context),
              child: const Text(
                "Voltar ao Cardápio",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
