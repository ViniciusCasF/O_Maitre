import 'package:flutter/material.dart';

class TelaEstoque extends StatefulWidget {
  const TelaEstoque({super.key});

  @override
  State<TelaEstoque> createState() => _TelaEstoqueState();
}

class _TelaEstoqueState extends State<TelaEstoque> {
  // Lista dinâmica de produtos
  final List<Map<String, dynamic>> _produtos = [
    {"nome": "Arroz", "quantidade": 10, "minima": 5, "maxima": 20},
    {"nome": "Feijão", "quantidade": 2, "minima": 5, "maxima": 15},
    {"nome": "Carne", "quantidade": 15, "minima": 10, "maxima": 30},
    {"nome": "Refrigerante", "quantidade": 0, "minima": 3, "maxima": 10},
    {"nome": "Batata", "quantidade": 20, "minima": 10, "maxima": 50},
  ];

  int _filtroSelecionado = 0; // 0 = todos, 1 = em falta, 2 = abaixo do máximo

  // Função para editar um produto
  void _editarProduto(int index) {
    final produto = _produtos[index];
    final TextEditingController qtdController =
    TextEditingController(text: produto["quantidade"].toString());
    final TextEditingController minimaController =
    TextEditingController(text: produto["minima"].toString());
    final TextEditingController maximaController =
    TextEditingController(text: produto["maxima"].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Editar ${produto["nome"]}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtdController,
              decoration: const InputDecoration(labelText: "Quantidade atual"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: minimaController,
              decoration: const InputDecoration(labelText: "Quantidade mínima"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: maximaController,
              decoration: const InputDecoration(labelText: "Quantidade máxima"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _produtos[index]["quantidade"] =
                    int.tryParse(qtdController.text) ?? 0;
                _produtos[index]["minima"] =
                    int.tryParse(minimaController.text) ?? 0;
                _produtos[index]["maxima"] =
                    int.tryParse(maximaController.text) ?? 0;
              });
              Navigator.pop(context);
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  // Função para exportar (mockada)
  void _exportarFaltando() {
    final faltando = _produtos
        .where((p) => p["quantidade"] < p["minima"])
        .map((p) => p["nome"])
        .toList();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(faltando.isEmpty
            ? "Nenhum produto em falta 🎉"
            : "Produtos em falta: ${faltando.join(", ")}"),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  List<Map<String, dynamic>> _filtrarProdutos() {
    if (_filtroSelecionado == 1) {
      return _produtos.where((p) => p["quantidade"] < p["minima"]).toList();
    } else if (_filtroSelecionado == 2) {
      return _produtos.where((p) => p["quantidade"] < p["maxima"]).toList();
    }
    return _produtos;
  }

  @override
  Widget build(BuildContext context) {
    final produtosFiltrados = _filtrarProdutos();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gerenciador de Estoque"),
        actions: [
          IconButton(
            onPressed: _exportarFaltando,
            icon: const Icon(Icons.file_download),
            tooltip: "Exportar produtos em falta",
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text("Todos"),
                  selected: _filtroSelecionado == 0,
                  onSelected: (_) {
                    setState(() => _filtroSelecionado = 0);
                  },
                ),
                ChoiceChip(
                  label: const Text("Em falta"),
                  selected: _filtroSelecionado == 1,
                  onSelected: (_) {
                    setState(() => _filtroSelecionado = 1);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: produtosFiltrados.length,
              itemBuilder: (context, index) {
                final produto = produtosFiltrados[index];
                final bool emFalta = produto["quantidade"] < produto["minima"];

                return Card(
                  margin:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: Icon(
                      emFalta ? Icons.warning : Icons.check_circle,
                      color: emFalta ? Colors.red : Colors.green,
                    ),
                    title: Text(produto["nome"]),
                    subtitle: Text(
                        "Qtd: ${produto["quantidade"]} | Mínima: ${produto["minima"]} | Máxima: ${produto["maxima"]}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _editarProduto(_produtos.indexOf(produto)),
                    ),
                    onTap: () => _editarProduto(_produtos.indexOf(produto)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
