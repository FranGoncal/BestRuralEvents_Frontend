class PaymentMethod {
  final String id;
  final String cardName;
  final String cardNumberMasked;
  final String brand;
  final int expiryMonth;
  final int expiryYear;
  final String cvv;
  final bool isDefault;

  const PaymentMethod({
    required this.id,
    required this.cardName,
    required this.cardNumberMasked,
    required this.brand,
    required this.expiryMonth,
    required this.expiryYear,
    required this.cvv,
    this.isDefault = false,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      cardName: json['cardName'] as String,
      cardNumberMasked: json['cardNumberMasked'] as String,
      brand: json['brand'] as String,
      expiryMonth: json['expiryMonth'] as int,
      expiryYear: json['expiryYear'] as int,
      cvv: json['cvv'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardName': cardName,
      'cardNumberMasked': cardNumberMasked,
      'brand': brand,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'cvv': cvv,
      'isDefault': isDefault,
    };
  }

  String get expiryLabel =>
      '${expiryMonth.toString().padLeft(2, '0')}/${(expiryYear % 100).toString().padLeft(2, '0')}';
}