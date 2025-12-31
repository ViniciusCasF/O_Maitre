// lib/Modelos/order_manager.dart
import 'Itens.dart';

class OrderManager {
  OrderManager._internal();
  static final OrderManager _instance = OrderManager._internal();
  factory OrderManager() => _instance;

  final List<Item> _items = [];

  List<Item> get items => List.unmodifiable(_items);

  void addItem(Item item) {
    _items.add(item);
  }

  void removeAt(int index) {
    _items.removeAt(index);
  }

  void clear() {
    _items.clear();
  }

  int get count => _items.length;
}
