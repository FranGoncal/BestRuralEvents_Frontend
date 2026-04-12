import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment_method.dart';

class PaymentMethodsStorageService {
  static const String _key = 'saved_payment_methods';

  Future<List<PaymentMethod>> getSavedMethods() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => PaymentMethod.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMethods(List<PaymentMethod> methods) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(methods.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  Future<void> addMethod(PaymentMethod method) async {
    final methods = await getSavedMethods();
    methods.removeWhere((m) => m.id == method.id);

    if (method.isDefault) {
      final normalized = methods
          .map((m) => PaymentMethod(
        id: m.id,
        cardName: m.cardName,
        cardNumberMasked: m.cardNumberMasked,
        brand: m.brand,
        expiryMonth: m.expiryMonth,
        expiryYear: m.expiryYear,
        cvv: m.cvv,
        isDefault: false,
      ))
          .toList();
      normalized.insert(0, method);
      await saveMethods(normalized);
      return;
    }

    methods.add(method);
    await saveMethods(methods);
  }

  Future<void> deleteMethod(String id) async {
    final methods = await getSavedMethods();
    methods.removeWhere((m) => m.id == id);
    await saveMethods(methods);
  }

  Future<void> setDefault(String id) async {
    final methods = await getSavedMethods();
    final updated = methods
        .map((m) => PaymentMethod(
      id: m.id,
      cardName: m.cardName,
      cardNumberMasked: m.cardNumberMasked,
      brand: m.brand,
      expiryMonth: m.expiryMonth,
      expiryYear: m.expiryYear,
      cvv: m.cvv,
      isDefault: m.id == id,
    ))
        .toList();

    await saveMethods(updated);
  }
}