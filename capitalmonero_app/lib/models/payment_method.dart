class PaymentMethod {
  final int id;
  final String name;
  final String slug;
  final String? category;
  final int sortOrder;
  final bool isActive;

  const PaymentMethod({
    required this.id,
    required this.name,
    required this.slug,
    this.category,
    required this.sortOrder,
    required this.isActive,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      category: json['category'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'category': category,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  PaymentMethod copyWith({
    int? id,
    String? name,
    String? slug,
    String? category,
    int? sortOrder,
    bool? isActive,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      category: category ?? this.category,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentMethod &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PaymentMethod(id: $id, name: $name, slug: $slug)';
}
