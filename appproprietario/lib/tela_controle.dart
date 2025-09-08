import 'package:flutter/material.dart';
import 'tela_teste.dart';
import 'menu.dart';

class ProprietarioScreen extends StatefulWidget {
  const ProprietarioScreen({super.key});

  @override
  State<ProprietarioScreen> createState() => _ProprietarioScreenState();
}

class _ProprietarioScreenState extends State<ProprietarioScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    telaTeste(),
  ];

  void _onSelectPage(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context); // fecha o Drawer quando um item é clicado
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
