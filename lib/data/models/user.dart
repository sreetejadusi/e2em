class User {
  String name;
  String phone;
  DateTime validTill;
  DateTime createdAt;

  User({
    required this.name,
    required this.phone,
    required this.validTill,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
        name: json['name'],
        phone: json['phone'],
        validTill: json['validTill'],
        createdAt: json['createdAt']);
  }

  Map<String, dynamic> toJson(User user) {
    return {
      'name': user.name,
      'phone': user.phone,
      'validTill': user.validTill,
      'createdAt': user.createdAt,
    };
  }
}
