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
      'status': 'aberta',                // aberta | paga | fechada
      'pedidos': <String>[],
      'total': 0.0,
      'startTime': FieldValue.serverTimestamp(),
    });
    return contaRef;
  }

  /// Vincula um pedido à conta e atualiza total (preço unitário)
  Future<void> adicionarPedido(int numeroMesa, String pedidoId, double preco) async {
    final contaRef = _db.collection('contas').doc('mesa_$numeroMesa');
    await _db.runTransaction((tx) async {
      final snap = await tx.get(contaRef);
      if (!snap.exists) return;
      final data = snap.data()!;
      final pedidos = List<String>.from(data['pedidos'] ?? []);
      pedidos.add(pedidoId);
      final novoTotal = (data['total'] ?? 0.0) + (preco);
      tx.update(contaRef, {
        'pedidos': pedidos,
        'total': novoTotal,
        'status': 'aberta',
        'lastActivity': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Paga e reseta a conta:
  /// - NÃO deleta pedidos
  /// - marca pedidos como status = -1 (arquivados) e archivedAt
  /// - cria snapshot em contas_archive com valorPago
  /// - reseta a conta ativa
  Future<void> pagarConta({
    required int numeroMesa,
    required double valorPago,          // total final que o cliente pagou (com taxa de serviço etc.)
  }) async {
    final contaRef = _db.collection('contas').doc('mesa_$numeroMesa');
    final archiveRef = _db.collection('contas_archive').doc(); // id novo

    await _db.runTransaction((tx) async {
      final snap = await tx.get(contaRef);
      if (!snap.exists) {
        throw Exception('Conta da mesa $numeroMesa não encontrada.');
      }

      final data = Map<String, dynamic>.from(snap.data()!);

      final List<String> pedidos = List<String>.from(data['pedidos'] ?? []);
      final double totalAtual = (data['total'] ?? 0.0) * 1.0;

      // Marca conta como paga (rastro no doc atual)
      tx.update(contaRef, {
        'status': 'paga',
        'paidAt': FieldValue.serverTimestamp(),
        'valorPago': valorPago,     // registra no doc atual também
      });

      // Cria snapshot no archive
      tx.set(archiveRef, {
        'mesaNumero': numeroMesa,
        'contaRef': contaRef.id,
        'pedidos': pedidos,
        'totalAntes': totalAtual,
        'valorPago': valorPago,
        'status': 'paga',
        'archivedAt': FieldValue.serverTimestamp(),
      });

      // OBS: não conseguimos fazer update em docs fora desta transação (em alguns cenários web pode falhar),
      // então marcamos para atualizar fora. Alternativa: criar uma subcoleção "pedidos" espelho no archive.
    });

    // Fora da transação, marque todos os pedidos como arquivados (status = -1) e com referência ao archive.
    final contaSnap = await contaRef.get();
    final pedidos = List<String>.from(contaSnap.data()?['pedidos'] ?? []);
    for (final id in pedidos) {
      try {
        await _db.collection('pedidos').doc(id).update({
          'status': -1, // ✅ ARQUIVADO
          'archivedAt': FieldValue.serverTimestamp(),
          // opcional: relacione ao archiveRef.id
          'contaArchiveId': archiveRef.id,
        });
      } catch (_) {}
    }

    // Por fim, reset da conta ativa (sem apagar pedidos)
    await contaRef.set({
      'mesaNumero': numeroMesa,
      'status': 'fechada',
      'pedidos': <String>[],
      'total': 0.0,
      'resetAt': FieldValue.serverTimestamp(),
    });
  }
}
