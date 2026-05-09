import 'package:flutter/material.dart';
import '../../models/event.dart';
import '../../models/payment_method.dart';
import '../../services/payment_methods_storage_service.dart';
import '../../services/payment_service.dart';
import '../../services/ticket_service.dart';
import 'package:flutter/services.dart';


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


class BuyTicketPage extends StatefulWidget {
  final Event event;
  final String token;
  final String? initialEmail;
  final String? initialName;

  const BuyTicketPage({
    super.key,
    required this.event,
    required this.token,
    this.initialEmail,
    this.initialName,
  });

  @override
  State<BuyTicketPage> createState() => _BuyTicketPageState();
}

class _BuyTicketPageState extends State<BuyTicketPage> {
  final TicketService _ticketService = TicketService();
  final PaymentService _paymentService = PaymentService();
  final PaymentMethodsStorageService _paymentMethodsStorageService =
  PaymentMethodsStorageService();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  final _formKey = GlobalKey<FormState>();

  int _quantity = 1;
  bool _useMyInformation = true;
  bool _isSubmitting = false;
  bool _isLoadingPaymentMethods = true;

  List<PaymentMethod> _savedPaymentMethods = [];
  String? _selectedPaymentMethodId;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.initialName?.trim() ?? '',
    );
    _emailController = TextEditingController(
      text: widget.initialEmail?.trim() ?? '',
    );

    _loadPaymentMethods();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _applyMyInformation(bool useMine) {
    setState(() {
      _useMyInformation = useMine;

      if (useMine) {
        _nameController.text = widget.initialName?.trim() ?? '';
        _emailController.text = widget.initialEmail?.trim() ?? '';
      } else {
        _nameController.clear();
        _emailController.clear();
      }
    });
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

  double _totalAmount() => widget.event.price * _quantity;

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
    if (price == 0) return 'Free';
    return '€${price.toStringAsFixed(2)}';
  }

  String _formatTotal() {
    final total = widget.event.price * _quantity;
    if (total == 0) return 'Free';
    return '€${total.toStringAsFixed(2)}';
  }

  Widget _buildBuyerInformationSection() {
    const primaryGreen = Color(0xFF2E7D32);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Buyer information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: primaryGreen,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Use my information'),
          subtitle: const Text(
            'Turn on if you are buying for yourself. Turn off if you are buying for someone else.',
          ),
          value: _useMyInformation,
          onChanged: _applyMyInformation,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nameController,
          enabled: !_useMyInformation,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Full name',
            hintText: _useMyInformation && (widget.initialName?.trim().isEmpty ?? true)
                ? 'No saved name available'
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (_useMyInformation) return null;

            final text = value?.trim() ?? '';
            if (text.isEmpty) {
              return 'Please enter the buyer name';
            }
            if (text.length < 2) {
              return 'Name is too short';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _emailController,
          enabled: !_useMyInformation,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Email',
            hintText: _useMyInformation && (widget.initialEmail?.trim().isEmpty ?? true)
                ? 'No saved email available'
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (_useMyInformation) return null;

            final text = value?.trim() ?? '';
            if (text.isEmpty) {
              return 'Please enter the buyer email';
            }
            final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
            if (!emailRegex.hasMatch(text)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
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

  Future<void> _submitBooking() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    if (_totalAmount() > 0 && _selectedPaymentMethod == null) {
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

    final totalAmount = _totalAmount();
    String? paymentReference;

    if (totalAmount > 0) {
      final paymentResult = await _paymentService.processPayment(
        token: widget.token,
        eventId: widget.event.id,
        quantity: _quantity,
        amount: totalAmount,
        customerName: _nameController.text.trim(),
        customerEmail: _emailController.text.trim(),
        paymentMethodId: _selectedPaymentMethod!.id,
      );

      if (!mounted) return;

      if (!paymentResult.success) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentResult.message),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      paymentReference = paymentResult.paymentReference;
    }

    final ticketResult = await _ticketService.bookTicket(
      token: widget.token,
      eventId: widget.event.id,
      quantity: _quantity,
      customerName: _nameController.text.trim(),
      customerEmail: _emailController.text.trim(),
      paymentReference: paymentReference,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (ticketResult.success) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Booking confirmed'),
            content: Text(
              ticketResult.bookingReference != null
                  ? 'Your booking was completed successfully.\n\nReference: ${ticketResult.bookingReference}'
                  : 'Your booking was completed successfully.',
            ),
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
          content: Text(ticketResult.message),
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
        title: const Text('Buy ticket'),
        backgroundColor: Colors.white,
        foregroundColor: primaryGreen,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
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
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.sell_outlined,
                                  size: 18,
                                  color: primaryGreen,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatPrice(widget.event.price),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
                  'Ticket details',
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
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Quantity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: _quantity > 1
                                ? () {
                              setState(() {
                                _quantity--;
                              });
                            }
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$_quantity',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _quantity++;
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          const Text('Price per ticket'),
                          const Spacer(),
                          Text(_formatPrice(widget.event.price)),
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
                            _formatTotal(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: primaryGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildBuyerInformationSection(),
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
                    onPressed: _isSubmitting ? null : _submitBooking,
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
                        : Text(
                      widget.event.price == 0
                          ? 'Reserve spot'
                          : 'Pay and confirm',
                      style: const TextStyle(
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
      ),
    );
  }
}