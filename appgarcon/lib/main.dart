// main.dart
import 'package:flutter/material.dart';
import 'Widget/Nav-bar.dart'; // importa o novo arquivo

void main() {
  runApp(const AppCliente());
}

class AppCliente extends StatelessWidget {
  const AppCliente({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Garçon',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        canvasColor: const Color.fromARGB(255, 232, 232, 232),
      ),
      home: const MyHomePage(),
    );
  }
}
