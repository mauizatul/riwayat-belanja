class Merchant {
  final int id;
  final String name;
  final DateTime? createdAt;

  Merchant({required this.id, required this.name, this.createdAt});

  factory Merchant.fromJson(Map<String, dynamic> json) {
    return Merchant(
      id: json['id'] as int,
      name: json['name'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() => {'name': name};
}
