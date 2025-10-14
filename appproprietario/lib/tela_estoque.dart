// lib/tela_estoque.dart
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:html' as html; // <-- só é usado na Web
import 'dart:convert';
import 'package:flutter/foundation.dart'; // para usar kIsWeb

class TelaEstoque extends StatefulWidget {
  const TelaEstoque({super.key});

  @override
  State<TelaEstoque> createState() => _TelaEstoqueState();
}

class _TelaEstoqueState extends State<TelaEstoque> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  int _filtroSelecionado = 0; // 0 = todos, 1 = em falta

  // Abre diálogo para adicionar novo insumo no Firestore
  void _adicionarInsumo() {
    final nomeController = TextEditingController();
    String unidadeSelecionada = "un";
    final qtdController = TextEditingController(text: '0');
    final minimaController = TextEditingController(text: '0');
    final maximaController = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Adicionar novo insumo"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nomeController, decoration: const InputDecoration(labelText: "Nome")),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: unidadeSelecionada,
                items: const [
                  DropdownMenuItem(value: "kg", child: Text("Quilos (kg)")),
                  DropdownMenuItem(value: "g", child: Text("Gramas (g)")),
                  DropdownMenuItem(value: "L", child: Text("Litros (L)")),
                  DropdownMenuItem(value: "un", child: Text("Unidades (un)")),
                ],
                onChanged: (v) => unidadeSelecionada = v ?? "un",
                decoration: const InputDecoration(labelText: "Unidade"),
              ),
              const SizedBox(height: 8),
              TextField(controller: qtdController, decoration: const InputDecoration(labelText: "Quantidade atual"), keyboardType: TextInputType.number),
              TextField(controller: minimaController, decoration: const InputDecoration(labelText: "Quantidade mínima"), keyboardType: TextInputType.number),
              TextField(controller: maximaController, decoration: const InputDecoration(labelText: "Quantidade máxima"), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final nome = nomeController.text.trim();
              if (nome.isEmpty) return;
              await _db.collection('insumos').add({
                'nome': nome,
                'unidade': unidadeSelecionada,
                'quantidade': int.tryParse(qtdController.text) ?? 0,
                'minima': int.tryParse(minimaController.text) ?? 0,
                'maxima': int.tryParse(maximaController.text) ?? 0,
                'createdAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  // Edita insumo: abre diálogo e atualiza o documento
  void _editarInsumo(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final qtdController = TextEditingController(text: (data['quantidade'] ?? 0).toString());
    final minimaController = TextEditingController(text: (data['minima'] ?? 0).toString());
    final maximaController = TextEditingController(text: (data['maxima'] ?? 0).toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Editar ${data['nome'] ?? ''}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtdController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Quantidade atual (${data['unidade'] ?? ''})"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: minimaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantidade mínima"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: maximaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantidade máxima"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              await _db.collection('insumos').doc(doc.id).update({
                'quantidade': int.tryParse(qtdController.text) ?? 0,
                'minima': int.tryParse(minimaController.text) ?? 0,
                'maxima': int.tryParse(maximaController.text) ?? 0,
                'updatedAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(context);
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  // Exporta insumos abaixo do mínimo para um arquivo .txt (salva em documentos do app)
  Future<void> _exportarFaltando() async {
    final snap = await _db.collection('insumos').orderBy('nome').get();
    final docs = snap.docs;

    final faltando = <String>[];
    for (final d in docs) {
      final data = d.data();
      final nome = data['nome'] ?? 'N/A';
      final qtd = (data['quantidade'] ?? 0).toString();
      final minima = (data['minima'] ?? 0).toString();
      final unidade = data['unidade'] ?? '';
      if ((data['quantidade'] ?? 0) < (data['minima'] ?? 0)) {
        faltando.add('$nome - ${qtd}${unidade} (mín: ${minima}${unidade})');
      }
    }

    if (faltando.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Nenhum insumo em falta 🎉')));
      return;
    }

    final now = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'insumos_faltando_$now.txt';
    final content = faltando.join('\n');

    try {
      if (kIsWeb) {
        // 🌐 --- WEB ---
        final bytes = utf8.encode(content);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arquivo baixado pelo navegador ✅')),
        );
      } else {
        // 📱 --- ANDROID / WINDOWS / iOS ---
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsString(content);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Arquivo salvo: ${file.path} ✅')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao exportar: $e')));
    }
  }

  // Remove insumo
  Future<void> _removerInsumo(String id) async {
    await _db.collection('insumos').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Controle de Estoque (Insumos)"),
        actions: [
          IconButton(icon: const Icon(Icons.download), onPressed: _exportarFaltando, tooltip: 'Exportar insumos em falta'),
          IconButton(icon: const Icon(Icons.add), onPressed: _adicionarInsumo, tooltip: 'Novo insumo'),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('insumos').orderBy('nome').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Erro: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          // aplicamos o filtro localmente
          final lista = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            if (_filtroSelecionado == 1) {
              return (data['quantidade'] ?? 0) < (data['minima'] ?? 0);
            }
            return true;
          }).toList();

          if (lista.isEmpty) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(label: const Text('Todos'), selected: _filtroSelecionado == 0, onSelected: (_) => setState(() => _filtroSelecionado = 0)),
                      ChoiceChip(label: const Text('Em falta'), selected: _filtroSelecionado == 1, onSelected: (_) => setState(() => _filtroSelecionado = 1)),
                    ],
                  ),
                ),
                const Expanded(child: Center(child: Text('Nenhum insumo cadastrado.'))),
              ],
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(label: const Text('Todos'), selected: _filtroSelecionado == 0, onSelected: (_) => setState(() => _filtroSelecionado = 0)),
                    ChoiceChip(label: const Text('Em falta'), selected: _filtroSelecionado == 1, onSelected: (_) => setState(() => _filtroSelecionado = 1)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: lista.length,
                  itemBuilder: (context, index) {
                    final doc = lista[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final nome = data['nome'] ?? '';
                    final unidade = data['unidade'] ?? '';
                    final qtd = data['quantidade'] ?? 0;
                    final minima = data['minima'] ?? 0;
                    final maxima = data['maxima'] ?? 0;
                    final emFalta = qtd < minima;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Icon(emFalta ? Icons.warning : Icons.check_circle, color: emFalta ? Colors.red : Colors.green),
                        title: Text(nome),
                        subtitle: Text('Qtd: $qtd $unidade | Min: $minima | Max: $maxima'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit), onPressed: () => _editarInsumo(doc)),
                            IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removerInsumo(doc.id)),
                          ],
                        ),
                        onTap: () => _editarInsumo(doc),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarInsumo,
        child: const Icon(Icons.add),
      ),
    );
  }
}
