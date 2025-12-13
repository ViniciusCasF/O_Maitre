import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TelaDashboard extends StatefulWidget {
  const TelaDashboard({super.key});

  @override
  State<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends State<TelaDashboard> {
  String _periodoSelecionado = "Dia";

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Converte qualquer numérico para double, evitando crash com int/null
  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return 0;
  }

  /// Define o início do período baseado no filtro selecionado
  DateTime _inicioPeriodo() {
    final agora = DateTime.now();

    switch (_periodoSelecionado) {
      case "Dia":
      // Início do dia atual
        return DateTime(agora.year, agora.month, agora.day);
      case "Semana":
      // Últimos 7 dias
        return agora.subtract(const Duration(days: 7));
      case "Mês":
      // Início do mês atual
        return DateTime(agora.year, agora.month, 1);
      case "Ano":
      // Início do ano atual
        return DateTime(agora.year, 1, 1);
      default:
        return DateTime(agora.year, agora.month, agora.day);
    }
  }

  /// Stream de contas históricas filtradas por data e status = "paga"
  Stream<QuerySnapshot> _streamHistorico() {
    final inicio = _inicioPeriodo();

    return _db
        .collection('historico_contas')
        .where(
      'timestamp_fechamento',
      isGreaterThanOrEqualTo: Timestamp.fromDate(inicio),
    )
        .snapshots();
  }



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
    return Scaffold(
      appBar: AppBar(title: const Text("Painel do Proprietário")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            /// 🔥 STREAM BUILDER COM OS DOIS ESTADOS (restaurante/cozinha)
            StreamBuilder<QuerySnapshot>(
              stream: _db.collection('estados').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text("Erro ao carregar estados");
                }
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

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
                const Text(
                  "Filtrar por:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
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

            /// 🔢 STREAM DOS DADOS FINANCEIROS (historico_contas)
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _streamHistorico(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                      child: Text("Erro ao carregar dados financeiros"),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;

                  double totalRecebido = 0;
                  double totalInsumos = 0;
                  double totalLucro = 0;

                  for (final doc in docs) {
                    final data = doc.data() as Map<String, dynamic>?;

                    if (data == null) continue; // evita erro


                    totalRecebido += _toDouble(data['totalVenda']);
                    totalInsumos += _toDouble(data['custoTotal']);
                    totalLucro += _toDouble(data['lucro']);
                  }

                  // Se quiser, pode calcular rendaBruta = totalRecebido - totalInsumos
                  // em vez de somar o campo 'lucro'
                  // final rendaBruta = totalRecebido - totalInsumos;
                  final rendaBruta = totalLucro;

                  return GridView.count(
                    crossAxisCount:
                    MediaQuery.of(context).size.width > 600 ? 3 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildCard(
                        titulo: "Total Recebido",
                        valor: "R\$ ${totalRecebido.toStringAsFixed(2)}",
                        cor1: Colors.green.shade400,
                        cor2: Colors.green.shade700,
                        icone: Icons.attach_money,
                      ),
                      _buildCard(
                        titulo: "Gastos com Insumos",
                        valor: "R\$ ${totalInsumos.toStringAsFixed(2)}",
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
                  );
                },
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
