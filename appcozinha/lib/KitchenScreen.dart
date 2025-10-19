import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Barra_pesquisa.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController searchController = TextEditingController();

  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {}); // Atualiza cronômetros
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // Atualiza estado da cozinha (aberta/fechada)
  Future<void> _atualizarEstadoCozinha(bool aberta) async {
    await _db.collection('estados').doc('cozinha').set({
      'aberta': aberta,
      'atualizadoPor': 'cozinha',
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  // Atualiza status do pedido
  Future<void> _atualizarStatusPedido(String id, int novoStatus) async {
    await _db.collection('pedidos').doc(id).update({
      'status': novoStatus,
    });
  }

  // Formata duração
  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds % 60)}";
  }

  // Mostra detalhes do pedido (modal)
  void mostrarDetalhes(String id, Map<String, dynamic> pedido) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Timer.periodic(const Duration(seconds: 1), (timer) {
              if (!Navigator.of(context).canPop()) {
                timer.cancel();
              } else {
                setStateDialog(() {});
              }
            });

            final startTime = (pedido['startTime'] as Timestamp).toDate();
            final elapsed = DateTime.now().difference(startTime);
            final status = pedido['status'] ?? 2;

            // Tradução da lógica:
            // 2 = chegou
            // 3 = em preparo
            // 1 = pronto (entregar)
            String botaoTexto;
            Color botaoCor;
            int? proximoStatus;

            if (status == 2) {
              botaoTexto = "Iniciar preparo";
              botaoCor = Colors.blue;
              proximoStatus = 3;
            } else if (status == 3) {
              botaoTexto = "Pedido pronto";
              botaoCor = Colors.green;
              proximoStatus = 1;
            } else {
              botaoTexto = "Pedido entregue";
              botaoCor = Colors.grey;
              proximoStatus = null;
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formatDuration(elapsed),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      pedido['nomeProduto'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      pedido['descricao'] ?? "Sem observações",
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: botaoCor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      onPressed: proximoStatus == null
                          ? null
                          : () async {
                        await _atualizarStatusPedido(id, proximoStatus!);
                        Navigator.pop(context);
                      },
                      child: Text(
                        botaoTexto,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Filtro da barra de pesquisa
  bool _filtrar(Map<String, dynamic> pedido, String query) {
    if (query.isEmpty) return true;
    final nome = (pedido['nomeProduto'] ?? "").toString().toLowerCase();
    return nome.contains(query.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 🔎 Barra de pesquisa
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: BarraPesquisa(
                controller: searchController,
                onChanged: (_) => setState(() {}),
              ),
            ),

            // 🔥 Estado da cozinha
            StreamBuilder<DocumentSnapshot>(
              stream: _db.collection('estados').doc('cozinha').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text("Erro ao carregar estado da cozinha");
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const CircularProgressIndicator();
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final cozinhaAberta = data['aberta'] ?? false;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Cozinha:",
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cozinhaAberta ? "Aberta" : "Fechada",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cozinhaAberta ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Switch(
                      value: cozinhaAberta,
                      onChanged: (value) {
                        _atualizarEstadoCozinha(value);
                      },
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 10),

            // 📋 Lista de pedidos
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('pedidos').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text("Erro ao carregar pedidos"));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final pedidos = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 2;
                    // Exibe apenas pedidos com status 2 (chegou) ou 3 (em preparo)
                    return (status == 2 || status == 3) &&
                        _filtrar(data, searchController.text);
                  }).toList();

                  if (pedidos.isEmpty) {
                    return const Center(child: Text("Nenhum pedido pendente"));
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(10),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: pedidos.length,
                    itemBuilder: (context, index) {
                      final doc = pedidos[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final startTime =
                      (data['startTime'] as Timestamp).toDate();
                      final elapsed = DateTime.now().difference(startTime);
                      final status = data['status'] ?? 2;

                      return GestureDetector(
                        onTap: () => mostrarDetalhes(doc.id, data),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: status == 3 ? Colors.green : Colors.black,
                              width: 2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  formatDuration(elapsed),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Text(
                                      data['nomeProduto'] ?? 'Sem nome',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ),
                                Text(
                                  "Mesa: ${data['mesa'] ?? '?'}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
