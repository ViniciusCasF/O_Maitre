import 'package:flutter/material.dart';

class PaginaPagamentoAprovado extends StatelessWidget {
  final int numeroMesa;

  const PaginaPagamentoAprovado({
    super.key,
    required this.numeroMesa,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade100,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 120),
            const SizedBox(height: 20),

            const Text(
              "Pagamento Confirmado!",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              "Mesa $numeroMesa liberada",
              style: const TextStyle(fontSize: 20),
            ),

            const SizedBox(height: 30),

          ],
        ),
      ),
    );
  }
}
