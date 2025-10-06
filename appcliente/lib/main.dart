// main.dart
/*
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
      title: 'App Cliente',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        canvasColor: const Color.fromARGB(255, 232, 232, 232),
      ),
      home: const MyHomePage(),
    );
  }
}

*/

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enviar dado simples de teste
  await FirebaseFirestore.instance.collection('logs_teste').add({
    'mensagem': 'Teste de envio',
    'data': DateTime.now(),
  });
  print('Dado enviado para o Firebase!');

  runApp(const AppCliente());
}

class AppCliente extends StatelessWidget {
  const AppCliente({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('App rodando!')),
      ),
    );
  }
}
