import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'Pagina_Pagamento_Aprovado.dart';

class PaginaPagamento extends StatefulWidget {
  final int numeroMesa;
  final double total;
  final String qrCodeBase64;
  final String copiaECola;
  final String idPagamento;

  const PaginaPagamento({
    Key? key,
    required this.numeroMesa,
    required this.total,
    required this.qrCodeBase64,
    required this.copiaECola,
    required this.idPagamento,
  }) : super(key: key);

  @override
  State<PaginaPagamento> createState() => _PaginaPagamentoState();
}

class _PaginaPagamentoState extends State<PaginaPagamento> {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    iniciarMonitoramento();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  /// 🔵 Inicia a verificação automática do pagamento a cada 5 segundos
  void iniciarMonitoramento() {
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      verificarStatusPagamento();
    });
  }

  /// 🔵 Consulta Firebase Functions: /status?id=XYZ
  Future<void> verificarStatusPagamento() async {
    final url = Uri.parse(
      "https://us-central1-o-maitre.cloudfunctions.net/api/status?id=${widget.idPagamento}",
    );

    try {
      final resp = await http.get(url);

      if (resp.statusCode != 200) return;

      final data = jsonDecode(resp.body);
      final status = data["status"];

      if (status == "approved") {
        timer?.cancel();

        await liberarMesaFirestore();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaginaPagamentoAprovado(
              numeroMesa: widget.numeroMesa,
            ),
          ),
        );
      }
    } catch (_) {}
  }

  /// 🔵 Atualiza Firestore marcando a mesa como paga
  Future<void> liberarMesaFirestore() async {
    final db = FirebaseFirestore.instance;

    await db
        .collection("contas")
        .doc("mesa_${widget.numeroMesa}")
        .update({
      "status_pagamento": "aprovado",
      "status": "fechada",
      "lastActivity": FieldValue.serverTimestamp(),
    });
  }


  @override
  Widget build(BuildContext context) {
    final qrBytes = base64Decode(widget.qrCodeBase64);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pagamento PIX"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🔵 Informações da Mesa
            Text(
              "Mesa ${widget.numeroMesa}",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            Text(
              "Total: R\$ ${widget.total.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            // 🔵 QR CODE
            const Text("Escaneie o QR Code:", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 10),

            Image.memory(qrBytes, width: 250, height: 250),

            const SizedBox(height: 30),

            // 🔵 Código PIX com botão copiar
            const Text(
              "Código PIX (Copia e Cola):",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 10),

            _widgetCodigoPix(),

            const SizedBox(height: 20),

            const Text(
              "Aguardando pagamento...",
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔵 Widget completo do código oculto + botão copiar
  Widget _widgetCodigoPix() {
    final codigo = widget.copiaECola;

    if (codigo.length < 20) {
      return Text("Código inválido");
    }

    final inicio = codigo.substring(0, 12);
    final fim = codigo.substring(codigo.length - 6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
        color: Colors.grey.shade100,
      ),
      child: Row(
        children: [
          // 🔵 Código parcial exibido
          Expanded(
            child: Text(
              "$inicio...$fim",
              style: const TextStyle(fontSize: 14, letterSpacing: 1),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 10),

          // 🔵 Botão copiar
          IconButton(
            icon: const Icon(Icons.copy, color: Colors.blue),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: codigo));

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Código PIX copiado!"),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
