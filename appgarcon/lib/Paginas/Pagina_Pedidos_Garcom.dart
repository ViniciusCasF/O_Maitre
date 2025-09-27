
import 'dart:async';
import 'package:flutter/material.dart';

// Modelo reaproveitado
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

class PaginaPedidosGarcom extends StatefulWidget {
  const PaginaPedidosGarcom({Key? key}) : super(key: key);

  @override
  State<PaginaPedidosGarcom> createState() => _PaginaPedidosGarcomState();
}

class _PaginaPedidosGarcomState extends State<PaginaPedidosGarcom> {
  List<Pedido> pedidos = [];
  List<Pedido> pedidosVisiveis = [];
  Timer? timer;

  @override
  void initState() {
    super.initState();

    // Mock de pedidos
    pedidos = List.generate(
      10,
          (i) => Pedido(
        nomeProduto: i % 2 == 0 ? "Cerveja" : "Pizza",
        mesa: i + 1,
        startTime: DateTime.now(),
        descricao: i % 2 == 0 ? "Bem gelada" : "Sem cebola",
      ),
    );

    pedidosVisiveis = List.from(pedidos);

    // Atualiza a tela a cada segundo
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds % 60)}";
  }

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
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      pedido.nomeProduto,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      pedido.descricao,
                      style: const TextStyle(fontSize: 15),
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
                            pedidos.remove(pedido);
                          }
                          Navigator.pop(context);
                        });
                      },
                      child: Text(
                        pedido.iniciado ? "Entregar pedido" : "Confirmar pedido",
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
    final largura = MediaQuery.of(context).size.width;
    int colunas = largura < 500 ? 2 : (largura < 900 ? 3 : 4);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pedidos (Garçom)"),
        backgroundColor: Colors.blue,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: colunas,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.9,
        ),
        itemCount: pedidosVisiveis.length,
        itemBuilder: (context, index) {
          final pedido = pedidosVisiveis[index];
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
    );
  }
}

