import 'package:appcliente/Paginas/Pagina_Pagamento.dart';
import 'package:flutter/material.dart';
import '../Widget/Texto_Linha.dart';
import '../Modelos/Itens.dart';

class PaginaConta extends StatefulWidget {
  const PaginaConta({Key? key}) : super(key: key);

  @override
  State<PaginaConta> createState() => _PaginaConta();
}

class _PaginaConta extends State<PaginaConta> {
  final List<Item> items = [
    Item('Hambúrguer', 2, 21.90, "images/bruschetta.jpg", "teste"),
    Item('Batata média', 1, 12.00, "images/bruschetta.jpg", "teste"),
    Item('Suco de laranja', 3, 8.50, "images/bruschetta.jpg", "teste"),
    Item('Brownie', 1, 9.90, "images/bruschetta.jpg", "teste"),
    Item('Milk-shake', 1, 19.90, "images/bruschetta.jpg", "teste"),
    Item('Café expresso', 2, 6.50, "images/bruschetta.jpg", "teste"),
    Item('Pizza brotinho', 1, 25.00, "images/bruschetta.jpg", "teste"),
  ];

  bool addService = true;

  // Métodos GET
  double subtotal() => items.fold(0, (s, it) => s + (it.qty * it.price));

  double service() => addService ? subtotal() * 0.10 : 0.0;

  double total() => subtotal() + service();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Resumo do Pedido",
          style: TextStyle(fontSize: 15),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF448AFF),
        toolbarHeight: 50,
      ),
      body: SafeArea(
        child: Scrollbar(
          thickness: 6.0, // Espessura da barra de rolagem principal
          radius: const Radius.circular(3),
          thumbVisibility: true, // Barra sempre visível
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [


                // Parte da janela (Estrutura)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 6,
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 3),
                      ),
                      // Sombra na parte inferior para indicar rolagem
                      BoxShadow(
                        blurRadius: 6,
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, -3),
                        spreadRadius: -2,
                      ),
                    ],
                  ),

                  // Cabeçalho (em cima dos produtos)
                  child: Column(
                    children: [
                      Row(
                        children: const [
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Produto",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Qtd",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Unitário",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "Total",
                              textAlign: TextAlign.right,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 16),


                      // Lista de produtos com altura fixa e rolagem independente
                      SizedBox(
                        height: 210, // Altura fixa para a janela rolável
                        child: Scrollbar(
                          thickness: 4.0, // Espessura da barra de rolagem da lista
                          radius: const Radius.circular(2),
                          thumbVisibility: true, // Barra sempre visível
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8), // Espaço para evitar sobreposição
                            child: ListView.separated(
                              physics: const ClampingScrollPhysics(), // Rolagem suave
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const Divider(height: 16),
                              itemBuilder: (_, i) {
                                final it = items[i];
                                return Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        it.name,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${it.qty}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'R\$ ${it.price.toStringAsFixed(2)}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'R\$ ${(it.qty * it.price).toStringAsFixed(2)}',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),


                // Parte de totais e botão
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Adicionar taxa de serviço (10%)',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          Switch(
                            value: addService,
                            onChanged: (v) => setState(() => addService = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      textoLinha('Subtotal', subtotal()),

                      textoLinha('Taxa de serviço', service()),
                      const Divider(),
                      textoLinha('Total', total(), isTotal: true),

                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF448AFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PaginaPagamento(),
                              ),
                            );
                          },
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              /// Texto centralizado no meio do botão
                              const Align(
                                alignment: Alignment.center,
                                child: Text(
                                  'Confirmar e ir para pagamento',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              /// Logo alinhado no canto esquerdo
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 12), // margem da borda
                                  child: Image.asset(
                                    'assets/images/pix.jpg',
                                    height: 24,
                                    width: 24,
                                    color: Colors.white, // garante contraste no botão azul
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),


                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                // Espaço adicional para evitar que o botão fique colado no final
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}