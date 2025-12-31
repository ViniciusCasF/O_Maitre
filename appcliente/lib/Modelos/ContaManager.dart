import 'package:cloud_firestore/cloud_firestore.dart';

class ContaManager {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Abre (ou cria) uma conta para a mesa (mesa_{numeroMesa})
  Future<DocumentReference<Map<String, dynamic>>> abrirOuCriarConta(int numeroMesa) async {
    final contaRef = _db.collection('contas').doc('mesa_$numeroMesa');
    final snap = await contaRef.get();

    if (snap.exists) {
      final data = snap.data()!;
      if (data['status'] == 'aberta') return contaRef;
    }

    await contaRef.set({
      'mesaNumero': numeroMesa,
      'status': 'aberta',            // aberta | paga | fechada
      'pedidos': <String>[],
      'total': 0.0,                  // valor de venda
      'custoTotal': 0.0,             // 🔥 novo campo: custo dos insumos
      'startTime': FieldValue.serverTimestamp(),
    });
    return contaRef;
  }

  /// Vincula um pedido à conta, atualiza total e custo dos insumos
  Future<void> adicionarPedido(
    int numeroMesa,
    String pedidoId,
    double precoVenda, {
    double custoInsumos = 0.0,      // 🔥 novo parâmetro opcional
  }) async {
    final contaRef = _db.collection('contas').doc('mesa_$numeroMesa');

    await _db.runTransaction((tx) async {
      final snap = await tx.get(contaRef);
      if (!snap.exists) return;

      final data = snap.data()!;

      final pedidos = List<String>.from(data['pedidos'] ?? []);
      pedidos.add(pedidoId);

      final double totalAtual = (data['total'] ?? 0.0) + precoVenda;
      final double custoAtual = (data['custoTotal'] ?? 0.0) + custoInsumos;

      tx.update(contaRef, {
        'pedidos': pedidos,
        'total': totalAtual,               // soma do preço de venda
        'custoTotal': custoAtual,          // 🔥 soma do custo dos insumos
        'status': 'aberta',
        'lastActivity': FieldValue.serverTimestamp(),
      });
    });
  }

  /// NÃO alterar a função pagarConta como você pediu.
  Future<void> pagarConta({
    required int numeroMesa,
    required double valorPago,
  }) async {
    final contaRef = _db.collection('contas').doc('mesa_$numeroMesa');
    final archiveRef = _db.collection('contas_archive').doc();

    await _db.runTransaction((tx) async {
      final snap = await tx.get(contaRef);
      if (!snap.exists) throw Exception('Conta da mesa $numeroMesa não encontrada.');

      final data = Map<String, dynamic>.from(snap.data()!);

      final List<String> pedidos = List<String>.from(data['pedidos'] ?? []);
      final double totalAtual = (data['total'] ?? 0.0) * 1.0;

      tx.update(contaRef, {
        'status': 'paga',
        'paidAt': FieldValue.serverTimestamp(),
        'valorPago': valorPago,
      });

      tx.set(archiveRef, {
        'mesaNumero': numeroMesa,
        'contaRef': contaRef.id,
        'pedidos': pedidos,
        'totalAntes': totalAtual,
        'valorPago': valorPago,
        'status': 'paga',
        'archivedAt': FieldValue.serverTimestamp(),
      });
    });

    final contaSnap = await contaRef.get();
    final pedidos = List<String>.from(contaSnap.data()?['pedidos'] ?? []);

    for (final id in pedidos) {
      try {
        await _db.collection('pedidos').doc(id).update({
          'status': -1,
          'archivedAt': FieldValue.serverTimestamp(),
          'contaArchiveId': archiveRef.id,
        });
      } catch (_) {}
    }

    await contaRef.set({
      'mesaNumero': numeroMesa,
      'status': 'fechada',
      'pedidos': <String>[],
      'total': 0.0,
      'custoTotal': 0.0,           // 🔥 resetar custo também
      'resetAt': FieldValue.serverTimestamp(),
    });
  }
}
