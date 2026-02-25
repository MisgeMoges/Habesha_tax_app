class TransactionCategory {
  final String id;
  final String name;

  TransactionCategory({required this.id, required this.name});

  factory TransactionCategory.fromJson(Map<String, dynamic> json) {
    return TransactionCategory(
      id: json['id'] ?? json['name'] ?? '',
      name: json['name'] ?? json['category_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
