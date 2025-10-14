import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaProdutos extends StatefulWidget {
  const TelaProdutos({super.key});

  @override
  State<TelaProdutos> createState() => _TelaProdutosState();
}

class _TelaProdutosState extends State<TelaProdutos> {
  final List<Map<String, dynamic>> _produtos = [];

  void _abrirDialogAdicionarProduto([int? indexEditar]) async {
    final produtoEditado = indexEditar != null ? _produtos[indexEditar] : null;

    final resultado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AdicionarProdutoDialog(
        produtoExistente: produtoEditado,
      ),
    );

    if (resultado != null) {
      setState(() {
        if (indexEditar != null) {
          _produtos[indexEditar] = resultado;
        } else {
          _produtos.add(resultado);
        }
      });
    }
  }

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
      body: ListView.builder(
        itemCount: _produtos.length,
        itemBuilder: (context, index) {
          final produto = _produtos[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: produto['imagemBytes'] != null
                  ? Image.memory(produto['imagemBytes'],
                  width: 50, height: 50, fit: BoxFit.cover)
                  : const Icon(Icons.image, size: 40),
              title: Text(produto['nome']),
              subtitle: Text(produto['descricao']),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _abrirDialogAdicionarProduto(index),
              ),
            ),
          );
        },
      ),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    if (widget.produtoExistente != null) {
      nomeController.text = widget.produtoExistente!['nome'];
      descricaoController.text = widget.produtoExistente!['descricao'];
      imagemBytes = widget.produtoExistente!['imagemBytes'];
      _insumos.addAll(
          List<Map<String, dynamic>>.from(widget.produtoExistente!['insumos']));
    }
  }

  Future<void> selecionarImagem() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        imagemBytes = result.files.single.bytes;
      });
    }
  }

  void adicionarInsumo() async {
    final insumo = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const AdicionarInsumoDialog(),
    );

    if (insumo != null) {
      setState(() {
        _insumos.add(insumo);
      });
    }
  }

  void removerInsumo(int index) {
    setState(() {
      _insumos.removeAt(index);
    });
  }

  void salvar() {
    if (nomeController.text.isEmpty || descricaoController.text.isEmpty) return;

    final produto = {
      'nome': nomeController.text,
      'descricao': descricaoController.text,
      'imagemBytes': imagemBytes,
      'insumos': _insumos,
    };

    Navigator.pop(context, produto);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.produtoExistente == null
          ? "Adicionar Produto"
          : "Editar Produto"),
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
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: adicionarInsumo,
                ),
              ],
            ),
            Column(
              children: _insumos.asMap().entries.map((entry) {
                final index = entry.key;
                final insumo = entry.value;
                final unidade = insumo['unidade'] ?? ''; // pega a unidade do insumo
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

          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: salvar,
          child: const Text("Salvar"),
        ),
      ],
    );
  }
}



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
      return {
        'id': doc.id,
        'nome': data['nome'] ?? '',
        'unidade': data['unidade'] ?? '',
      };
    }).toList();
  }

  void salvar() {
    if (insumoSelecionado == null || quantidadeController.text.isEmpty) return;

    Navigator.pop(context, {
      'nome': insumoSelecionado!,
      'quantidade': quantidadeController.text,
      'unidade': unidadeSelecionada ?? '',
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Adicionar Insumo"),
      content: FutureBuilder<List<Map<String, dynamic>>>(
        future: carregarInsumos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Text("Erro ao carregar insumos");
          }

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

                    // Atualiza a unidade de acordo com o insumo selecionado
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
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancelar"),
        ),
        ElevatedButton(
          onPressed: salvar,
          child: const Text("Adicionar"),
        ),
      ],
    );
  }
}
