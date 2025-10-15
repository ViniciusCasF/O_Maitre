import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class TelaProdutos extends StatefulWidget {
  const TelaProdutos({super.key});

  @override
  State<TelaProdutos> createState() => _TelaProdutosState();
}

class _TelaProdutosState extends State<TelaProdutos> {
  List<Map<String, dynamic>> _produtos = [];

  @override
  void initState() {
    super.initState();
    carregarProdutos();
  }

  Future<void> carregarProdutos() async {
    final snapshot = await FirebaseFirestore.instance.collection('produtos').get();
    setState(() {
      _produtos.clear();
      for (var doc in snapshot.docs) {
        _produtos.add({
          ...doc.data(),
          'id': doc.id,
        });
      }
    });
  }


  // ================== SALVAR NOVO / ATUALIZAR PRODUTO ==================
  void _abrirDialogAdicionarProduto([Map<String, dynamic>? produtoExistente]) async {
    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AdicionarProdutoDialog(produtoExistente: produtoExistente),
    );

    if (resultado != null) {
      await carregarProdutos(); // recarrega lista do banco
    }
  }

  // ================== DELETAR PRODUTO ==================
  Future<void> _deletarProduto(String id) async {
    await FirebaseFirestore.instance.collection('produtos').doc(id).delete();
    carregarProdutos();
  }

  // ================== INTERFACE ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Produtos do Restaurante"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _abrirDialogAdicionarProduto(),
          ),
        ],
      ),
      body: _produtos.isEmpty
          ? const Center(child: Text("Nenhum produto cadastrado"))
          : ListView.builder(
        itemCount: _produtos.length,
        itemBuilder: (context, index) {
          final produto = _produtos[index];
          final tags = (produto['tags'] ?? []) as List;

          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: produto['imagemUrl'] != null
                  ? Image.network(
                produto['imagemUrl'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
                  : const Icon(Icons.image, size: 40),
              title: Text(produto['nome']),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(produto['descricao']),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 6,
                    children: tags
                        .map<Widget>(
                          (t) => Chip(
                        label: Text(t),
                        backgroundColor: Colors.blue.shade100,
                      ),
                    )
                        .toList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ===============================================================
// =============== DIALOGO DE ADICIONAR/EDITAR PRODUTO ===========
// ===============================================================

class AdicionarProdutoDialog extends StatefulWidget {
  final Map<String, dynamic>? produtoExistente;

  const AdicionarProdutoDialog({super.key, this.produtoExistente});

  @override
  State<AdicionarProdutoDialog> createState() => _AdicionarProdutoDialogState();
}

class _AdicionarProdutoDialogState extends State<AdicionarProdutoDialog> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController descricaoController = TextEditingController();
  Uint8List? imagemBytes;
  final List<Map<String, dynamic>> _insumos = [];
  List<String> _tagsSelecionadas = [];
  List<String> _todasTags = [];
  String? imagemUrlExistente;

  @override
  void initState() {
    super.initState();
    if (widget.produtoExistente != null) {
      nomeController.text = widget.produtoExistente!['nome'] ?? '';
      descricaoController.text = widget.produtoExistente!['descricao'] ?? '';
      _insumos.addAll(
          List<Map<String, dynamic>>.from(widget.produtoExistente!['insumos'] ?? []));
      _tagsSelecionadas =
      List<String>.from(widget.produtoExistente!['tags'] ?? []);
      imagemUrlExistente = widget.produtoExistente!['imagemUrl'];
    }
    carregarTags();
  }

  Future<void> carregarTags() async {
    final snapshot = await FirebaseFirestore.instance.collection('tags').get();
    setState(() {
      _todasTags = snapshot.docs.map((doc) => doc['nome'] as String).toList();
    });
  }

  void adicionarTag(String nomeTag) async {
    nomeTag = nomeTag.trim();
    if (nomeTag.isEmpty || _todasTags.contains(nomeTag)) return;
    await FirebaseFirestore.instance.collection('tags').add({'nome': nomeTag});
    setState(() {
      _todasTags.add(nomeTag);
      _tagsSelecionadas.add(nomeTag);
    });
  }

  Future<void> selecionarImagem() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        imagemBytes = result.files.single.bytes;
      });
    }
  }

  Future<String?> _uploadImagem(String produtoId) async {
    if (imagemBytes == null) return imagemUrlExistente; // mantém se não mudou
    try {
      final ref = FirebaseStorage.instance.ref().child('produtos/$produtoId.jpg');
      await ref.putData(imagemBytes!);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint("Erro ao enviar imagem: $e");
      return null;
    }
  }

  Future<void> salvar() async {
    if (nomeController.text.isEmpty || descricaoController.text.isEmpty) return;

    try {
      // Mostra loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      String? imageUrl;
      if (imagemBytes != null) {
        // Salvar imagem no Storage
        final ref = FirebaseStorage.instance
            .ref()
            .child('produtos')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = await ref.putData(imagemBytes!);
        imageUrl = await uploadTask.ref.getDownloadURL();
      }

      // Salvar dados no Firestore
      final produto = {
        'nome': nomeController.text,
        'descricao': descricaoController.text,
        'imagemUrl': imageUrl,
        'insumos': _insumos,
        'tags': _tagsSelecionadas,
        'criadoEm': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('produtos').add(produto);

      if (context.mounted) {
        Navigator.pop(context); // Fecha o loading
        Navigator.pop(context, produto); // Retorna o produto para a tela principal
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar produto: $e')),
      );
    }
  }


  void adicionarInsumo() async {
    final insumo = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const AdicionarInsumoDialog(),
    );
    if (insumo != null) setState(() => _insumos.add(insumo));
  }

  void removerInsumo(int index) => setState(() => _insumos.removeAt(index));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.produtoExistente == null ? "Adicionar Produto" : "Editar Produto"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            GestureDetector(
              onTap: selecionarImagem,
              child: Container(
                height: 120,
                width: double.infinity,
                color: Colors.grey[200],
                child: imagemBytes != null
                    ? Image.memory(imagemBytes!, fit: BoxFit.cover)
                    : imagemUrlExistente != null
                    ? Image.network(imagemUrlExistente!, fit: BoxFit.cover)
                    : const Icon(Icons.add_a_photo, size: 40),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: "Nome do Produto"),
            ),
            TextField(
              controller: descricaoController,
              decoration: const InputDecoration(labelText: "Descrição"),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                const Text("Insumos:"),
                const Spacer(),
                IconButton(icon: const Icon(Icons.add), onPressed: adicionarInsumo),
              ],
            ),
            Column(
              children: _insumos.asMap().entries.map((entry) {
                final index = entry.key;
                final insumo = entry.value;
                final unidade = insumo['unidade'] ?? '';
                return ListTile(
                  title: Text(insumo['nome']),
                  subtitle: Text(
                    "Quantidade: ${insumo['quantidade']}${unidade.isNotEmpty ? ' ($unidade)' : ''}",
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => removerInsumo(index),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 15),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text("Tags:", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Wrap(
              spacing: 8,
              children: _tagsSelecionadas.map((tag) {
                return Chip(
                  label: Text(tag),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => setState(() => _tagsSelecionadas.remove(tag)),
                );
              }).toList(),
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Adicionar ou criar Tag"),
              items: [
                ..._todasTags.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                const DropdownMenuItem(value: '__nova__', child: Text('➕ Criar nova tag...')),
              ],
              onChanged: (valor) async {
                if (valor == null) return;
                if (valor == '__nova__') {
                  final nomeNovaTag = await showDialog<String>(
                    context: context,
                    builder: (_) {
                      final controller = TextEditingController();
                      return AlertDialog(
                        title: const Text("Nova Tag"),
                        content: TextField(controller: controller, decoration: const InputDecoration(labelText: "Nome da Tag")),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
                          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text("Criar")),
                        ],
                      );
                    },
                  );
                  if (nomeNovaTag != null && nomeNovaTag.trim().isNotEmpty) adicionarTag(nomeNovaTag);
                } else if (!_tagsSelecionadas.contains(valor)) {
                  setState(() => _tagsSelecionadas.add(valor));
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(onPressed: salvar, child: const Text("Salvar")),
      ],
    );
  }
}

// ===============================================================
// =============== DIALOGO DE ADICIONAR INSUMO ===================
// ===============================================================

class AdicionarInsumoDialog extends StatefulWidget {
  const AdicionarInsumoDialog({super.key});
  @override
  State<AdicionarInsumoDialog> createState() => _AdicionarInsumoDialogState();
}

class _AdicionarInsumoDialogState extends State<AdicionarInsumoDialog> {
  final TextEditingController quantidadeController = TextEditingController();
  String? insumoSelecionado;
  String? unidadeSelecionada;

  Future<List<Map<String, dynamic>>> carregarInsumos() async {
    final snapshot = await FirebaseFirestore.instance.collection('insumos').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {'id': doc.id, 'nome': data['nome'] ?? '', 'unidade': data['unidade'] ?? ''};
    }).toList();
  }

  void salvar() {
    if (insumoSelecionado == null || quantidadeController.text.isEmpty) return;
    Navigator.pop(context, {'nome': insumoSelecionado!, 'quantidade': quantidadeController.text, 'unidade': unidadeSelecionada ?? ''});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Adicionar Insumo"),
      content: FutureBuilder<List<Map<String, dynamic>>>(
        future: carregarInsumos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return const Text("Erro ao carregar insumos");
          final insumos = snapshot.data ?? [];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Selecione o Insumo"),
                items: insumos.map<DropdownMenuItem<String>>((insumo) {
                  return DropdownMenuItem<String>(
                    value: insumo['nome'] as String,
                    child: Text(insumo['nome'] as String),
                  );
                }).toList(),
                value: insumoSelecionado,
                onChanged: (String? valor) {
                  setState(() {
                    insumoSelecionado = valor;
                    final selecionado = insumos.firstWhere(
                          (ins) => ins['nome'] == valor,
                      orElse: () => {'unidade': ''},
                    );
                    unidadeSelecionada = selecionado['unidade'] as String?;
                  });
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: quantidadeController,
                decoration: InputDecoration(
                  labelText: unidadeSelecionada == null
                      ? "Quantidade"
                      : "Quantidade (${unidadeSelecionada!})",
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          );
        },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
        ElevatedButton(onPressed: salvar, child: const Text("Adicionar")),
      ],
    );
  }
}
