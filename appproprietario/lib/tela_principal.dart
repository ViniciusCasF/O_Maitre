import 'package:flutter/material.dart';

class TelaDashboard extends StatefulWidget {
  const TelaDashboard({super.key});

  @override
  State<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends State<TelaDashboard> {
  bool _restauranteAberto = true;
  bool _cozinhaAberta = true;
  String _periodoSelecionado = "Dia";

  // Mock de valores
  final Map<String, Map<String, double>> _dados = {
    "Dia": {"recebido": 1200, "insumos": 400},
    "Semana": {"recebido": 8200, "insumos": 2500},
    "Mês": {"recebido": 32000, "insumos": 11000},
    "Ano": {"recebido": 380000, "insumos": 135000},
  };

  @override
  Widget build(BuildContext context) {
    final recebido = _dados[_periodoSelecionado]!["recebido"]!;
    final insumos = _dados[_periodoSelecionado]!["insumos"]!;
    final rendaBruta = recebido - insumos;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Painel do Proprietário"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Switches do topo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text("Fechar o restaurante"),
                    Switch(
                      value: _restauranteAberto,
                      onChanged: (v) {
                        setState(() => _restauranteAberto = v);
                      },
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text("Encerrar a cozinha"),
                    Switch(
                      value: _cozinhaAberta,
                      onChanged: (v) {
                        setState(() => _cozinhaAberta = v);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filtro de período centralizado
            Column(
              children: [
                const Text(
                  "Filtrar por:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: _periodoSelecionado,
                  alignment: Alignment.center,
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

            // Cards estilo PowerBI
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
