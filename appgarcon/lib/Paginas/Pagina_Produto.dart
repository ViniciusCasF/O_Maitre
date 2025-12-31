import 'package:flutter/material.dart';
import '../Modelos/Itens.dart';
import '../Modelos/order_manager.dart';
import 'Pagina_Pedidos.dart';

class PaginaProduto extends StatelessWidget {
  final String nome;
  final double preco;
  final String imagem;
  final String descricao;

  const PaginaProduto({
    Key? key,
    required this.nome,
    required this.preco,
    required this.imagem,
    required this.descricao,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(nome)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Imagem grande (30% da tela)
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.3,
            child: Image.network(
              imagem,
              fit: BoxFit.cover,
              width: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                print('Erro ao carregar imagem: $imagem');
                print('Detalhes do erro: $error');
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image,
                      size: 80, color: Colors.grey),
                );
              },
            ),
          ),

          // Descrição do produto
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              descricao,
              style: const TextStyle(fontSize: 16),
            ),
          ),

          const Spacer(),

          // Botão de adicionar
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                final TextEditingController detalhesController =
                TextEditingController();
                int qty = 1;

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) {
                    return StatefulBuilder(
                      builder: (contextSB, setStateSB) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom:
                            MediaQuery.of(contextSB).viewInsets.bottom,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Adicionar $nome',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Quantidade
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      onPressed: () => setStateSB(() {
                                        if (qty > 1) qty--;
                                      }),
                                      icon: const Icon(
                                          Icons.remove_circle_outline),
                                    ),
                                    Text('$qty',
                                        style:
                                        const TextStyle(fontSize: 18)),
                                    IconButton(
                                      onPressed: () =>
                                          setStateSB(() => qty++),
                                      icon: const Icon(
                                          Icons.add_circle_outline),
                                    ),
                                  ],
                                ),

                                // Campo de observações
                                TextField(
                                  controller: detalhesController,
                                  decoration: const InputDecoration(
                                    labelText: 'Detalhes (ex: sem gelo)',
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Botões
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          // adiciona o item e volta para o cardápio
                                          OrderManager().addItem(
                                            Item(nome, qty, preco, imagem,
                                                detalhesController.text),
                                          );
                                          Navigator.of(contextSB).pop();
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text(
                                            'Adicionar & continuar'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          // adiciona o item e vai para pedidos
                                          OrderManager().addItem(
                                            Item(nome, qty, preco, imagem,
                                                detalhesController.text),
                                          );
                                          Navigator.of(contextSB).pop();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                              const PaginaPedidos(),
                                            ),
                                          );
                                        },
                                        child:
                                        const Text('Ir para pedidos'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
              Text("Adicionar por R\$ ${preco.toStringAsFixed(2)}"),
            ),
          ),
        ],
      ),
    );
  }
}