import 'package:flutter/material.dart';

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
            child: Image.asset(imagem, fit: BoxFit.cover),
          ),

          // Descrição
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
                // aqui você vai adicionar lógica para incluir no pedido
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Produto adicionado ao pedido!")),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text("Adicionar por R\$ ${preco.toStringAsFixed(2)}"),
            ),
          ),
        ],
      ),
    );
  }
}
