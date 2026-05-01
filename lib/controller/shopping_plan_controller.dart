import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/user_session.dart';
import '../model/shopping_plan_model.dart';
import '../services/shopping_plan_service.dart';

class ShoppingPlanController extends ChangeNotifier {
  final ShoppingPlanService _service = ShoppingPlanService();

  final List<ShoppingItem> _items = [];

  List<ShoppingItem> get items =>
      _items.where((i) => i.userId == UserSession.userId).toList();

  // ================= LOAD FROM DB =================
  void listenToUserItems() {
    final userId = UserSession.userId;
    if (userId == null) return;

    _service.getUserItems(userId).listen((snapshot) {
      _items.clear();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        _items.add(
          ShoppingItem(
            id: doc.id,
            userId: data['userId'],
            name: data['name'],
            isDone: data['isDone'] ?? false,
          ),
        );
      }

      notifyListeners();
    });
  }

  // ================= ADD ITEM =================
  Future<void> addItem(String name) async {
    if (name.trim().isEmpty) return;

    final userId = UserSession.userId!;
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    await _service.addItem({
      'id': id,
      'userId': userId,
      'name': name.trim(),
      'isDone': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ================= DELETE =================
  Future<void> deleteItem(String id) async {
    await _service.deleteItem(id);
  }

  // ================= TOGGLE =================
  Future<void> toggleItem(ShoppingItem item) async {
    await _service.toggleItem(item.id, !item.isDone);
  }

  // ================= CLEAR LOCAL ONLY =================
  void clearAllLocal() {
    _items.clear();
    notifyListeners();
  }
}