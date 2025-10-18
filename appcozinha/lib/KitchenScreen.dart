import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Barra_pesquisa.dart';

// Modelo de pedido
class Pedido {
  final String nomeProduto;
  final int mesa;
  final DateTime startTime;
  final String descricao;
  bool iniciado;
  bool entregue;

  Pedido({
    required this.nomeProduto,
    required this.mesa,
    required this.startTime,
    this.descricao = "Sem observações",
    this.iniciado = false,
    this.entregue = false,
  });
}

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool serviceEnded = false;
  final TextEditingController searchController = TextEditingController();

  List<Pedido> pedidos = [];
  List<Pedido> pedidosFiltrados = [];

  Timer? timer;

  @override
  void initState() {
    super.initState();

    // Mock de pedidos (exemplo)
    pedidos = List.generate(
      10,
          (i) => Pedido(
        nomeProduto: i % 2 == 0 ? "Porção Batata Frita" : "Hambúrguer",
        mesa: i + 1,
        startTime: DateTime.now(),
        descricao: i % 2 == 0
            ? "Sem sal, adicional de queijo"
            : "Ponto médio, sem cebola",
      ),
    );

    pedidosFiltrados = List.from(pedidos);

    // Atualiza o cronômetro a cada segundo
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // 🔥 Atualiza o estado da cozinha no Firestore
  Future<void> _atualizarEstadoCozinha(bool aberta) async {
    await _db.collection('estados').doc('cozinha').set({
      'aberta': aberta,
      'atualizadoPor': 'cozinha',
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  // Função para filtrar pedidos
  void filtrarPedidos(String query) {
    setState(() {
      if (query.isEmpty) {
        pedidosFiltrados = pedidos.where((p) => !p.entregue).toList();
      } else {
        pedidosFiltrados = pedidos
            .where((p) =>
        p.nomeProduto.toLowerCase().contains(query.toLowerCase()) &&
            !p.entregue)
            .toList();
      }
    });
  }

  // Formata duração como mm:ss
  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds % 60)}";
  }

  // Modal de detalhes do pedido
  void mostrarDetalhes(Pedido pedido) {
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
                      formatDuration(DateTime.now().difference(pedido.startTime)),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      pedido.nomeProduto,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      pedido.descricao,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        pedido.iniciado ? Colors.green : Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      onPressed: () {
                        setState(() {
                          if (!pedido.iniciado) {
                            pedido.iniciado = true;
                          } else {
                            pedido.entregue = true;
                          }
                          Navigator.pop(context);
                          filtrarPedidos(searchController.text);
                        });
                      },
                      child: Text(
                        pedido.iniciado ? "Entregar pedido" : "Iniciar preparo",
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Barra de pesquisa
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: BarraPesquisa(
                controller: searchController,
                onChanged: filtrarPedidos,
              ),
            ),

            // 🔥 STREAM DO FIRESTORE (sincroniza com o painel do proprietário)
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
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

            // Lista de pedidos
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.9,
                ),
                itemCount: pedidosFiltrados.length,
                itemBuilder: (context, index) {
                  final pedido = pedidosFiltrados[index];
                  final elapsed = DateTime.now().difference(pedido.startTime);

                  return GestureDetector(
                    onTap: () => mostrarDetalhes(pedido),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: pedido.iniciado ? Colors.green : Colors.black,
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
                                  pedido.nomeProduto,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                            Text(
                              "Mesa: ${pedido.mesa}",
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
