import 'dart:async';
import 'package:flutter/material.dart';
import 'Barra_pesquisa.dart';

// Modelo de pedido
class Pedido {
  final String nomeProduto;
  final int mesa;
  final DateTime startTime;

  Pedido({
    required this.nomeProduto,
    required this.mesa,
    required this.startTime,
  });
}

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  bool serviceEnded = false;
  final TextEditingController searchController = TextEditingController();

  List<Pedido> pedidos = [];
  List<Pedido> pedidosFiltrados = [];

  Timer? timer;

  @override
  void initState() {
    super.initState();

    // Mock de pedidos
    pedidos = List.generate(
      20,
          (i) => Pedido(
        nomeProduto: i % 2 == 0 ? "Porção Batata Frita" : "Hamburguer",
        mesa: i + 1,
        startTime: DateTime.now(),
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

  // Função para filtrar pedidos
  void filtrarPedidos(String query) {
    setState(() {
      if (query.isEmpty) {
        pedidosFiltrados = List.from(pedidos);
      } else {
        pedidosFiltrados = pedidos
            .where((p) =>
            p.nomeProduto.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // Formata duração como mm:ss
  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds % 60)}";
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

            // Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Switch(
                  value: serviceEnded,
                  onChanged: (value) {
                    setState(() {
                      serviceEnded = value;
                    });
                  },
                ),
                const Text(
                  "Encerrar Serviço da cozinha",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Janela com pedidos
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // ajusta conforme a tela
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.9,
                ),
                itemCount: pedidosFiltrados.length,
                itemBuilder: (context, index) {
                  final pedido = pedidosFiltrados[index];
                  final elapsed = DateTime.now().difference(pedido.startTime);

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.black, width: 1),
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
