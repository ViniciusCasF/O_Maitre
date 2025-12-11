import 'package:appcliente/Paginas/Pagina_Produto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../Widget/Barra_pesquisa.dart';
import '../Widget/ProdutoCard.dart';
import 'Pagina_Pedidos.dart';
import '../Modelos/order_manager.dart';
import '../Modelos/MesaHelper.dart';

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

  bool cozinhaAberta = true;
  bool restauranteAberto = true; // ✅ NOVO

  @override
  void initState() {
    super.initState();
    carregarTudo().then((_) => verificarOuCriarConta());
  }

  Future<void> verificarOuCriarConta() async {
    final mesa = MesaHelper.detectarMesa();
    final db = FirebaseFirestore.instance;
    final docRef = db.collection("contas").doc("mesa_$mesa");
    final snap = await docRef.get();

    // 1. Conta não existe → criar nova
    if (!snap.exists) {
      await docRef.set({
        "mesaNumero": mesa,
        "pedidos": [],
        "total": 0,
        "status": "aberta",
        "status_pagamento": "pendente",
        "startTime": FieldValue.serverTimestamp(),
        "lastActivity": FieldValue.serverTimestamp(),
      });
      return;
    }

    final data = snap.data()!;
    final status = data["status"];

    // 2. Se conta fechada → arquiva ANTES
    if (status == "fechada") {

      // 3. Depois cria uma nova conta limpa
      await docRef.set({
        "mesaNumero": mesa,
        "pedidos": [],
        "total": 0,
        "status": "aberta",
        "status_pagamento": "pendente",
        "startTime": FieldValue.serverTimestamp(),
        "lastActivity": FieldValue.serverTimestamp(),
      });
    }
  }


  Future<void> carregarTudo() async {
    await Future.wait([
      carregarEstadoCozinha(),
      carregarEstadoRestaurante(), // ✅ NOVO
      carregarTags(),
    ]);
    await carregarProdutos();
  }

  Future<void> arquivarContaSeFechada(int mesa) async {
    final db = FirebaseFirestore.instance;
    final docRef = db.collection("contas").doc("mesa_$mesa");
    final snap = await docRef.get();

    if (!snap.exists) return;

    final dados = snap.data()!;
    final status = dados["status"];

    // Apenas arquiva se estiver fechada
    if (status == "fechada") {

      final double total = (dados["total"] ?? 0.0).toDouble();
      final double custoTotal = (dados["custoTotal"] ?? 0.0).toDouble();

      await db.collection("historico_contas").add({
        ...dados,
        "mesaNumero": mesa,
        "totalVenda": total,
        "custoTotal": custoTotal,
        "lucro": total - custoTotal,   // opcional
        "timestamp_fechamento": FieldValue.serverTimestamp(),
      });
    }
  }



  // ==============================
  // ESTADO DA COZINHA
  // ==============================
  Future<void> carregarEstadoCozinha() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('estados')
          .doc('cozinha')
          .get();

      if (doc.exists && doc.data()?['aberta'] != null) {
        cozinhaAberta = doc['aberta'] == true;
      }
    } catch (e) {
      print('Erro ao carregar estado da cozinha: $e');
    }
  }

  // ==============================
  // ✅ NOVO: ESTADO DO RESTAURANTE
  // ==============================
  Future<void> carregarEstadoRestaurante() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('estados')
          .doc('restaurante')
          .get();

      if (doc.exists && doc.data()?['aberto'] != null) {
        restauranteAberto = doc['aberto'] == true;
      }
    } catch (e) {
      print('Erro ao carregar estado do restaurante: $e');
    }
  }

  // ==============================
  // PRODUTOS
  // ==============================
  Future<void> carregarProdutos() async {
    try {
      // ✅ Se o restaurante estiver fechado, não carrega produtos
      if (!restauranteAberto) {
        setState(() {
          produtos = [];
        });
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final produtosSnapshot = await firestore.collection('produtos').get();
      final insumosRef = firestore.collection('insumos');

      List<Map<String, dynamic>> produtosDisponiveis = [];

      for (var doc in produtosSnapshot.docs) {
        final data = doc.data();

        List<String> tags = [];
        if (data['tags'] != null) {
          tags = List<String>.from(data['tags']);
        }

        // Verifica insumos do produto
        final List<dynamic>? insumos = data['insumos'] as List<dynamic>?;
        bool possuiEstoqueSuficiente = true;

        if (insumos != null && insumos.isNotEmpty) {
          for (var insumoMap in insumos) {
            final nomeInsumo = insumoMap['nome']?.toString() ?? '';
            final qtdStr = insumoMap['quantidade']?.toString() ?? '0';
            final qtdNecessaria =
                double.tryParse(qtdStr.replaceAll(',', '.')) ?? 0.0;

            if (nomeInsumo.isEmpty) continue;

            final query = await insumosRef
                .where('nome', isEqualTo: nomeInsumo)
                .limit(1)
                .get();

            if (query.docs.isEmpty) {
              possuiEstoqueSuficiente = false;
              break;
            }

            final insumoData = query.docs.first.data();
            final qtdAtual = (insumoData['quantidade'] ?? 0).toDouble();

            if (qtdAtual < qtdNecessaria) {
              possuiEstoqueSuficiente = false;
              break;
            }
          }
        }

        if (possuiEstoqueSuficiente) {
          // Se a cozinha estiver fechada, só mostra produtos do garçom
          if (!cozinhaAberta && (data['tipo'] ?? 'garcom') != 'garcom') {
            continue;
          }

          produtosDisponiveis.add({
            'nome': data['nome'] ?? 'Sem nome',
            'descricao': data['descricao'] ?? '',
            'imagem': data['imagemUrl'] ?? '',
            'tags': tags,
            'tipo': data['tipo'] ?? 'garcom',
            'preco': data['preco'] ?? 0,
          });
        }
      }

      setState(() {
        produtos = produtosDisponiveis;
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
          (produto['nome'] ?? '')
              .toString()
              .toLowerCase()
              .contains(searchText.toLowerCase());

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
            // =======================================
            // 🏷️ TAGS (logo abaixo da barra de pesquisa)
            // =======================================
            if (filtros.isNotEmpty)
              SizedBox(
                height: 56,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  scrollDirection: Axis.horizontal,
                  itemCount: filtros.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final texto = filtros[index];
                    return _buildFiltro(texto);
                  },
                ),
              )
            else
              const SizedBox(height: 8),

            // =======================================
            // ⚠️ Mensagem se restaurante estiver fechado
            // =======================================
            if (!restauranteAberto)
              Container(
                color: Colors.red.shade50,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                child: const Text(
                  '🍽️ O restaurante está encerrando. Por favor, pague a sua conta e volte outro dia :).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.w600),
                ),
              ),

            // Mensagem da cozinha (se restaurante aberto)
            if (restauranteAberto && !cozinhaAberta)
              Container(
                color: Colors.orange.shade50,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                child: const Text(
                  '🍳 A cozinha está encerrada. Apenas produtos do garçom estão disponíveis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.orangeAccent, fontWeight: FontWeight.w600),
                ),
              ),

            // Lista de produtos (apenas se restaurante aberto)
            if (restauranteAberto)
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
                          setState(() {});
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
              )
            else
              const Expanded(
                child: Center(
                  child: Text(
                    "O cardápio está indisponível no momento.",
                    style: TextStyle(
                        fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
          ],
        ),
      ),

      // Barra inferior (pedido aberto)
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (order.items.isNotEmpty)
            Container(
              color: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        MaterialPageRoute(
                            builder: (_) => const PaginaPedidos()),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      onPressed: () {
        setState(() {
          filtroAtivo = ativo ? '' : texto;
        });
      },
      child: Text(
        texto,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
