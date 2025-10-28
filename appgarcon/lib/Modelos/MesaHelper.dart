import 'dart:developer';

class MesaHelper {
  /// Lê ?mesa=XX da URL (Flutter Web). Se não existir, usa "1" (modo dev).
  static int detectarMesa() {
    try {
      final s = Uri.base.queryParameters['mesa'];
      if (s != null) return int.tryParse(s) ?? 1;
    } catch (e) {
      log('Erro lendo mesa da URL: $e');
    }
    return 1;
  }
}
