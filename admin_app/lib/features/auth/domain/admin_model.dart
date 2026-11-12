import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model representing an Admin user in the system.
class Admin {
  final String id;
  final String name;
  final String email;
  final String role;

  const Admin({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory Admin.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Admin.fromMap(data, id: doc.id);
  }

  factory Admin.fromMap(Map<String, dynamic> map, {required String id}) {
    return Admin(
      id: id,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'admin',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
    };
  }
}
