import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Pedido {
  final String id;
  final String nomeProduto;
  final int mesa;
  final DateTime startTime;
  final String descricao;
  bool iniciado;
  bool entregue;

  Pedido({
    required this.id,
    required this.nomeProduto,
    required this.mesa,
    required this.startTime,
    this.descricao = "Sem observações",
    this.iniciado = false,
    this.entregue = false,
  });
}

class PaginaPedidosGarcom extends StatefulWidget {
  const PaginaPedidosGarcom({Key? key}) : super(key: key);

  @override
  State<PaginaPedidosGarcom> createState() => _PaginaPedidosGarcomState();
}

class _PaginaPedidosGarcomState extends State<PaginaPedidosGarcom> {
  String? garcomSelecionadoId;
  String? garcomNome;
  Color? garcomCor;
  List<int> mesasDoGarcom = [];
  List<Pedido> pedidos = [];
  StreamSubscription? _pedidoSubscription;
  Timer? _timer; // 👈 Timer para atualizar o relógio

  @override
  void initState() {
    super.initState();
    _carregarGarcomSalvo();

    // Atualiza os timers a cada segundo
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _carregarGarcomSalvo() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('garcomSelecionadoId');
    final nome = prefs.getString('garcomNome');
    final corHex = prefs.getString('garcomCor');

    if (id != null && nome != null && corHex != null) {
      setState(() {
        garcomSelecionadoId = id;
        garcomNome = nome;
        garcomCor = Color(int.parse(corHex.replaceFirst('#', '0xff')));
      });
      _carregarMesasEGatilharPedidos();
    }
  }

  Future<void> _selecionarGarcom() async {
    final snapshot =
    await FirebaseFirestore.instance.collection('garcons').get();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          children: snapshot.docs.map((doc) {
            final nome = doc['nome'];
            final corHex = doc['cor'];
            final cor = Color(int.parse(corHex.replaceFirst('#', '0xff')));

            return ListTile(
              leading: CircleAvatar(backgroundColor: cor),
              title: Text(nome),
              onTap: () async {
                Navigator.pop(context);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('garcomSelecionadoId', doc.id);
                await prefs.setString('garcomNome', nome);
                await prefs.setString('garcomCor', corHex);

                setState(() {
                  garcomSelecionadoId = doc.id;
                  garcomNome = nome;
                  garcomCor = cor;
                });

                _carregarMesasEGatilharPedidos();
              },
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _carregarMesasEGatilharPedidos() async {
    if (garcomSelecionadoId == null) return;

    final mesasSnapshot = await FirebaseFirestore.instance
        .collection('mesas')
        .where('garcomId', isEqualTo: garcomSelecionadoId)
        .get();

    mesasDoGarcom =
        mesasSnapshot.docs.map((doc) => doc['numero'] as int).toList();

    _ouvirPedidos();
  }

  void _ouvirPedidos() {
    _pedidoSubscription?.cancel();
    if (mesasDoGarcom.isEmpty) return;

    _pedidoSubscription = FirebaseFirestore.instance
        .collection('pedidos')
        .where('mesa', whereIn: mesasDoGarcom)
        .where('status', isEqualTo: 1) // 👈 apenas pedidos prontos
        .snapshots()
        .listen((snapshot) {
      setState(() {
        pedidos = snapshot.docs.map((doc) {
          final data = doc.data();
          return Pedido(
            id: doc.id,
            nomeProduto: data['nomeProduto'] ?? 'Sem nome',
            mesa: data['mesa'],
            startTime: (data['startTime'] as Timestamp).toDate(),
            descricao: data['descricao'] ?? '',
          );
        }).toList();
      });
    });
  }

  Future<void> _entregarPedido(Pedido pedido) async {
    await FirebaseFirestore.instance
        .collection('pedidos')
        .doc(pedido.id)
        .update({'status': 0});
  }

  String formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(d.inMinutes)}:${twoDigits(d.inSeconds % 60)}";
  }

  void mostrarDetalhes(Pedido pedido) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatDuration(DateTime.now().difference(pedido.startTime)),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  pedido.nomeProduto,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  pedido.descricao,
                  style: const TextStyle(fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  onPressed: () async {
                    await _entregarPedido(pedido);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Marcar como entregue",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pedidoSubscription?.cancel();
    _timer?.cancel(); // 👈 cancela o timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.of(context).size.width;
    int colunas = largura < 500 ? 2 : (largura < 900 ? 3 : 4);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          children: [
            if (garcomCor != null)
              CircleAvatar(backgroundColor: garcomCor, radius: 10),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                garcomNome != null
                    ? "Garçom: $garcomNome"
                    : "Selecione o garçom",
                style: const TextStyle(fontSize: 18),
              ),
            ),
            TextButton(
              onPressed: _selecionarGarcom,
              child: const Text(
                "Trocar",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      body: garcomSelecionadoId == null
          ? const Center(
        child: Text("Escolha um garçom para visualizar os pedidos."),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: colunas,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.9,
        ),
        itemCount: pedidos.length,
        itemBuilder: (context, index) {
          final pedido = pedidos[index];
          final elapsed = DateTime.now().difference(pedido.startTime);

          return GestureDetector(
            onTap: () => mostrarDetalhes(pedido),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: Colors.green, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formatDuration(elapsed),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          pedido.nomeProduto,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                    Text(
                      "Mesa: ${pedido.mesa}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
