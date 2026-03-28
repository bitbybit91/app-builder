class Setting {
  final int id;
  final String key;
  final String? value;
  final String? group;
  final String? label;
  final String? type;

  const Setting({
    required this.id,
    required this.key,
    this.value,
    this.group,
    this.label,
    this.type,
  });

  factory Setting.fromJson(Map<String, dynamic> json) {
    return Setting(
      id: json['id'] as int,
      key: json['key'] as String,
      value: json['value'] as String?,
      group: json['group'] as String?,
      label: json['label'] as String?,
      type: json['type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'value': value,
      'group': group,
      'label': label,
      'type': type,
    };
  }

  Setting copyWith({
    int? id,
    String? key,
    String? value,
    String? group,
    String? label,
    String? type,
  }) {
    return Setting(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
      group: group ?? this.group,
      label: label ?? this.label,
      type: type ?? this.type,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Setting && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Setting(id: $id, key: $key, value: $value)';
}
