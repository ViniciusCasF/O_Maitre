import 'package:flutter/material.dart';

class ProdutoCard extends StatelessWidget {
  final String nome;
  final double preco;
  final String imagem;

  const ProdutoCard({
    super.key,
    required this.nome,
    required this.preco,
    required this.imagem,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF448AFF), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagem do produto (da internet)
          Expanded(
            child: ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imagem,
                fit: BoxFit.cover,
                width: double.infinity,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          (loadingProgress.expectedTotalBytes ?? 1)
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('Erro ao carregar a imagem: $imagem');
                  print('Detalhes do erro: $error');
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image,
                        size: 50, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
          // Nome e preço
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'R\$ ${preco.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF448AFF),
                    fontWeight: FontWeight.w600,
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
