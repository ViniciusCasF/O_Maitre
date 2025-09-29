import 'package:flutter/material.dart';
import 'menu.dart';
import 'tela_principal.dart';
import 'tela_mesas_garcons.dart';
import 'tela_estoque.dart';

class ProprietarioScreen extends StatefulWidget {
  const ProprietarioScreen({super.key});

  @override
  State<ProprietarioScreen> createState() => _ProprietarioScreenState();
}

class _ProprietarioScreenState extends State<ProprietarioScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    TelaDashboard(),        // index 0
    TelaMesasGarcons(), // index 1
    TelaEstoque(), // index 2
  ];

  void _onSelectPage(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Painel do Proprietário")),
      drawer: MenuWidget(
        selectedIndex: _selectedIndex,
        onSelectPage: _onSelectPage,
      ),
      body: _pages[_selectedIndex],
    );
  }
}
