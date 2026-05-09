import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../models/event.dart';
import '../../../../models/payment_method.dart';
import '../../../../services/payment_methods_storage_service.dart';
import '../../../../services/promotion_service.dart';

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.length > 4) {
      digitsOnly = digitsOnly.substring(0, 4);
    }

    String formatted = digitsOnly;
    if (digitsOnly.length >= 3) {
      formatted = '${digitsOnly.substring(0, 2)}/${digitsOnly.substring(2)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PromoteEventPage extends StatefulWidget {
  final Event event;
  final String token;
  final String userId;

  const PromoteEventPage({
    super.key,
    required this.event,
    required this.token,
    required this.userId,
  });

  @override
  State<PromoteEventPage> createState() => _PromoteEventPageState();
}

class _PromoteEventPageState extends State<PromoteEventPage> {
  final PromotionService _promotionService = PromotionService();
  final PaymentMethodsStorageService _paymentMethodsStorageService =
  PaymentMethodsStorageService();

  static const double _promotionPrice = 1.0;
  static const int _promotionDurationDays = 7;

  bool _isSubmitting = false;
  bool _isLoadingPaymentMethods = true;

  List<PaymentMethod> _savedPaymentMethods = [];
  String? _selectedPaymentMethodId;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    final methods = await _paymentMethodsStorageService.getSavedMethods();

    if (!mounted) return;

    setState(() {
      _savedPaymentMethods = methods;
      _selectedPaymentMethodId = methods
          .cast<PaymentMethod?>()
          .firstWhere((m) => m?.isDefault == true, orElse: () => null)
          ?.id ??
          (methods.isNotEmpty ? methods.first.id : null);
      _isLoadingPaymentMethods = false;
    });
  }

  int? _parseExpiryMonth(String value) {
    final cleaned = value.trim();
    final parts = cleaned.split('/');
    if (parts.length != 2) return null;

    final month = int.tryParse(parts[0]);
    if (month == null || month < 1 || month > 12) return null;

    return month;
  }

  int? _parseExpiryYear(String value) {
    final cleaned = value.trim();
    final parts = cleaned.split('/');
    if (parts.length != 2) return null;

    final yy = int.tryParse(parts[1]);
    if (yy == null) return null;

    return 2000 + yy;
  }

  String _detectCardBrand(String number) {
    final normalized = number.replaceAll(' ', '');
    if (normalized.startsWith('4')) return 'Visa';
    if (normalized.startsWith('5')) return 'Mastercard';
    if (normalized.startsWith('34') || normalized.startsWith('37')) {
      return 'American Express';
    }
    return 'Card';
  }

  String _maskCardNumber(String number) {
    final normalized = number.replaceAll(' ', '');
    if (normalized.length < 4) return '****';
    final last4 = normalized.substring(normalized.length - 4);
    return '**** **** **** $last4';
  }

  PaymentMethod? get _selectedPaymentMethod {
    try {
      return _savedPaymentMethods.firstWhere(
            (m) => m.id == _selectedPaymentMethodId,
      );
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$day/$month/$year';
  }

  String _formatPrice(double price) {
    return '€${price.toStringAsFixed(2)}';
  }

  Future<void> _openAddPaymentMethodSheet() async {
    final cardNameController = TextEditingController();
    final cardNumberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();

    final formKey = GlobalKey<FormState>();
    bool saveAsDefault = _savedPaymentMethods.isEmpty;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Add payment method',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: cardNameController,
                        decoration: InputDecoration(
                          labelText: 'Card name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return 'Enter the card name';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: cardNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(19),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Card number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          final normalized = (value ?? '').replaceAll(' ', '');
                          if (normalized.isEmpty) return 'Enter the card number';
                          if (normalized.length < 12) {
                            return 'Invalid card number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: expiryController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                ExpiryDateInputFormatter(),
                              ],
                              decoration: InputDecoration(
                                labelText: 'MM/YY',
                                hintText: '08/27',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                final regex = RegExp(r'^\d{2}/\d{2}$');
                                if (!regex.hasMatch(text)) {
                                  return 'Use MM/YY';
                                }

                                final month = _parseExpiryMonth(text);
                                final year = _parseExpiryYear(text);

                                if (month == null || year == null) {
                                  return 'Invalid date';
                                }

                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: cvvController,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              maxLength: 4,
                              maxLengthEnforcement: MaxLengthEnforcement.enforced,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              decoration: InputDecoration(
                                labelText: 'CVV',
                                hintText: '123',
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                final regex = RegExp(r'^\d{3,4}$');
                                if (!regex.hasMatch(text)) {
                                  return '3 or 4 digits';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        value: saveAsDefault,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Set as default payment method'),
                        onChanged: (value) {
                          setModalState(() {
                            saveAsDefault = value ?? false;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;

                            final cardNumber =
                            cardNumberController.text.trim().replaceAll(' ', '');
                            final expiry = expiryController.text.trim();

                            final month = _parseExpiryMonth(expiry)!;
                            final year = _parseExpiryYear(expiry)!;

                            final method = PaymentMethod(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              cardName: cardNameController.text.trim(),
                              cardNumberMasked: _maskCardNumber(cardNumber),
                              brand: _detectCardBrand(cardNumber),
                              expiryMonth: month,
                              expiryYear: year,
                              cvv: cvvController.text.trim(),
                              isDefault: saveAsDefault,
                            );

                            await _paymentMethodsStorageService.addMethod(method);

                            if (!mounted) return;
                            Navigator.pop(context);
                          },
                          child: const Text('Save payment method'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    await _loadPaymentMethods();
  }

  Future<void> _openManagePaymentMethods() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Manage payment methods',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                if (_savedPaymentMethods.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No saved payment methods yet.'),
                  )
                else
                  ..._savedPaymentMethods.map(
                        (method) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.credit_card),
                      title: Text('${method.brand} • ${method.cardNumberMasked}'),
                      subtitle: Text(
                        '${method.cardName} · Expires ${method.expiryLabel}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'default') {
                            await _paymentMethodsStorageService
                                .setDefault(method.id);
                          } else if (value == 'delete') {
                            await _paymentMethodsStorageService
                                .deleteMethod(method.id);
                          }

                          if (!mounted) return;
                          Navigator.pop(context);
                          await _loadPaymentMethods();
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'default',
                            child: Text('Set as default'),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    await _loadPaymentMethods();
  }

  Widget _buildPaymentMethodSection() {
    const primaryGreen = Color(0xFF2E7D32);
    const lightGray = Color(0xFFE0E0E0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: lightGray),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Payment method',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _openManagePaymentMethods,
                child: const Text('Manage'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingPaymentMethods)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_savedPaymentMethods.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('No payment method saved yet.'),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openAddPaymentMethodSheet,
                    icon: const Icon(Icons.add),
                    label: const Text('Add payment method'),
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                ..._savedPaymentMethods.map(
                      (method) => RadioListTile<String>(
                    value: method.id,
                    groupValue: _selectedPaymentMethodId,
                    activeColor: primaryGreen,
                    contentPadding: EdgeInsets.zero,
                    title: Text('${method.brand} • ${method.cardNumberMasked}'),
                    subtitle: Text(
                      '${method.cardName} · Expires ${method.expiryLabel}'
                          '${method.isDefault ? ' · Default' : ''}',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethodId = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openAddPaymentMethodSheet,
                    icon: const Icon(Icons.add),
                    label: const Text('Add another card'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _submitPromotion() async {
    if (_isSubmitting) return;

    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final result = await _promotionService.promoteEvent(
      token: widget.token,
      eventId: widget.event.id,
      userId: widget.userId,
      paymentMethodId: _selectedPaymentMethod!.id,
      amount: _promotionPrice,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (result.success) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Promotion successful'),
            content: Text('Your event was promoted successfully.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF2E7D32);
    const lightGray = Color(0xFFE0E0E0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Promote event'),
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: lightGray),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 10,
                      offset: Offset(0, 4),
                      color: Color(0x14000000),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: Image.network(
                        widget.event.imageUrls.isNotEmpty ? widget.event.imageUrls.first : '',
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) {
                          return Container(
                            height: 180,
                            width: double.infinity,
                            color: const Color(0xFFF1F1F1),
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              size: 48,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.event.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: primaryGreen,
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(widget.event.location)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: primaryGreen,
                              ),
                              const SizedBox(width: 8),
                              Text(_formatDate(widget.event.date)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Promotion details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: lightGray),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text(
                          'Promotion type',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Spacer(),
                        Text('Featured promotion'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text(
                          'Duration',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text('$_promotionDurationDays days'),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Text('Fixed price'),
                        const Spacer(),
                        Text(_formatPrice(_promotionPrice)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatPrice(_promotionPrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: primaryGreen,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5FAF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD6EBD8)),
                      ),
                      child: Text(
                        'Your event will be more likely to be displayed in main page for $_promotionDurationDays days after payment confirmation.',
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Payment',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: primaryGreen,
                ),
              ),
              const SizedBox(height: 12),
              _buildPaymentMethodSection(),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPromotion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Pay €1.00 and promote',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}