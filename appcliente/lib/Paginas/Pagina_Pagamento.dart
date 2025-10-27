import 'package:flutter/material.dart';
import '../Modelos/ContaManager.dart';

class PaginaPagamento extends StatefulWidget {
  final int numeroMesa;
  final double total;

  const PaginaPagamento({
    Key? key,
    required this.numeroMesa,
    required this.total,
  }) : super(key: key);

  @override
  State<PaginaPagamento> createState() => _PaginaPagamentoState();
}

class _PaginaPagamentoState extends State<PaginaPagamento> {
  final contaManager = ContaManager();
  bool processando = false;
  bool concluido = false;

  Future<void> _confirmarPagamento() async {
    setState(() => processando = true);

    try {
      // Simula o processamento do pagamento (ex: PIX, cartão, etc.)
      await Future.delayed(const Duration(seconds: 2));

      // ✅ Marca a conta como paga sem excluir pedidos, registra valorPago e reseta conta ativa
      await contaManager.pagarConta(
        numeroMesa: widget.numeroMesa,
        valorPago: widget.total,
      );

      setState(() {
        processando = false;
        concluido = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha no pagamento: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() => processando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (concluido) {
      // ✅ Tela final de sucesso
      return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 100),
                  const SizedBox(height: 20),
                  const Text(
                    'Pagamento realizado com sucesso!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Mesa ${widget.numeroMesa}',
                    style: const TextStyle(fontSize: 18, color: Colors.black54, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Sua saída está liberada.\nObrigado pela visita!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF448AFF),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.home, color: Colors.white),
                    label: const Text('Voltar ao cardápio',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 💳 Tela normal de pagamento
    return Scaffold(
      appBar: AppBar(
        title: Text('Pagamento — Mesa ${widget.numeroMesa}'),
        backgroundColor: const Color(0xFF448AFF),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text('Total a pagar', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'R\$ ${widget.total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 32),
            const Text(
              'Escolha sua forma de pagamento (simulação)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Column(
                children: [
                  _botaoPagamento('Pagar com PIX', Icons.pix_rounded),
                  const SizedBox(height: 12),
                  _botaoPagamento('Cartão de crédito', Icons.credit_card),
                  const SizedBox(height: 12),
                  _botaoPagamento('Cartão de débito', Icons.credit_score_rounded),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: processando ? null : _confirmarPagamento,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF448AFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: processando
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirmar pagamento',
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _botaoPagamento(String texto, IconData icone) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade100,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icone, color: const Color(0xFF448AFF)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(texto, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
          ),
          const Icon(Icons.check_circle, color: Colors.grey),
        ],
      ),
    );
  }
}
