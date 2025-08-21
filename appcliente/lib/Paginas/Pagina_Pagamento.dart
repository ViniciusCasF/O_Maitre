import 'package:flutter/material.dart';

class PaginaPagamento extends StatefulWidget {
  const PaginaPagamento({super.key});

  @override
  State<PaginaPagamento> createState() => _PaginaPagamento();
}

class _PaginaPagamento extends State<PaginaPagamento> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: Text ('Aqui voce coloca a api do banco para gerar o qr code e realizar o pagamento da conta'),
      ),
    );
  }

}