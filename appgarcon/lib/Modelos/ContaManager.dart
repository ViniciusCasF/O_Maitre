import 'package:cloud_firestore/cloud_firestore.dart';

class ContaManager {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Abre (ou cria) uma conta para a mesa (mesa_{numeroMesa})
  Future<DocumentReference<Map<String, dynamic>>> abrirOuCriarConta(
      int numeroMesa) async {
    final contaRef = _db.collection('contas').doc('mesa_$numeroMesa');
    final snap = await contaRef.get();

    if (snap.exists) {
      final data = snap.data()!;
      if (data['status'] == 'aberta') return contaRef;
    }

    await contaRef.set({
      'mesaNumero': numeroMesa,
      'status': 'aberta', // aberta | paga | fechada
      'pedidos': <String>[],
      'total': 0.0,       // total de vendas
      'custoTotal': 0.0,  // 🔥 custo de insumos
      'startTime': FieldValue.serverTimestamp(),
    });

    return contaRef;
  }

  /// Vincula um pedido à conta e atualiza total e custo
  Future<void> adicionarPedido(
      int numeroMesa,
      String pedidoId,
      double precoVenda, {
        double custoInsumos = 0.0,
      }) async {
    final contaRef = _db.collection('contas').doc('mesa_$numeroMesa');

    await _db.runTransaction((tx) async {
      final snap = await tx.get(contaRef);
      if (!snap.exists) return;

      final data = snap.data()!;

      final pedidos = List<String>.from(data['pedidos'] ?? []);
      pedidos.add(pedidoId);

      final double novoTotal =
          (data['total'] ?? 0.0) + precoVenda;
      final double novoCusto =
          (data['custoTotal'] ?? 0.0) + custoInsumos;

      tx.update(contaRef, {
        'pedidos': pedidos,
        'total': novoTotal,
        'custoTotal': novoCusto, // 🔥 aqui entra o custo
        'status': 'aberta',
        'lastActivity': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Paga e arquiva a conta
  Future<void> pagarConta({
    required int numeroMesa,
    required double valorPago,
  }) async {
    final contaRef = _db.collection('contas').doc('mesa_$numeroMesa');
    final archiveRef = _db.collection('contas_archive').doc();

    await _db.runTransaction((tx) async {
      final snap = await tx.get(contaRef);
      if (!snap.exists) {
        throw Exception('Conta da mesa $numeroMesa não encontrada.');
      }

      final data = Map<String, dynamic>.from(snap.data()!);

      final pedidos = List<String>.from(data['pedidos'] ?? []);
      final totalAtual = (data['total'] ?? 0.0);
      final custoAtual = (data['custoTotal'] ?? 0.0);

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
        'custoTotal': custoAtual,
        'valorPago': valorPago,
        'status': 'paga',
        'archivedAt': FieldValue.serverTimestamp(),
      });
    });

    // Arquiva pedidos
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

    // Reseta conta ativa
    await contaRef.set({
      'mesaNumero': numeroMesa,
      'status': 'fechada',
      'pedidos': <String>[],
      'total': 0.0,
      'custoTotal': 0.0,
      'resetAt': FieldValue.serverTimestamp(),
    });
  }
}
