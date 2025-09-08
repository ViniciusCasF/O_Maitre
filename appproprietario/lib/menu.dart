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
            child: Text("Menu", style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text("CRUD"),
            selected: selectedIndex == 0,
            onTap: () => onSelectPage(0),
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text("Relatórios"),
            selected: selectedIndex == 1,
            onTap: () => onSelectPage(1),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text("Configurações"),
            selected: selectedIndex == 2,
            onTap: () => onSelectPage(2),
          ),
        ],
      ),
    );
  }
}
