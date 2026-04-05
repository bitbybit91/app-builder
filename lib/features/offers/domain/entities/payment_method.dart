import 'package:equatable/equatable.dart';

class PaymentMethod extends Equatable {
  final String code;
  final String name;
  final String? description;
  final String? category;

  const PaymentMethod({
    required this.code,
    required this.name,
    this.description,
    this.category,
  });

  @override
  List<Object?> get props => [code, name];
}
