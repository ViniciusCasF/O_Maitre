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
  // Adiciona uma nova mesa
  // =============================================================
  Future<void> _adicionarMesa() async {
    final mesasSnapshot = await _firestore.collection('mesas').get();
    final numerosExistentes = mesasSnapshot.docs
        .map((m) => m['numero'] as int)
        .toList()
      ..sort();

    int proximoNumero = 1;

    // Encontra o menor número que ainda não existe
    for (int i = 1; i <= numerosExistentes.length; i++) {
      if (!numerosExistentes.contains(i)) {
        proximoNumero = i;
        break;
      } else {
        proximoNumero = numerosExistentes.last + 1;
      }
    }

    await _firestore.collection('mesas').add({
      'numero': proximoNumero,
      'garcomId': null,
    });
  }


  // =============================================================
  // Adiciona novo garçom
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
  // Mostra o QR Code e botão de remover mesa
  // =============================================================
  void _mostrarQrCodeMesa(String mesaId, int numero) {
    final link = "http://192.168.0.109:5050/?mesa=$numero";

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

              // 🔹 QR CODE COM LINK
              QrImageView(
                data: link,
                version: QrVersions.auto,
                size: 200.0,
              ),

              const SizedBox(height: 10),
              const Text(
                "Link do pedido:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),

              // 🔹 Mostra o link (opcional)
              SelectableText(
                link,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Remover mesa"),
                      content: const Text("Tem certeza que deseja remover esta mesa?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancelar"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Remover"),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _firestore.collection('mesas').doc(mesaId).delete();
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.delete, color: Colors.white),
                label: const Text("Remover Mesa"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
              const SizedBox(height: 8),
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
  // Card visual do garçom
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
  // CONSTRUÇÃO DA TELA
  // =============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ======================== MESAS ========================
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
                                    onTap: () => _mostrarQrCodeMesa(mesaDoc.id, numero),
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

          // ======================== GARÇONS ========================
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

                Expanded(
                  child: Column(
                    children: [
                      // 🔹 Lista de garçons
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

                      // 🔻 Área de descarte para remover garçons
                      DragTarget<String>(
                        onAccept: (garcomId) async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Remover garçom"),
                              content: const Text("Deseja realmente remover este garçom?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("Cancelar"),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  child: const Text("Remover"),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _firestore.collection('garcons').doc(garcomId).delete();
                          }
                        },
                        builder: (context, candidateData, rejectedData) {
                          return Container(
                            margin: const EdgeInsets.all(8),
                            height: 60,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: candidateData.isEmpty ? Colors.red[100] : Colors.red[300],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red, width: 2),
                            ),
                            child: const Center(
                              child: Text(
                                "🗑️ Arraste aqui para remover garçom",
                                style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
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
