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
  final db = FirebaseFirestore.instance;

  Future<void> excluirPedido(String pedidoId) async {
    // Exclui o documento do pedido
    await db.collection("pedidos").doc(pedidoId).delete();

    // Remove da lista da conta
    await db.collection("contas").doc(widget.mesaId).update({
      "pedidos": FieldValue.arrayRemove([pedidoId]),
    });

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final pedidosIds = List<String>.from(widget.data["pedidos"] ?? []);

    return Scaffold(
      appBar: AppBar(title: const Text("Pedidos da Conta")),
      body: pedidosIds.isEmpty
          ? const Center(child: Text("Nenhum pedido nesta conta."))
          : ListView.builder(
        itemCount: pedidosIds.length,
        itemBuilder: (_, i) {
          final pedidoId = pedidosIds[i];

          return StreamBuilder<DocumentSnapshot>(
            stream:
            db.collection("pedidos").doc(pedidoId).snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const ListTile(
                    title: Text("Carregando..."));
              }

              if (!snap.data!.exists) {
                return const ListTile(
                  title: Text("Pedido removido"),
                );
              }

              final data =
              snap.data!.data() as Map<String, dynamic>;

              final nome = data["nomeProduto"] ?? "Sem nome";
              final preco =
              (data["preco"] ?? 0.0).toDouble();
              final descricao = data["descricao"] ?? "";
              final tipo = data["tipo"] ?? "";
              final status = data["status"] ?? 0;
              final horario = data["startTime"];

              /// ==========================================
              /// 🔵 DEFINIÇÃO DE STATUS — 100% ALINHADO
              /// ==========================================
              String textoStatus = "Desconhecido";
              Color corStatus = Colors.grey;

              switch (status) {
                case 3:
                  textoStatus = "👨‍🍳 Preparando na cozinha";
                  corStatus = Colors.deepOrange;
                  break;

                case 2:
                  textoStatus = "📥 Cozinha recebeu";
                  corStatus = Colors.amber;
                  break;

                case 1:
                  textoStatus = "🧑‍🍽 Garçom recebeu";
                  corStatus = Colors.green;
                  break;

                case 0:
                  textoStatus = "🍽 Pedido entregue";
                  corStatus = Colors.blue;
                  break;

                case -1:
                  textoStatus = "📦 Arquivado";
                  corStatus = Colors.grey;
                  break;

                case -2:
                  textoStatus = "❌ Cancelado";
                  corStatus = Colors.red;
                  break;
              }

              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(
                    nome,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(
                          "Preço: R\$ ${preco.toStringAsFixed(2)}"),
                      if (descricao.isNotEmpty)
                        Text("Descrição: $descricao"),
                      Text("Tipo: $tipo"),

                      if (horario != null)
                        Text(
                          "Horário: ${DateTime.fromMillisecondsSinceEpoch(horario.seconds * 1000)}",
                        ),

                      const SizedBox(height: 6),

                      Text(
                        textoStatus,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: corStatus,
                        ),
                      ),
                    ],
                  ),

                  /// 🔴 Botão excluir só aparece
                  /// se o pedido não estiver arquivado
                  /// e não estiver cancelado
                  trailing: (status == 0 ||
                      status == 1 ||
                      status == 2 ||
                      status == 3)
                      ? IconButton(
                    icon: const Icon(Icons.delete,
                        color: Colors.red),
                    onPressed: () async {
                      final confirmar =
                      await showDialog(
                        context: context,
                        builder: (_) =>
                            AlertDialog(
                              title:
                              const Text("Excluir pedido"),
                              content: Text(
                                  "Deseja excluir definitivamente '$nome'?"),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(
                                          context,
                                          false),
                                  child: const Text(
                                      "Cancelar"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(
                                          context,
                                          true),
                                  child: const Text(
                                    "Excluir",
                                    style: TextStyle(
                                        color:
                                        Colors.red),
                                  ),
                                ),
                              ],
                            ),
                      );

                      if (confirmar == true) {
                        await excluirPedido(
                            pedidoId);

                        ScaffoldMessenger.of(
                            context)
                            .showSnackBar(
                          SnackBar(
                            content: Text(
                                "Pedido '$nome' excluído com sucesso."),
                          ),
                        );
                      }
                    },
                  )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
