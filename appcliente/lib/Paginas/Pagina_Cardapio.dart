import 'package:appcliente/Paginas/Pagina_Produto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../Widget/Barra_pesquisa.dart';
import '../Widget/ProdutoCard.dart';
import 'Pagina_Pedidos.dart';
import '../Modelos/order_manager.dart';

class PaginaCardapio extends StatefulWidget {
  const PaginaCardapio({super.key});

  @override
  State<PaginaCardapio> createState() => _PaginaCardapioState();
}

class _PaginaCardapioState extends State<PaginaCardapio> {
  String searchText = '';
  String filtroAtivo = '';
  final OrderManager order = OrderManager();

  List<Map<String, dynamic>> produtos = [];
  List<String> filtros = [];

  @override
  void initState() {
    super.initState();
    carregarTudo();
  }

  Future<void> carregarTudo() async {
    await Future.wait([
      carregarProdutos(),
      carregarTags(),
    ]);
  }

  Future<void> carregarProdutos() async {
    try {
      final querySnapshot =
      await FirebaseFirestore.instance.collection('produtos').get();

      final novosProdutos = querySnapshot.docs.map((doc) {
        final data = doc.data();

        List<String> tags = [];
        if (data['tags'] != null) {
          tags = List<String>.from(data['tags']);
        }

        return {
          'nome': data['nome'] ?? 'Sem nome',
          'descricao': data['descricao'] ?? '',
          'imagem': data['imagemUrl'] ?? '',
          'tags': tags,
        };
      }).toList();

      setState(() {
        produtos = novosProdutos;
      });
    } catch (e) {
      print('Erro ao carregar produtos: $e');
    }
  }

  Future<void> carregarTags() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('tags').get();

      final tags = snapshot.docs
          .map((doc) => doc['nome']?.toString() ?? '')
          .where((t) => t.isNotEmpty)
          .toList();

      setState(() {
        filtros = tags;
      });
    } catch (e) {
      print('Erro ao carregar tags: $e');
    }
  }

  void buscarAtualizacoes(String value) {
    setState(() {
      searchText = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final produtosFiltrados = produtos.where((produto) {
      final matchesCategoria = filtroAtivo.isEmpty ||
          (produto['tags'] != null && produto['tags'].contains(filtroAtivo));

      final matchesBusca = searchText.isEmpty ||
          produto['nome'].toLowerCase().contains(searchText.toLowerCase());

      return matchesCategoria && matchesBusca;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: BarraPesquisa(onChanged: buscarAtualizacoes),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filtros (tags)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  for (var f in filtros) ...[
                    _buildFiltro(f),
                    const SizedBox(width: 8),
                  ],
                  const SizedBox(width: 16),
                ],
              ),
            ),

            // Lista de produtos
            Expanded(
              child: produtosFiltrados.isEmpty
                  ? const Center(child: Text('Nenhum produto encontrado'))
                  : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                itemCount: produtosFiltrados.length,
                itemBuilder: (context, index) {
                  final produto = produtosFiltrados[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaginaProduto(
                            nome: produto['nome'],
                            preco: 0,
                            imagem: produto['imagem'],
                            descricao: produto['descricao'],
                          ),
                        ),
                      ).then((_) {
                        setState(() {});
                      });
                    },
                    child: ProdutoCard(
                      nome: produto['nome'],
                      preco: 0,
                      imagem: produto['imagem'],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Barra de pedidos
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (order.items.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Pedido aberto: ${order.items.length} item(s)",
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PaginaPedidos()),
                      ).then((_) {
                        setState(() {});
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF448AFF),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: const Text("Finalizar pedido"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFiltro(String texto) {
    final bool ativo = filtroAtivo == texto;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: ativo ? const Color(0xFF448AFF) : Colors.white,
        foregroundColor: ativo ? Colors.white : const Color(0xFF448AFF),
        side: const BorderSide(color: Color(0xFF448AFF), width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: ativo ? 4 : 0,
      ),
      onPressed: () {
        setState(() {
          filtroAtivo = ativo ? '' : texto;
        });
      },
      child: Text(texto),
    );
  }
}
