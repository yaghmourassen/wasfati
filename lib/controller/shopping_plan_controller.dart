import 'package:flutter/material.dart';
import '../core/user_session.dart';
import '../model/shopping_plan_model.dart';

class ShoppingPlanController extends ChangeNotifier {
  final List<ShoppingItem> _items = [];

  // ✅ only current user items
  List<ShoppingItem> get items =>
      _items.where((i) => i.userId == UserSession.userId).toList();

  // ================= ADD ITEM =================
  void addItem(String name) {
    if (name.trim().isEmpty) return;

    _items.add(
      ShoppingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: UserSession.userId!, // ✅ IMPORTANT FIX
        name: name.trim(),
        isDone: false,
      ),
    );

    notifyListeners();
  }

  // ================= DELETE ITEM =================
  void deleteItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  // ================= TOGGLE ITEM =================
  void toggleItem(String id) {
    final index = _items.indexWhere((item) => item.id == id);

    if (index != -1) {
      final oldItem = _items[index];

      _items[index] = oldItem.copyWith(
        isDone: !oldItem.isDone,
      );

      notifyListeners();
    }
  }

  // ================= CLEAR ALL (ONLY USER DATA) =================
  void clearAll() {
    _items.removeWhere(
          (item) => item.userId == UserSession.userId,
    );
    notifyListeners();
  }
}