
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/user_session.dart';
import '../model/shopping_plan_model.dart';
import '../services/shopping_plan_service.dart';
import '../services/notification_service.dart';

class ShoppingPlanController extends ChangeNotifier {
final ShoppingPlanService _service = ShoppingPlanService();
final NotificationService _notificationService = NotificationService();

late final Future<void> _notificationInitialization =
_notificationService.initNotification();

final List<ShoppingItem> _items = [];

List<ShoppingItem> get items =>
_items.where((i) => i.userId == UserSession.userId).toList();

ShoppingPlanController() {
_notificationInitialization;
}

// ================= LOAD FROM DB =================
void listenToUserItems() {
final userId = UserSession.userId;
if (userId == null) return;

_service.getUserItems(userId).listen((snapshot) {
_items.clear();

for (var doc in snapshot.docs) {
final data = doc.data() as Map<String, dynamic>;

_items.add(
ShoppingItem.fromMap(data),
);
}

notifyListeners();
});
}

// ================= ADD ITEM WITH REMINDER =================
Future<void> addItem(String name, {DateTime? reminderTime}) async {
if (name.trim().isEmpty) return;

final userId = UserSession.userId!;
final int notificationId =
DateTime.now().millisecondsSinceEpoch ~/ 1000;
final id = notificationId.toString();

final newItem = ShoppingItem(
id: id,
userId: userId,
name: name.trim(),
isDone: false,
reminderTime: reminderTime,
);

final itemMap = newItem.toMap();
itemMap['createdAt'] = FieldValue.serverTimestamp();

await _service.addItem(itemMap);

// Schedule notification if a future reminder time was selected.
if (reminderTime != null &&
reminderTime.isAfter(DateTime.now())) {
await _notificationInitialization;

await _notificationService.scheduleNotification(
id: notificationId,
title: 'تذكير خطة الطبخ 🍳',
body: 'موعد العنصر: ${name.trim()}',
scheduledTime: reminderTime,
);
}
}

// ================= DELETE =================
Future<void> deleteItem(String id) async {
await _service.deleteItem(id);

// Cancel the associated notification when deleting the item.
final intId = int.tryParse(id);
if (intId != null) {
await _notificationService.cancelNotification(intId);
}
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