import 'package:flutter/material.dart';

class TelaMesasGarcons extends StatefulWidget {
  const TelaMesasGarcons({super.key});

  @override
  State<TelaMesasGarcons> createState() => _TelaMesasGarconsState();
}

class _TelaMesasGarconsState extends State<TelaMesasGarcons> {
  // Lista de mesas (50 mesas inicialmente, todas sem garçom)
  final List<String?> _mesas = List.generate(50, (index) => null);

  // Lista de garçons
  final List<String> _garcons = ["João", "Maria", "Carlos", "Ana", "Pedro"];

  // Cores associadas a cada garçom
  final Map<String, Color> _garcomCores = {
    "João": Colors.blue,
    "Maria": Colors.red,
    "Carlos": Colors.green,
    "Ana": Colors.purple,
    "Pedro": Colors.orange,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Coluna de Mesas (70%)
        Expanded(
          flex: 7,
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, // 5 mesas por linha
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1, // mesas mais "quadradas"
            ),
            itemCount: _mesas.length,
            itemBuilder: (context, index) {
              final garcom = _mesas[index];
              final corMesa =
              garcom != null ? _garcomCores[garcom] ?? Colors.brown : Colors.brown[200];

              return DragTarget<String>(
                onAccept: (garcom) {
                  setState(() {
                    _mesas[index] = garcom;
                  });
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    decoration: BoxDecoration(
                      color: corMesa,
                      border: Border.all(color: Colors.brown, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: garcom == null
                          ? const Text("Mesa vazia",
                          style: TextStyle(fontSize: 12))
                          : Text(
                        "Mesa: $garcom",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Divisor entre mesas e garçons
        Container(
          width: 2,
          color: Colors.grey[400],
          margin: const EdgeInsets.symmetric(vertical: 12),
        ),

        // Coluna de Garçons (30%)
        Expanded(
          flex: 3,
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
