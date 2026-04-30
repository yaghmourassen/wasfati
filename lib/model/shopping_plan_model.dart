class ShoppingItem {
  final String id;
  final String userId; // ✅ IMPORTANT: link to owner
  final String name;
  final bool isDone;

  ShoppingItem({
    required this.id,
    required this.userId,
    required this.name,
    this.isDone = false,
  });

  ShoppingItem copyWith({
    String? id,
    String? userId,
    String? name,
    bool? isDone,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId, // ✅ add this for DB
      'name': name,
      'isDone': isDone,
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '', // ✅ important
      name: map['name'] ?? '',
      isDone: map['isDone'] ?? false,
    );
  }
}