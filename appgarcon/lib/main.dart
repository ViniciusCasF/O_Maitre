import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'Widget/Nav-bar.dart'; // importa o novo arquivo

Future<void> main() async {
  // Garante que o Firebase seja inicializado antes de rodar o app
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // (opcional) Enviar dado de teste ao iniciar
  /*
  final db = FirebaseDatabase.instance.ref();
  await db.child('logs_teste').push().set({
    'mensagem': 'Teste de envio',
    'data': DateTime.now().toIso8601String(),
  });
  print('Dado enviado para o Firebase!');
  */

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