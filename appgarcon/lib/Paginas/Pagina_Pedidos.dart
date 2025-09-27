// lib/Paginas/PaginaPedidos.dart
import 'package:flutter/material.dart';
import '../Modelos/Itens.dart';
import '../Modelos/order_manager.dart';
import 'Pagina_Pagamento.dart'; // ajusta o caminho se necessário

class PaginaPedidos extends StatefulWidget {
  const PaginaPedidos({Key? key}) : super(key: key);

  @override
  State<PaginaPedidos> createState() => _PaginaPedidosState();
}

class _PaginaPedidosState extends State<PaginaPedidos> {
  final OrderManager order = OrderManager();

  @override
  Widget build(BuildContext context) {
    final items = order.items;
    return Scaffold(
      appBar: AppBar(
        title: Text('Meu Pedido (${items.length})'),
        centerTitle: true,
        backgroundColor: const Color(0xFF448AFF),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Lista (sem preços)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: items.isEmpty
                    ? const Center(child: Text('Seu pedido está vazio.'))
                    : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) {
                    final it = items[i];
                    return ListTile(
                      leading: it.image != null && it.image.isNotEmpty
                          ? Image.asset(it.image, width: 48, height: 48, fit: BoxFit.cover)
                          : const Icon(Icons.fastfood),
                      title: Text(it.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Qtd: ${it.qty}'),
                          if (it.description != null && it.description.isNotEmpty) Text(it.description),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => setState(() => order.removeAt(i)),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Rodapé com botões
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // volta para onde o usuário vinha (cardápio/produtos).
                        // Navigator.pop(context);
                        // Se preferir voltar sempre para a raiz (cardápio), use:
                        Navigator.of(context).popUntil((r) => r.isFirst);
                      },
                      child: const Text('Adicionar mais produtos'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: items.isEmpty
                          ? null
                          : () {
                        // navega para pagamento (e opcionalmente limpa o pedido quando confirmado)
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PaginaPagamento()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF448AFF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Terminar pedido'),
                    ),
                  ),
                ],
              ),
            ),
            // segurança para não encostar no notch / barra
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
