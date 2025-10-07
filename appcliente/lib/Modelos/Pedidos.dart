// lib/Modelos/Pedido.dart
class Pedido {
  final String nome;
  final String descricao;
  final String? imagem;
  final DateTime data;
  final int mesa;
  final int tipo; // 0 = cozinha, 1 = garçom (bebida)
  int status; // 0 = pendente, 1 = pronto, 2 = entregue

  Pedido({
    required this.nome,
    required this.descricao,
    this.imagem,
    required this.data,
    required this.mesa,
    required this.tipo,
    this.status = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'imagem': imagem ?? '',
      'data': data,
      'mesa': mesa,
      'tipo': tipo,
      'status': status,
    };
  }
}
