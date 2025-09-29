import 'package:flutter/material.dart';

class MenuWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelectPage;

  const MenuWidget({
    super.key,
    required this.selectedIndex,
    required this.onSelectPage,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              "Menu do Proprietário",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Tela de Teste"),
            selected: selectedIndex == 0,
            onTap: () => onSelectPage(0), // chama a função passando o índice
          ),
          ListTile(
            leading: const Icon(Icons.table_bar),
            title: const Text("Mesas & Garçons"),
            selected: selectedIndex == 1,
            onTap: () => onSelectPage(1), // chama a função passando o índice
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text("Estoque"),
            selected: selectedIndex == 2,
            onTap: () => onSelectPage(2),
          ),
        ],
      ),
    );
  }
}
