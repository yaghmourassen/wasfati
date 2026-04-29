import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/user_session.dart';
import '../model/shopping_plan_model.dart';

class ShoppingPlanController extends ChangeNotifier {
  final List<ShoppingItem> _items = [];

  List<ShoppingItem> get items => _items; // ✅ REQUIRED (missing in your code)

  void addItem(String name) {
    if (name.trim().isEmpty) return;

    _items.add(
      ShoppingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.trim(),
        isDone: false,
      ),
    );

    notifyListeners();
  }

  void deleteItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void toggleItem(String id) {
    final index = _items.indexWhere((item) => item.id == id);

    if (index != -1) {
      _items[index].isDone = !_items[index].isDone;
      notifyListeners();
    }
  }

  void clearAll() {
    _items.clear();
    notifyListeners();
  }
}

class ShoppingItem {
  final String id;
  final String name;
  bool isDone;

  ShoppingItem({
    required this.id,
    required this.name,
    this.isDone = false,
  });
}