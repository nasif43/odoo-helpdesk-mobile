class User {
  final int id;
  final int? employeeId;
  final String name;
  final String email;
  final String role; // 'customer' or 'admin'
  final int partnerId;
  final String language;

  const User({
    required this.id,
    this.employeeId,
    required this.name,
    required this.email,
    required this.role,
    required this.partnerId,
    this.language = 'en_US',
  });

  bool get isAdmin => role == 'admin';
  bool get isCustomer => role == 'customer';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      employeeId: json['employee_id'] as int?,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'customer',
      partnerId: json['partner_id'] as int? ?? 0,
      language: json['language'] as String? ?? 'en_US',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'employee_id': employeeId,
    'name': name,
    'email': email,
    'role': role,
    'partner_id': partnerId,
    'language': language,
  };
}
