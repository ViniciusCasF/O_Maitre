import 'package:flutter/material.dart';
import '../Widget/Barra_pesquisa.dart'; // Importa a barra de pesquisa
import '../Widget/ProdutoCard.dart'; // Importa o widget de produto

class PaginaCardapio extends StatefulWidget {
  const PaginaCardapio({super.key});

  @override
  State<PaginaCardapio> createState() => _PaginaCardapio();
}

class _PaginaCardapio extends State<PaginaCardapio> {
  String searchText = '';
  String filtroAtivo = '';

  final List<String> filtros = [
    'Entradas',
    'Bebidas',
    'Sobremesas',
    'Porções',
    'Massas',
    'Carnes',
  ];

  // Lista de produtos estática para demonstração
  final List<Map<String, dynamic>> produtos = [
    {'nome': 'Bruschetta', 'preco': 15.90, 'categoria': 'Entradas', 'imagem': 'assets/images/bruschetta.jpg'},
    {'nome': 'Coca-Cola', 'preco': 7.50, 'categoria': 'Bebidas', 'imagem': 'assets/images/coca_cola.jpg'},
    {'nome': 'Cheesecake', 'preco': 12.00, 'categoria': 'Sobremesas', 'imagem': 'assets/images/cheesecake.jpg'},
    {'nome': 'Batata Frita', 'preco': 20.00, 'categoria': 'Porções', 'imagem': 'assets/images/batata_frita.jpg'},
    {'nome': 'Spaghetti', 'preco': 25.90, 'categoria': 'Massas', 'imagem': 'assets/images/spaghetti.jpg'},
    {'nome': 'Filé Mignon', 'preco': 45.00, 'categoria': 'Carnes', 'imagem': 'assets/images/file_mignon.jpg'},
    {'nome': 'Suco de Laranja', 'preco': 8.00, 'categoria': 'Bebidas', 'imagem': 'assets/images/suco_laranja.jpg'},
    {'nome': 'Tiramisu', 'preco': 14.50, 'categoria': 'Sobremesas', 'imagem': 'assets/images/tiramisu.jpg'},
  ];

  void buscarAtualizacoes(String value) {
    setState(() {
      searchText = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar produtos com base nos filtros e a pesquisa

    final produtosFiltrados = produtos.where((produto) {
      final matchesCategoria = filtroAtivo.isEmpty || produto['categoria'] == filtroAtivo;
      final matchesBusca = searchText.isEmpty ||
          produto['nome'].toLowerCase().contains(searchText.toLowerCase());
      return matchesCategoria && matchesBusca;
    }).toList();


    // Barra de pesquisa
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Duas colunas
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7, // Proporção para evitar esticamento
                ),
                itemCount: produtosFiltrados.length,
                itemBuilder: (context, index) {
                  final produto = produtosFiltrados[index];
                  return ProdutoCard(
                    nome: produto['nome'],
                    preco: produto['preco'],
                    imagem: produto['imagem'],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  // Funções para adicionar os botões de filtros
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
          if (ativo) {
            filtroAtivo = ''; // 🔹 se já estava ativo, desativa
          } else {
            filtroAtivo = texto; // 🔹 senão, ativa
          }
        });
      },
      child: Text(texto),
    );
  }
}