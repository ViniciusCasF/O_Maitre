import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaDashboard extends StatefulWidget {
  const TelaDashboard({super.key});

  @override
  State<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends State<TelaDashboard> {
  String _periodoSelecionado = "Dia";

  final Map<String, Map<String, double>> _dados = {
    "Dia": {"recebido": 1200, "insumos": 400},
    "Semana": {"recebido": 8200, "insumos": 2500},
    "Mês": {"recebido": 32000, "insumos": 11000},
    "Ano": {"recebido": 380000, "insumos": 135000},
  };

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Atualiza o estado da cozinha
  Future<void> _atualizarEstadoCozinha(bool aberta) async {
    await _db.collection('estados').doc('cozinha').set({
      'aberta': aberta,
      'atualizadoPor': 'proprietario',
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Atualiza o estado do restaurante
  Future<void> _atualizarEstadoRestaurante(bool aberto) async {
    await _db.collection('estados').doc('restaurante').set({
      'aberto': aberto,
      'atualizadoPor': 'proprietario',
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final recebido = _dados[_periodoSelecionado]!["recebido"]!;
    final insumos = _dados[_periodoSelecionado]!["insumos"]!;
    final rendaBruta = recebido - insumos;

    return Scaffold(
      appBar: AppBar(title: const Text("Painel do Proprietário")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            /// 🔥 STREAM BUILDER COM OS DOIS ESTADOS
            StreamBuilder<QuerySnapshot>(
              stream: _db.collection('estados').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text("Erro ao carregar estados");
                }
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                // Pega os documentos
                final docs = snapshot.data!.docs;
                final cozinhaDoc = docs.where((d) => d.id == 'cozinha').isNotEmpty
                    ? docs.firstWhere((d) => d.id == 'cozinha')
                    : null;

                final restauranteDoc = docs.where((d) => d.id == 'restaurante').isNotEmpty
                    ? docs.firstWhere((d) => d.id == 'restaurante')
                    : null;

                final cozinhaData = cozinhaDoc?.data() as Map<String, dynamic>?;
                final restauranteData = restauranteDoc?.data() as Map<String, dynamic>?;


                final cozinhaAberta = cozinhaData?['aberta'] ?? false;
                final restauranteAberto = restauranteData?['aberto'] ?? false;

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // 🔷 Controle do restaurante
                        Column(
                          children: [
                            const Text("Abrir/Fechar Restaurante"),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Switch(
                                  value: restauranteAberto,
                                  onChanged: (v) => _atualizarEstadoRestaurante(v),
                                ),
                                Text(
                                  restauranteAberto ? "Aberto" : "Fechado",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: restauranteAberto ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // 🔶 Controle da cozinha
                        Column(
                          children: [
                            const Text("Encerrar Cozinha"),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Switch(
                                  value: cozinhaAberta,
                                  onChanged: (v) => _atualizarEstadoCozinha(v),
                                ),
                                Text(
                                  cozinhaAberta ? "Aberta" : "Fechada",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: cozinhaAberta ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );

              },
            ),

            const SizedBox(height: 20),

            // Filtro de período
            Column(
              children: [
                const Text("Filtrar por:",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _periodoSelecionado,
                  items: const [
                    DropdownMenuItem(value: "Dia", child: Text("Dia")),
                    DropdownMenuItem(value: "Semana", child: Text("Semana")),
                    DropdownMenuItem(value: "Mês", child: Text("Mês")),
                    DropdownMenuItem(value: "Ano", child: Text("Ano")),
                  ],
                  onChanged: (value) {
                    setState(() => _periodoSelecionado = value!);
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Cards de resumo
            Expanded(
              child: GridView.count(
                crossAxisCount:
                MediaQuery.of(context).size.width > 600 ? 3 : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildCard(
                    titulo: "Total Recebido",
                    valor: "R\$ ${recebido.toStringAsFixed(2)}",
                    cor1: Colors.green.shade400,
                    cor2: Colors.green.shade700,
                    icone: Icons.attach_money,
                  ),
                  _buildCard(
                    titulo: "Gastos com Insumos",
                    valor: "R\$ ${insumos.toStringAsFixed(2)}",
                    cor1: Colors.red.shade400,
                    cor2: Colors.red.shade700,
                    icone: Icons.shopping_cart,
                  ),
                  _buildCard(
                    titulo: "Renda Bruta",
                    valor: "R\$ ${rendaBruta.toStringAsFixed(2)}",
                    cor1: Colors.blue.shade400,
                    cor2: Colors.blue.shade700,
                    icone: Icons.bar_chart,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required String titulo,
    required String valor,
    required Color cor1,
    required Color cor2,
    required IconData icone,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [cor1, cor2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                titulo,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
