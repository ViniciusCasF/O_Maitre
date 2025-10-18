import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class TelaMesasGarcons extends StatefulWidget {
  const TelaMesasGarcons({super.key});

  @override
  State<TelaMesasGarcons> createState() => _TelaMesasGarconsState();
}

class _TelaMesasGarconsState extends State<TelaMesasGarcons> {
  final _firestore = FirebaseFirestore.instance;

  // =============================================================
  // Adiciona uma nova mesa no banco
  // =============================================================
  Future<void> _adicionarMesa() async {
    final mesas = await _firestore.collection('mesas').get();
    int proximoNumero = mesas.docs.isEmpty
        ? 1
        : (mesas.docs.map((m) => m['numero'] as int).reduce((a, b) => a > b ? a : b) + 1);

    await _firestore.collection('mesas').add({
      'numero': proximoNumero,
      'garcomId': null,
    });
  }

  // =============================================================
  // Adiciona um novo garçom com nome e cor escolhida
  // =============================================================
  Future<void> _adicionarGarcom() async {
    final nomeController = TextEditingController();
    Color corSelecionada = Colors.brown;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Adicionar Garçom"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(
                labelText: "Nome do garçom",
              ),
            ),
            const SizedBox(height: 16),
            const Text("Escolha uma cor:"),
            const SizedBox(height: 8),
            BlockPicker(
              pickerColor: corSelecionada,
              onColorChanged: (color) {
                corSelecionada = color;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final nome = nomeController.text.trim();
              if (nome.isNotEmpty) {
                await _firestore.collection('garcons').add({
                  'nome': nome,
                  'cor': '#${corSelecionada.value.toRadixString(16).substring(2)}',
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // Mostra o QR Code da mesa (número)
  // =============================================================
  void _mostrarQrCodeMesa(int numero) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(16),
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

  // =============================================================
  // Cria o card visual de um garçom
  // =============================================================
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

  // =============================================================
  // CONSTRUÇÃO DA TELA PRINCIPAL
  // =============================================================
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

                // 🔹 Lista de mesas em tempo real
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('mesas').orderBy('numero').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final mesasDocs = snapshot.data!.docs;

                      return GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: mesasDocs.length,
                        itemBuilder: (context, index) {
                          final mesaDoc = mesasDocs[index];
                          final numero = mesaDoc['numero'];
                          final garcomId = mesaDoc['garcomId'];

                          return FutureBuilder<DocumentSnapshot?>(
                            future: garcomId != null
                                ? _firestore.collection('garcons').doc(garcomId).get()
                                : null,
                            builder: (context, garcomSnapshot) {
                              String garcomNome = "Sem garçom";
                              Color corMesa = Colors.brown[200]!;

                              if (garcomSnapshot.hasData && garcomSnapshot.data!.exists) {
                                final garcomData = garcomSnapshot.data!;
                                garcomNome = garcomData['nome'];
                                corMesa = Color(int.parse(
                                    (garcomData['cor'] ?? '795548').replaceFirst('#', '0xff')));
                              }

                              return DragTarget<String>(
                                onAccept: (garcomIdAceito) async {
                                  await _firestore.collection('mesas').doc(mesaDoc.id).update({
                                    'garcomId': garcomIdAceito,
                                  });
                                },
                                builder: (context, candidateData, rejectedData) {
                                  return GestureDetector(
                                    onTap: () => _mostrarQrCodeMesa(numero),
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
                                              "Mesa $numero",
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              garcomNome,
                                              style: const TextStyle(
                                                  fontSize: 12, color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
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
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Text(
                        "Garçons",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _adicionarGarcom,
                        icon: const Icon(Icons.add),
                        label: const Text("Adicionar Garçom"),
                      ),
                    ],
                  ),
                ),

                // 🔹 Lista de garçons em tempo real
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('garcons').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final garconsDocs = snapshot.data!.docs;

                      return ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: garconsDocs.length,
                        itemBuilder: (context, index) {
                          final garcom = garconsDocs[index];
                          final nome = garcom['nome'];
                          final corHex = garcom['cor'] ?? "795548";
                          final cor = Color(int.parse(corHex.replaceFirst('#', '0xff')));

                          return Draggable<String>(
                            data: garcom.id,
                            feedback: Material(
                              color: Colors.transparent,
                              child: _garcomCard(nome, cor, arrastando: true),
                            ),
                            childWhenDragging: Opacity(
                              opacity: 0.3,
                              child: _garcomCard(nome, cor),
                            ),
                            child: _garcomCard(nome, cor),
                          );
                        },
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
}
