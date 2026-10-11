class ShoppingItem {
  final String id;
  final String userId; // ✅ IMPORTANT: link to owner
  final String name;
  final bool isDone;
  final DateTime? reminderTime; // ✅ حقل وقت التذكير الجديد

  ShoppingItem({
    required this.id,
    required this.userId,
    required this.name,
    this.isDone = false,
    this.reminderTime,
  });

  ShoppingItem copyWith({
    String? id,
    String? userId,
    String? name,
    bool? isDone,
    DateTime? reminderTime,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      isDone: isDone ?? this.isDone,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId, // ✅ add this for DB
      'name': name,
      'isDone': isDone,
      'reminderTime': reminderTime?.toIso8601String(), // ✅ تخزين وقت التذكير كـ String
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '', // ✅ important
      name: map['name'] ?? '',
      isDone: map['isDone'] ?? false,
      reminderTime: map['reminderTime'] != null
          ? DateTime.tryParse(map['reminderTime'])
          : null, // ✅ قراءة وقت التذكير من قاعدة البيانات
    );
  }
}