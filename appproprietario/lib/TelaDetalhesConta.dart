import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaDetalhesConta extends StatefulWidget {
  final String mesaId;
  final Map<String, dynamic> data;

  const TelaDetalhesConta({
    super.key,
    required this.mesaId,
    required this.data,
  });

  @override
  State<TelaDetalhesConta> createState() => _TelaDetalhesContaState();
}

class _TelaDetalhesContaState extends State<TelaDetalhesConta> {
  Future<void> cancelarPedido(String pedidoId) async {
    final db = FirebaseFirestore.instance;

    // marca pedido como cancelado
    await db.collection("pedidos").doc(pedidoId).update({
      "status": -2,
      "cancelledAt": FieldValue.serverTimestamp(),
    });

    // remove da conta
    await db.collection("contas").doc(widget.mesaId).update({
      "pedidos": FieldValue.arrayRemove([pedidoId])
    });

    setState(() {}); // recarrega a tela
  }

  @override
  Widget build(BuildContext context) {
    final pedidos = List<String>.from(widget.data["pedidos"] ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalhes da Conta"),
      ),
      body: ListView.builder(
        itemCount: pedidos.length,
        itemBuilder: (_, i) {
          final pedidoId = pedidos[i];

          return Card(
            child: ListTile(
              title: Text("Pedido: $pedidoId"),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Cancelar"),
                onPressed: () async {
                  await cancelarPedido(pedidoId);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Pedido $pedidoId cancelado")),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
