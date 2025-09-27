import 'package:appgarcon/Paginas/Pagina_Produto.dart';
import 'package:flutter/material.dart';
import '../Widget/Barra_pesquisa.dart';
import '../Widget/ProdutoCard.dart';
import 'Pagina_Pedidos.dart'; // para abrir os pedidos
import '../Modelos/order_manager.dart'; // para acessar os itens do pedido

class PaginaCardapio extends StatefulWidget {
  const PaginaCardapio({super.key});

  @override
  State<PaginaCardapio> createState() => _PaginaCardapio();
}

class _PaginaCardapio extends State<PaginaCardapio> {
  String searchText = '';
  String filtroAtivo = '';

  final OrderManager order = OrderManager();

  final List<String> filtros = [
    'Entradas',
    'Bebidas',
    'Sobremesas',
    'Porções',
    'Massas',
    'Carnes',
  ];

  final List<Map<String, dynamic>> produtos = [
    {
      'nome': 'Bruschetta',
      'preco': 15.90,
      'categoria': 'Entradas',
      'imagem': 'assets/images/bruschetta.jpg',
      'descricao': 'Deliciosa torrada italiana com tomate e manjericão fresco.'
    },
    {
      'nome': 'Coca-Cola',
      'preco': 7.50,
      'categoria': 'Bebidas',
      'imagem': 'assets/images/coca_cola.jpg',
      'descricao': 'Refrigerante gelado, perfeito para acompanhar qualquer refeição.'
    },
    {
      'nome': 'Cheesecake',
      'preco': 12.00,
      'categoria': 'Sobremesas',
      'imagem': 'assets/images/cheesecake.jpg',
      'descricao': 'Clássica sobremesa americana de queijo com calda de frutas.'
    },
    {
      'nome': 'Batata Frita',
      'preco': 20.00,
      'categoria': 'Porções',
      'imagem': 'assets/images/batata_frita.jpg',
      'descricao': 'Porção crocante de batatas fritas, perfeita para compartilhar.'
    },
    {
      'nome': 'Spaghetti',
      'preco': 25.90,
      'categoria': 'Massas',
      'imagem': 'assets/images/spaghetti.jpg',
      'descricao': 'Espaguete italiano com molho artesanal de tomate e manjericão.'
    },
    {
      'nome': 'Filé Mignon',
      'preco': 45.00,
      'categoria': 'Carnes',
      'imagem': 'assets/images/file_mignon.jpg',
      'descricao': 'Filé mignon grelhado, servido ao ponto com acompanhamentos.'
    },
    {
      'nome': 'Suco de Laranja',
      'preco': 8.00,
      'categoria': 'Bebidas',
      'imagem': 'assets/images/suco_laranja.jpg',
      'descricao': 'Suco natural de laranja, feito na hora.'
    },
    {
      'nome': 'Tiramisu',
      'preco': 14.50,
      'categoria': 'Sobremesas',
      'imagem': 'assets/images/tiramisu.jpg',
      'descricao': 'Sobremesa italiana clássica com café, mascarpone e cacau.'
    },
  ];

  void buscarAtualizacoes(String value) {
    setState(() {
      searchText = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final produtosFiltrados = produtos.where((produto) {
      final matchesCategoria =
          filtroAtivo.isEmpty || produto['categoria'] == filtroAtivo;
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
            // Filtros
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
            // Produtos
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
                            preco: produto['preco'],
                            imagem: produto['imagem'],
                            descricao: produto['descricao'],
                          ),
                        ),
                      ).then((_) {
                        setState(() {}); // força rebuild para mostrar barra
                      });
                    },
                    child: ProdutoCard(
                      nome: produto['nome'],
                      preco: produto['preco'],
                      imagem: produto['imagem'],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Barra do pedido (fica acima da nav-bar)
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
                        setState(() {}); // atualiza quando volta
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
