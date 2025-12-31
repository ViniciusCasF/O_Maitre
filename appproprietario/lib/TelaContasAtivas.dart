import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'TelaDetalhesConta.dart';

class TelaContasAtivas extends StatelessWidget {
  const TelaContasAtivas({super.key});

  Stream<QuerySnapshot> _streamContas() {
    return FirebaseFirestore.instance
        .collection('contas')
        .where('status', isNotEqualTo: 'fechada')
        .snapshots();
  }

  Future<void> cancelarConta(String mesaId, Map<String, dynamic> data) async {
    final db = FirebaseFirestore.instance;
    final pedidos = List<String>.from(data["pedidos"] ?? []);

    // 🗃 Arquiva como cancelada
    await db.collection("historico_contas_canceladas").add({
      "mesaNumero": data["mesaNumero"],
      "pedidos": pedidos,
      "subtotal": data["subtotal"] ?? 0.0,
      "custoTotal": data["custoTotal"] ?? 0.0,
      "taxaDeServico": data["taxaDeServico"] ?? false,
      "motivo": "Cancelada pelo proprietário",
      "timestamp": FieldValue.serverTimestamp(),
    });

    // 🔥 Marca pedidos como cancelados
    for (final id in pedidos) {
      await db.collection("pedidos").doc(id).update({
        "status": -2,
        "cancelledAt": FieldValue.serverTimestamp(),
      });
    }

    // 🧹 Reseta conta
    await db.collection("contas").doc(mesaId).set({
      "pedidos": [],
      "subtotal": 0,
      "total": 0,
      "custoTotal": 0,
      "status": "fechada",
      "status_pagamento": "cancelada",
      "resetAt": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Contas Ativas")),

      body: StreamBuilder<QuerySnapshot>(
        stream: _streamContas(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final contas = snapshot.data!.docs;

          if (contas.isEmpty) {
            return const Center(
              child: Text(
                "Nenhuma conta ativa no momento.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: contas.length,
            itemBuilder: (_, i) {
              final doc = contas[i];
              final data = doc.data() as Map<String, dynamic>;

              final mesa = data["mesaNumero"];
              final subtotal = (data["subtotal"] ?? 0.0).toDouble();
              final taxa = data["taxaDeServico"] ?? false;
              final pedidos = List<String>.from(data["pedidos"] ?? []);

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text("Mesa $mesa"),
                  subtitle: Text(
                        "Pedidos: ${pedidos.length}\n"
                  ),
                  trailing: Column(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          minimumSize: const Size(90, 30),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TelaDetalhesConta(
                                mesaId: doc.id,
                                data: data,
                              ),
                            ),
                          );
                        },
                        child: const Text("Detalhes"),
                      ),
                      const SizedBox(height: 4),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(90, 30),
                        ),
                        onPressed: () async {
                          final confirm = await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Cancelar conta"),
                              content: const Text(
                                  "Tem certeza que deseja cancelar esta conta?"),
                              actions: [
                                TextButton(
                                  child: const Text("Não"),
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                ),
                                TextButton(
                                  child: const Text("Sim"),
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await cancelarConta(doc.id, data);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Conta cancelada com sucesso.")),
                            );
                          }
                        },
                        child: const Text("Cancelar"),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
