import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart'; // ← precisa estar no pubspec.yaml

class TelaMesasGarcons extends StatefulWidget {
  const TelaMesasGarcons({super.key});

  @override
  State<TelaMesasGarcons> createState() => _TelaMesasGarconsState();
}

class _TelaMesasGarconsState extends State<TelaMesasGarcons> {
  final List<Map<String, dynamic>> _mesas = [];
  final List<String> _garcons = ["João", "Maria", "Carlos", "Ana", "Pedro"];

  final Map<String, Color> _garcomCores = {
    "João": Colors.blue,
    "Maria": Colors.red,
    "Carlos": Colors.green,
    "Ana": Colors.purple,
    "Pedro": Colors.orange,
  };

  void _adicionarMesa() {
    setState(() {
      int proximoNumero = _mesas.isEmpty ? 1 : _mesas.last['numero'] + 1;
      _mesas.add({'numero': proximoNumero, 'garcom': null});
    });
  }

  void _mostrarQrCodeMesa(int numero) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 300, // Largura explícita para forçar o tamanho e evitar o erro
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'QR Code da Mesa $numero',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              QrImageView(
                data: numero.toString(),
                version: QrVersions.auto,
                size: 200.0,
              ),
              const SizedBox(height: 10),
              Text(
                "Número da mesa: $numero",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Fechar"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ======================== COLUNA DE MESAS ========================
          Expanded(
            flex: 7,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Text(
                        "Mesas do Restaurante",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _adicionarMesa,
                        icon: const Icon(Icons.add),
                        label: const Text("Adicionar Mesa"),
                      ),
                    ],
                  ),
                ),
                // 🔹 Garante que o GridView tenha altura controlada
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1,
                    ),
                    itemCount: _mesas.length,
                    itemBuilder: (context, index) {
                      final mesa = _mesas[index];
                      final garcom = mesa['garcom'];
                      final corMesa = garcom != null
                          ? _garcomCores[garcom] ?? Colors.brown
                          : Colors.brown[200];

                      return DragTarget<String>(
                        onAccept: (garcom) {
                          setState(() {
                            _mesas[index]['garcom'] = garcom;
                          });
                        },
                        builder: (context, candidateData, rejectedData) {
                          return GestureDetector(
                            onTap: () => _mostrarQrCodeMesa(mesa['numero']),
                            child: Container(
                              decoration: BoxDecoration(
                                color: corMesa,
                                border: Border.all(color: Colors.brown, width: 2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Mesa ${mesa['numero']}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    garcom == null
                                        ? const Text(
                                      "Sem garçom",
                                      style: TextStyle(fontSize: 12),
                                    )
                                        : Text(
                                      "Garçom: $garcom",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
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

          // ======================== DIVISOR ========================
          VerticalDivider(
            color: Colors.grey[400],
            thickness: 2,
            indent: 12,
            endIndent: 12,
          ),

          // ======================== COLUNA DE GARÇONS ========================
          Expanded(
            flex: 3,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    "Garçons",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  // 🔹 Aqui o ListView agora tem limites de tamanho válidos
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _garcons.length,
                    itemBuilder: (context, index) {
                      final garcom = _garcons[index];
                      final cor = _garcomCores[garcom] ?? Colors.blueGrey;

                      return Draggable<String>(
                        data: garcom,
                        feedback: Material(
                          color: Colors.transparent,
                          child: _garcomCard(garcom, cor, arrastando: true),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.3,
                          child: _garcomCard(garcom, cor),
                        ),
                        child: _garcomCard(garcom, cor),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _garcomCard(String garcom, Color cor, {bool arrastando = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: cor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          garcom,
          style: TextStyle(
            fontSize: 16,
            color: arrastando ? Colors.yellowAccent : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}