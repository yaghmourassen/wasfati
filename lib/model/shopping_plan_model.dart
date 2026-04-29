class ShoppingItem {
  final String id;
  final String name;
  final bool isDone;

  ShoppingItem({
    required this.id,
    required this.name,
    this.isDone = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isDone': isDone,
    };
  }

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'],
      name: map['name'],
      isDone: map['isDone'] ?? false,
    );
  }
}