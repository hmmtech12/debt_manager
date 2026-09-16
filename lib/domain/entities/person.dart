class Person {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? notes;

  const Person({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.notes,
  });

  Person copyWith({String? name, String? phone, String? email, String? notes}) {
    return Person(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'notes': notes,
      };

  factory Person.fromMap(Map<String, dynamic> map) => Person(
        id: map['id'] as String,
        name: map['name'] as String,
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        notes: map['notes'] as String?,
      );
}
