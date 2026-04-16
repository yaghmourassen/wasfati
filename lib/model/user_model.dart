class UserModel {
  String? id;
  String name;
  String email;
  String? profileImageUrl;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
  });

  // Convert UserModel to Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'profileImageUrl': profileImageUrl,
    };
  }

  // Convert Map to UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      name: map['name'],
      email: map['email'],
      profileImageUrl: map['profileImageUrl'],
    );
  }
}
