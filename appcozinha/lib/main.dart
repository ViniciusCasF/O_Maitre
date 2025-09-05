import 'package:flutter/material.dart';
import 'KitchenScreen.dart'; // importa a tela que você criou

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cozinha',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const KitchenScreen(), // sua tela inicial
    );
  }
}
